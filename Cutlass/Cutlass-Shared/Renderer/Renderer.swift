//
//  Renderer.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable cyclomatic_complexity

import Foundation
import MetalKit
import GLKit
import simd
import Flynn

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

struct SceneMatrices {
    var projectionMatrix: GLKMatrix4 = GLKMatrix4Identity
    var modelviewMatrix: GLKMatrix4 = GLKMatrix4Identity
}

struct GlobalUniforms {
    var globalColor: GLKVector4 = GLKVector4Make(1.0, 1.0, 1.0, 1.0)
}

struct SDFUniforms {
    var edgeDistance: Float
    var edgeWidth: Float
}

public class Renderer: Actor {
    static let maxConcurrentFrames: Int = 1

    private var metalDevice: MTLDevice
    private var pixelFormat: MTLPixelFormat

    private var root: Yoga = Yoga()

    private var metalCommandQueue: MTLCommandQueue!

    private var ignoreStencilState: MTLDepthStencilState!
    private var decrementStencilState: MTLDepthStencilState!
    private var testStencilState: MTLDepthStencilState!
    private var incrementStencilState: MTLDepthStencilState!

    private var stencilPipelineState: MTLRenderPipelineState!
    private var flatPipelineState: MTLRenderPipelineState!
    private var texturePipelineState: MTLRenderPipelineState!
    private var sdfPipelineState: MTLRenderPipelineState!

    private var normalSamplerState: MTLSamplerState!
    private var mipmapSamplerState: MTLSamplerState!

    private let textureLoader: MTKTextureLoader

    private var bundlePathCache: [String: String]
    private var isLoadingTextureCache: [String: Bool]
    private var textureCache: [String: MTLTexture]

    private var depthTexture: MTLTexture!

    init(pixelFormat: MTLPixelFormat, device: MTLDevice) {
        self.metalDevice = device
        self.pixelFormat = pixelFormat

        metalCommandQueue = metalDevice.makeCommandQueue()

        //Get the framework bundle by using `Bundle(for: type(of: self))` from inside any framework class.
        //Then use the bundle to define an MTLLibrary.
        let frameworkBundle = Bundle(for: type(of: self))
        let defaultLibrary = (try? metalDevice.makeDefaultLibrary(bundle: frameworkBundle))!

        // render as normal testing against the stencil buffer for masking
        if true {
            let stencilDescriptor = MTLStencilDescriptor()
            stencilDescriptor.stencilCompareFunction = .equal
            stencilDescriptor.depthStencilPassOperation = .keep
            stencilDescriptor.stencilFailureOperation = .keep
            stencilDescriptor.depthFailureOperation = .keep
            stencilDescriptor.readMask = 0xFF
            stencilDescriptor.writeMask = 0x00

            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            depthStencilDescriptor.depthCompareFunction = .lessEqual
            depthStencilDescriptor.isDepthWriteEnabled = false
            depthStencilDescriptor.frontFaceStencil = stencilDescriptor
            depthStencilDescriptor.backFaceStencil = stencilDescriptor

            testStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)
        }

        // render to the stencil buffer, don't render to the color attachment
        if true {
            let stencilDescriptor = MTLStencilDescriptor()
            stencilDescriptor.stencilCompareFunction = .equal
            stencilDescriptor.stencilFailureOperation = .keep
            stencilDescriptor.depthFailureOperation = .keep
            stencilDescriptor.depthStencilPassOperation = .decrementClamp
            stencilDescriptor.readMask = 0x00
            stencilDescriptor.writeMask = 0xFF

            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            depthStencilDescriptor.depthCompareFunction = .lessEqual
            depthStencilDescriptor.isDepthWriteEnabled = false
            depthStencilDescriptor.frontFaceStencil = stencilDescriptor
            depthStencilDescriptor.backFaceStencil = stencilDescriptor

            decrementStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)
        }

        // unrender from the stencil buffer, don't render to the color attachment
        if true {
            let stencilDescriptor = MTLStencilDescriptor()
            stencilDescriptor.stencilCompareFunction = .equal
            stencilDescriptor.stencilFailureOperation = .keep
            stencilDescriptor.depthFailureOperation = .keep
            stencilDescriptor.depthStencilPassOperation = .incrementClamp
            stencilDescriptor.readMask = 0x00
            stencilDescriptor.writeMask = 0xFF

            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            depthStencilDescriptor.depthCompareFunction = .lessEqual
            depthStencilDescriptor.isDepthWriteEnabled = false
            depthStencilDescriptor.frontFaceStencil = stencilDescriptor
            depthStencilDescriptor.backFaceStencil = stencilDescriptor

            incrementStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)
        }

        // ignore stencil state: normal rendering while ignoring the stencil buffer
        if true {
            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            depthStencilDescriptor.depthCompareFunction = .lessEqual
            depthStencilDescriptor.isDepthWriteEnabled = false
            depthStencilDescriptor.frontFaceStencil = nil
            depthStencilDescriptor.backFaceStencil = nil

            ignoreStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)
        }

        // A shader pipeline for rendering to the stencil buffer only
        if true {
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "flat_vertex")
            pipelineStateDescriptor.fragmentFunction = nil
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat

            pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
            pipelineStateDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8

            stencilPipelineState = try? metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }

        // A "flat" shader pipeline (no texture, just geometric colors)
        if true {
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "flat_vertex")
            pipelineStateDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "flat_fragment")
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat

            pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
            pipelineStateDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8

            flatPipelineState = try? metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }

        // A textured shader pipeline
        if true {
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "textured_vertex")
            pipelineStateDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "textured_fragment")
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat

            pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
            pipelineStateDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8

            texturePipelineState = try? metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }

        // A sdf shader pipeline
        if true {
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "sdf_vertex")
            pipelineStateDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "sdf_fragment")
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat

            pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
            pipelineStateDescriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8

            sdfPipelineState = try? metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }

        // do not interpolate between mipmaps
        let normalSamplerDesc = MTLSamplerDescriptor()
        normalSamplerDesc.sAddressMode = .clampToEdge
        normalSamplerDesc.tAddressMode = .clampToEdge
        normalSamplerDesc.minFilter = .linear
        normalSamplerDesc.magFilter = .linear
        normalSamplerDesc.mipFilter = .notMipmapped
        normalSamplerState = metalDevice.makeSamplerState(descriptor: normalSamplerDesc)

        // interpolate between mipmaps
        let mipmapSamplerDesc = MTLSamplerDescriptor()
        mipmapSamplerDesc.sAddressMode = .clampToEdge
        mipmapSamplerDesc.tAddressMode = .clampToEdge
        mipmapSamplerDesc.minFilter = .linear
        mipmapSamplerDesc.magFilter = .linear
        mipmapSamplerDesc.mipFilter = .linear
        mipmapSamplerState = metalDevice.makeSamplerState(descriptor: mipmapSamplerDesc)

        textureLoader = MTKTextureLoader(device: metalDevice)

        bundlePathCache = [:]
        textureCache = [:]
        isLoadingTextureCache = [:]

        super.init()

        self.privateInit()
    }

    private func privateInit() {
        depthTexture = getDepthTexture(size: CGSize(width: 128, height: 128))
    }

    private func getDepthTexture(size: CGSize) -> MTLTexture {

        var textureWidth: Int = 128
        var textureHeight: Int = 128

        if size.width > 0 {
            textureWidth = Int(size.width)
        }
        if size.height > 0 {
            textureHeight = Int(size.height)
        }

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float_stencil8,
            width: textureWidth, height: textureHeight, mipmapped: false)
        desc.storageMode = .private
        desc.usage = .renderTarget
        return metalDevice.makeTexture(descriptor: desc)!
    }

    // MARK: - Behaviors - Rendering
    private var sceneMatrices = SceneMatrices()
    private var globalUniforms = GlobalUniforms()
    private var sdfUniforms = SDFUniforms(edgeDistance: 0.4, edgeWidth: 1.0)
    private var sdfUniformsBuffer: MTLBuffer!

    private var stencilValueCount: Int = 0
    private var stencilValueMax: Int = 255

    private var lastFramesTime: CFAbsoluteTime = 0.0
    private var renderAheadCount: Int = 0
    private var numFrames: Int = 0
    private var firstRender: Bool = true

    private var needsLayout: Bool = true
    private var needsRender: Bool = true

    public lazy var beSetRoot = Behavior(self) { (args: BehaviorArgs) in
        // flynnlint:parameter Yoga - The yoga node to set the root as
        self.root.removeAll()
        self.root.child(args[x:0])
        self.needsLayout = true
    }

    public lazy var beSetNeedsLayout = Behavior(self) { (_: BehaviorArgs) in
        self.needsLayout = true
    }

    public lazy var beSetNeedsRender = Behavior(self) { (_: BehaviorArgs) in
        self.needsRender = true
    }

    // Render happens like this:
    // 1. Someone (a view most likely) asks us to render, sending us a CAMetalLayer
    // 2. We check and record the size of the drawable, but don't grab a drawable yet
    // 3. We call Yoga.render() on our root node, which walks the hiearchy and concurrently asks all views to render
    // 4. Each view can submit render units (geometry + stuff to render their views) concurrently
    // 5. We expect to receive a submitRenderFinished() call from all views in the hiearchy, and we know
    //    the frame is done when we have received all of them back
    private var numberOfViewsToRender: Int = 0
    private var frameNumberRequested: Int64 = 0
    private var renderUnitTree: AVLTree<Int64, RenderUnit> = AVLTree()

    public lazy var beRenderFrame = Behavior(self) { (args: BehaviorArgs) in
        // flynnlint:parameter CAMetalLayer - The metal layer to render into
        // flynnlint:parameter CGSize - The size of the view associated with the metal layer
        // flynnlint:parameter CGFloat - the scale of the view associated with the metal layer
        let metalLayer: CAMetalLayer = args[x:0]
        let contentsSize: CGSize = args[x:1]
        let contentsScale: CGFloat = args[x:2]

        let pointSize = CGSize(width: contentsSize.width, height: contentsSize.height)
        let pixelSize = CGSize(width: contentsSize.width * contentsScale, height: contentsSize.height * contentsScale)

        metalLayer.drawableSize = pixelSize
        metalLayer.contentsScale = contentsScale

        self.frameNumberRequested += 1

        let ctx = RenderFrameContext(renderer: self,
                                     metalLayer: metalLayer,
                                     pointSize: pointSize,
                                     pixelSize: pixelSize,
                                     frameNumber: self.frameNumberRequested,
                                     view: ViewFrameContext())

        self.render_start(ctx)
    }

    public lazy var beSubmitRenderUnit = Behavior(self) { (args: BehaviorArgs) in
        // flynnlint:parameter RenderFrameContext - The render frame context
        // flynnlint:parameter RenderUnit - The render unit to render

        // Each view can submit a number of render units, with each render unit being
        // an distinct renderable thing
        let ctx: RenderFrameContext = args[x:0]
        let unit: RenderUnit = args[x:1]
        self.renderUnitTree.insert(key: unit.renderNumber, payload: unit)
    }

    public lazy var beSubmitRenderFinished = Behavior(self) { (args: BehaviorArgs) in
        // flynnlint:parameter RenderFrameContext - The render frame context

        // Each view which received a render call must call submitRenderFinished when they
        // have finished that render call. The Renderer tracks these to know when all views
        // in a render frame have finished.
        let ctx: RenderFrameContext = args[x:0]
        self.numberOfViewsToRender -= 1

        if self.numberOfViewsToRender == 0 {
            self.render_finish(ctx)
        }
    }

    public lazy var beSubmitRenderOnScreen = Behavior(self) { (_: BehaviorArgs) in
        self.renderAheadCount -= 1
    }

    // MARK: - Internal - Rendering

    private func render_start(_ ctx: RenderFrameContext) {
        // make sure we are not trying to render more than the max concurrent frames
        if renderAheadCount >= Renderer.maxConcurrentFrames {
            return
        }

        needsLayout = true

        if needsLayout ||
           Int(root.getWidth()) != Int(ctx.pointSize.width) ||
           Int(root.getHeight()) != Int(ctx.pointSize.height) {
            root.size(Pixel(ctx.pointSize.width), Pixel(ctx.pointSize.height))
            root.layout()
            needsLayout = false
            needsRender = true
        }

        if needsRender == false {
            return
        }
        needsRender = false

        numberOfViewsToRender = root.render(ctx)

        if numberOfViewsToRender == 0 {
            return
        }

        renderAheadCount += 1
    }

    private func render_finish(_ ctx: RenderFrameContext) {

        if let drawable = ctx.metalLayer.nextDrawable() {
            let drawableWidth = drawable.texture.width
            let drawableHeight = drawable.texture.height

            if drawableWidth != Int(ctx.pixelSize.width) || drawableHeight != Int(ctx.pixelSize.height) {
                print(".")
                renderAheadCount -= 1
                return
            }

            if drawableWidth != depthTexture.width || drawableHeight != depthTexture.height {
                depthTexture = getDepthTexture(size: CGSize(width: drawableWidth, height: drawableHeight))
            }

            let renderPassDescriptor = MTLRenderPassDescriptor()
            if let depthAttachment = renderPassDescriptor.depthAttachment {
                depthAttachment.texture = depthTexture
                depthAttachment.clearDepth = 1.0
                depthAttachment.storeAction = .dontCare
                depthAttachment.loadAction = .clear

                if let stencilAttachment = renderPassDescriptor.stencilAttachment {
                    stencilAttachment.texture = depthAttachment.texture
                    stencilAttachment.storeAction = .dontCare
                    stencilAttachment.loadAction = .clear
                    stencilAttachment.clearStencil = 255
                }
            }

            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0,
                                                                                green: 1.0,
                                                                                blue: 1.0,
                                                                                alpha: 1.0)

            guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
                renderAheadCount -= 1
                return
            }

            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                renderAheadCount -= 1
                return
            }

            // Set up our projection matrix
            let aspect = fabsf(Float(ctx.pointSize.width / ctx.pointSize.height))

            // calculate the field of view such that at a given depth we
            // match the size of the window exactly
            var radtheta: Float = 0.0
            let distance: Float = 5000.0

            radtheta = 2.0 * atan2( Float(ctx.pointSize.height / 2.0), distance )

            let projectionMatrix = GLKMatrix4MakePerspective(
                radtheta,
                aspect,
                1.0,
                distance * 10.0)
            sceneMatrices.projectionMatrix = projectionMatrix

            // define the modelview and projection matrics and make them
            // available to the shaders
            var modelViewMatrix = GLKMatrix4Identity
            modelViewMatrix = GLKMatrix4Translate(modelViewMatrix,
                                                  Float(ctx.pointSize.width * -0.5),
                                                  Float(ctx.pointSize.height * 0.5),
                                                  -5000.0)
            modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, Float.pi)
            sceneMatrices.modelviewMatrix = modelViewMatrix

            renderEncoder.setVertexBytes(&sceneMatrices, length: MemoryLayout<SceneMatrices>.stride, index: 1)
            renderEncoder.setFragmentBytes(&sdfUniforms, length: MemoryLayout<SDFUniforms>.stride, index: 0)

            globalUniforms.globalColor.r = -99
            globalUniforms.globalColor.g = -999
            globalUniforms.globalColor.b = -9999
            globalUniforms.globalColor.a = -99999

            stencilValueCount = stencilValueMax
            renderEncoder.setStencilReferenceValue(UInt32(stencilValueCount))
            renderEncoder.setDepthStencilState(ignoreStencilState)

            var aborted = false

            renderEncoder.setRenderPipelineState(flatPipelineState)
            renderEncoder.setFragmentSamplerState(normalSamplerState, index: 0)

            renderUnitTree.doInOrder(node: renderUnitTree.root) { (node) in
                if let unit = node.payload {
                    let shaderType = unit.shaderType

                    if unit.viewFrame.fitToSize {
                        // When a render unit has fitToSize set, it means it wants to ensure that the
                        // yoga node related to this render unit has its width and height set to the
                        // render size.
                        if unit.viewFrame.bounds.width() != unit.contentSize.x ||
                           unit.viewFrame.bounds.height() != unit.contentSize.y {
                            if let node = root.getNode(yodaID: unit.yogaID) {
                                node.size(Pixel(unit.contentSize.x), Pixel(unit.contentSize.y))
                                needsLayout = true
                                aborted = true
                            }
                        }
                    }

                    if let textureName = unit.textureName {
                        let texture = createTextureSync(textureName)
                        if texture == nil {
                            return
                        }
                        renderEncoder.setFragmentTexture(texture, index: 0)
                    }

                    if stencilValueCount == stencilValueMax {
                        renderEncoder.setDepthStencilState(ignoreStencilState)
                    } else {
                        renderEncoder.setDepthStencilState(testStencilState)
                    }

                    /*
                    if cullMode == CullMode_back {
                        renderEncoder.setCullMode(.back)
                    } else if cullMode == CullMode_front {
                        renderEncoder.setCullMode(.front)
                    } else if cullMode == CullMode_none {
                        renderEncoder.setCullMode(.none)
                    }*/

                    if shaderType == .abort {
                        aborted = true
                    }

                    if shaderType == .flat {
                        renderEncoder.setRenderPipelineState(flatPipelineState)
                        renderEncoder.setFragmentSamplerState(normalSamplerState, index: 0)
                    } else if shaderType == .texture {
                        renderEncoder.setRenderPipelineState(texturePipelineState)
                        renderEncoder.setFragmentSamplerState(normalSamplerState, index: 0)
                    } else if shaderType == .sdf {
                        renderEncoder.setRenderPipelineState(sdfPipelineState)
                        renderEncoder.setFragmentSamplerState(mipmapSamplerState, index: 0)
                    } else if shaderType == .stencilBegin {
                        renderEncoder.setDepthStencilState(decrementStencilState)
                        renderEncoder.setRenderPipelineState(stencilPipelineState)
                        renderEncoder.setFragmentSamplerState(normalSamplerState, index: 0)
                    } else if shaderType == .stencilEnd {
                        renderEncoder.setDepthStencilState(incrementStencilState)
                        renderEncoder.setRenderPipelineState(stencilPipelineState)
                        renderEncoder.setFragmentSamplerState(normalSamplerState, index: 0)
                    }

                    if aborted == false && unit.vertices.vertexCount() > 0 {
                        drawRenderUnit(renderEncoder, unit)
                    }

                    if shaderType == .stencilBegin {
                        stencilValueCount = max(stencilValueCount - 1, 0)
                        renderEncoder.setStencilReferenceValue(UInt32(stencilValueCount))
                    }
                    if shaderType == .stencilEnd {
                        stencilValueCount = min(stencilValueCount + 1, stencilValueMax)
                        renderEncoder.setStencilReferenceValue(UInt32(stencilValueCount))
                    }
                }
            }
            renderUnitTree = AVLTree()

            renderEncoder.endEncoding()

            commandBuffer.addCompletedHandler { (_) in
                self.beSubmitRenderOnScreen()
            }

            if aborted == false {
                commandBuffer.present(drawable)
            }
            commandBuffer.commit()

            if aborted == false {
                // Simple FPS so we can compare performance
                numFrames += 1

                let currentTime = CFAbsoluteTimeGetCurrent()
                let elapsedTime = currentTime - lastFramesTime
                if elapsedTime > 1.0 {
                    print("\(numFrames) fps")
                    numFrames = 0
                    lastFramesTime = currentTime
                }
            }
        }
    }

    private func drawRenderUnit(_ renderEncoder: MTLRenderCommandEncoder, _ unit: RenderUnit) {
        //var vertexBuffer: MTLBuffer!

        if  globalUniforms.globalColor.r != unit.color.x ||
            globalUniforms.globalColor.g != unit.color.y ||
            globalUniforms.globalColor.b != unit.color.z ||
            globalUniforms.globalColor.a != unit.color.w {

            globalUniforms.globalColor.r = unit.color.x
            globalUniforms.globalColor.g = unit.color.y
            globalUniforms.globalColor.b = unit.color.z
            globalUniforms.globalColor.a = unit.color.w

            renderEncoder.setVertexBytes(&globalUniforms, length: MemoryLayout<GlobalUniforms>.stride, index: 2)
        }

        let actualBytes = unit.vertices.bytesCount()
        if actualBytes <= 4096 {
            if let pointer = unit.vertices.bytes() {
                renderEncoder.setVertexBytes(pointer, length: actualBytes, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: unit.vertices.vertexCount())
            }
        }
        /*
        else{
            vertexBuffer = metalDevice.makeBuffer(bytesNoCopy: unit.vertices,
                                                  length: Int(unit.bytes_vertices),
                                                  options: [ .storageModeShared ],
                                                  deallocator: { (pointer: UnsafeMutableRawPointer, _: Int) in
                                                    RenderEngine_release(unit.vertices, unit.size_vertices_array)
                                                })
            if vertexBuffer != nil {
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: Int(unit.num_vertices))
            }else{
                print("vertexBuffer is nil: \(unit.bytes_vertices) bytes for \(unit.num_vertices) vertices")
                RenderEngine_release(unit.vertices, unit.size_vertices_array)
            }
        }*/
    }

    // MARK: - Safe Texture Utility Methods
    // Note: we don't trust the places that calls these methods to do so from the same thread,
    // and we want to support loading an image atomically. So these methods include their own
    // locking mechanisms to keep them safe.

    public lazy var beGetTextureInfo = Behavior(self) { (args: BehaviorArgs) in
        // flynnlint:parameter String - The bundle path of the texture to load
        // flynnlint:parameter Behavior - Callback with the texture
        let bundlePath: String = args[x:0]
        let callback: Behavior = args[x:1]
        let resolvedPath = String(bundlePath: bundlePath)
        if let texture = self.textureCache[resolvedPath] {
            callback(self, bundlePath, texture)
        }
    }

    private func createTextureSync(_ bundlePath: String) -> MTLTexture? {
        let resolvedPath = String(bundlePath: bundlePath)

        // images loaded from urls are only loaded asynchronously
        if bundlePath.starts(with: "http") {
            let texture = textureCache[resolvedPath]
            if texture != nil {
                return texture
            }
            createTextureAsync(bundlePath)
            return nil
        }

        var texture = textureCache[resolvedPath]
        if texture != nil {
            return texture
        }

        let isLoading = isLoadingTextureCache[resolvedPath]
        if isLoading != nil {
            return nil
        }
        isLoadingTextureCache[resolvedPath] = true

        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
            MTKTextureLoader.Option.SRGB: NSNumber(value: true),
            MTKTextureLoader.Option.generateMipmaps: NSNumber(value: true)
        ]
        do {
            texture = try textureLoader.newTexture(URL: URL(fileURLWithPath: resolvedPath),
                                                   options: textureLoaderOptions)
            textureCache[resolvedPath] = texture
            self.needsRender = true

            return texture
        } catch {
            print("Texture failed to load: \(error)")
        }
        return nil
    }

    private lazy var registerTexture = Behavior(self) { (args: BehaviorArgs) in
        let resolvedPath: String = args[x:0]
        let texture: MTLTexture = args[x:1]
        self.textureCache[resolvedPath] = texture
        self.needsRender = true
    }

    private func createTextureAsync(_ bundlePath: String) {
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
            MTKTextureLoader.Option.SRGB: NSNumber(value: true),
            MTKTextureLoader.Option.generateMipmaps: NSNumber(value: false)
        ]

        let resolvedPath = String(bundlePath: bundlePath)

        let isLoading = isLoadingTextureCache[resolvedPath]
        if isLoading != nil {
            return
        }
        isLoadingTextureCache[resolvedPath] = true

        if bundlePath.starts(with: "http") == false {
            do {
                let texture = try self.textureLoader.newTexture(URL: URL(fileURLWithPath: resolvedPath),
                                                                options: textureLoaderOptions)
                self.textureCache[resolvedPath] = texture
                self.needsRender = true

            } catch {
                print("Texture failed to load: \(error)")
            }
            return
        }

        if let url = URL(string: resolvedPath) {
            URLSession.shared.dataTask(with: url) { (data, _, _) in
                if let data = data {
                    self.textureLoader.newTexture(data: data,
                                                  options: textureLoaderOptions,
                                                  completionHandler: { (texture, _) in
                        if let texture = texture {
                            self.registerTexture(resolvedPath, texture)
                        }
                    })
                }
            }.resume()
        }
    }
}
