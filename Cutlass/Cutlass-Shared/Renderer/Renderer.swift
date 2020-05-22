//
//  Renderer.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

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
    var edgeDistance:Float
    var edgeWidth:Float
}

public class Renderer : Actor {
    static let maxConcurrentFrames:Int = 3
    
    private var metalDevice:MTLDevice
    private var pixelFormat:MTLPixelFormat
    
    private var root:Yoga = Yoga()
    
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

    private let textureLoader:MTKTextureLoader!
    
    private var bundlePathCache:Dictionary<String, String>!
    private var isLoadingTextureCache:Dictionary<String, Bool>!
    private var textureCache:Dictionary<String, MTLTexture>!
    
    private var depthTexture:MTLTexture!
    
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
            
            stencilPipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
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
            
            flatPipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
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
            
            texturePipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
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
            
            sdfPipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
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
        
        bundlePathCache = Dictionary<String, String>()
        textureCache = Dictionary<String, MTLTexture>()
        isLoadingTextureCache = Dictionary<String, Bool>()
        
        super.init()
        
        self.privateInit()
    }
    
    private func privateInit() {
        depthTexture = getDepthTexture(size:CGSize(width: 128, height: 128))
    }
    
    private func getDepthTexture(size:CGSize) -> MTLTexture {
        
        var textureWidth:Int = 128
        var textureHeight:Int = 128
        
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
    private var sdfUniforms = SDFUniforms(edgeDistance:0.4, edgeWidth:1.0)
    private var sdfUniformsBuffer: MTLBuffer!
    
    private var stencilValueCount:Int = 0
    private var stencilValueMax:Int = 255
    
    private var projectedSize:CGSize = CGSize(width:128, height:128)
    
    private var lastFramesTime: CFAbsoluteTime = 0.0
    private var renderAheadCount:Int = 0
    private var numFrames:Int = 0
    private var firstRender:Bool = true
    
    private var needsLayout:Bool = true
    
    private var renderUnits:[RenderUnit] = []
    
    public lazy var setRoot = Behavior(self) { (args:BehaviorArgs) in
        self.root.removeAll()
        self.root.child(args[x:0])
        self.needsLayout = true
    }
    
    // Render happens like this:
    // 1. Someone (a view most likely) asks us to render, sending us a CAMetalLayer
    // 2. We grab the next drawable and create a RenderFrameContext, putting ourself and the drawable in there
    // 3. We call Yoga.render() on our root node, which walks the hiearchy and concurrently asks all views to render
    // 4. Each view can submit render units (geometry + stuff to render their views) concurrently
    // 5. We expect to receive a submitRenderFinished() call from all views in the hiearchy, and we know
    //    the frame is done when we have received all of them back
    private var numberOfViewsToRender:Int = 0
    
    public lazy var render = Behavior(self) { (args:BehaviorArgs) in
        let metalLayer:CAMetalLayer = args[x:0]
        let contentsScale:CGFloat = args[x:1]
        
        let pointSize = CGSize(width: metalLayer.bounds.size.width,
                               height: metalLayer.bounds.size.height)
        
        let pixelSize = CGSize(width: metalLayer.bounds.size.width * contentsScale,
                               height: metalLayer.bounds.size.height * contentsScale)
        
        // ensure that our depth texture size is correct!
        if pixelSize.equalTo(CGSize(width: self.depthTexture.width, height: self.depthTexture.height)) == false {
            metalLayer.drawableSize = pixelSize
            metalLayer.contentsScale = contentsScale
            self.depthTexture = self.getDepthTexture(size:pixelSize)
        }
                
        if let drawable = metalLayer.nextDrawable() {
                        
            let ctx = RenderFrameContext(renderer:self,
                                         viewSize:pointSize,
                                         drawable:drawable,
                                           matrix:GLKMatrix4Identity,
                                           bounds:GLKVector4Make(0, 0, 0, 0))
            self.render_start(ctx)
        }
    }
    
    public lazy var submitRenderUnit = Behavior(self) { (args:BehaviorArgs) in
        let ctx:RenderFrameContext = args[x:0]
        let unit:RenderUnit = args[x:1]
        
        // TODO: Replace this with a tree structure which can sort
        // the render units as it inserts them
        self.renderUnits.append(unit)
    }
    
    public lazy var submitRenderFinished = Behavior(self) { (args:BehaviorArgs) in
        let ctx:RenderFrameContext = args[x:0]
        
        self.numberOfViewsToRender -= 1
        
        if self.numberOfViewsToRender == 0 {
            self.render_finish(ctx)
        }
    }
    
    public lazy var submitRenderOnScreen = Behavior(self) { (args:BehaviorArgs) in
        self.renderAheadCount -= 1
    }
    
    private func render_start(_ ctx:RenderFrameContext) {
        // Check to see if our render size changed, if it did we need
        // to reset the projection matrices to match and re-layout
        if projectedSize.equalTo(ctx.viewSize) == false {
            projectedSize = ctx.viewSize
            
            let aspect = fabsf(Float(projectedSize.width) / Float(projectedSize.height))
            
            // calculate the field of view such that at a given depth we
            // match the size of the window exactly
            var radtheta:Float = 0.0
            let distance:Float = 5000.0
            
            radtheta = 2.0 * atan2( Float(projectedSize.height) / 2.0, distance );
            
            let projectionMatrix = GLKMatrix4MakePerspective(
                radtheta,
                aspect,
                1.0,
                distance * 10.0)
            sceneMatrices.projectionMatrix = projectionMatrix
            
            needsLayout = true
        }
        
        // make sure we are not trying to render more than the max concurrent frames
        if renderAheadCount >= Renderer.maxConcurrentFrames {
            return
        }
        
        if needsLayout {
            root.size(px:(Float(projectedSize.width),Float(projectedSize.height)))
            root.layout()
            needsLayout = false
        }
        
        numberOfViewsToRender = root.render(ctx)

        if numberOfViewsToRender == 0 {
            return
        }
        
        renderAheadCount += 1
    }
    
    private func render_finish(_ ctx:RenderFrameContext) {
        let drawable = ctx.drawable
        
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
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            renderAheadCount -= 1
            return
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            renderAheadCount -= 1
            return
        }

        // define the modelview and projection matrics and make them
        // available to the shaders
        var modelViewMatrix = GLKMatrix4Identity
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, Float(projectedSize.width * -0.5), Float(projectedSize.height * 0.5), -5000.0)
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
        
        // TODO: process and render all collected render units for this frame
        renderEncoder.setRenderPipelineState(flatPipelineState)
        renderEncoder.setFragmentSamplerState(normalSamplerState, index:0)
        
        for unit in renderUnits {
            if unit.textureName != nil {
                /*
                let texture = createTextureSync(namePtr: unit.textureName)
                if texture == nil {
                    continue
                }
                renderEncoder.setFragmentTexture(texture, index: 0)*/
            }
            
            /*
            if stencilValueCount == stencilValueMax {
                renderEncoder.setDepthStencilState(ignoreStencilState)
            } else {
                renderEncoder.setDepthStencilState(testStencilState)
            }
            */
            
            /*
            if cullMode == CullMode_back {
                renderEncoder.setCullMode(.back)
            } else if cullMode == CullMode_front {
                renderEncoder.setCullMode(.front)
            } else if cullMode == CullMode_none {
                renderEncoder.setCullMode(.none)
            }
            
            if shaderType == ShaderType_Abort {
                aborted = true
            }
                
            if shaderType == ShaderType_Flat {
                renderEncoder.setRenderPipelineState(flatPipelineState)
                renderEncoder.setFragmentSamplerState(normalSamplerState, index:0)
            } else if shaderType == ShaderType_Textured {
                renderEncoder.setRenderPipelineState(texturePipelineState)
                renderEncoder.setFragmentSamplerState(normalSamplerState, index:0)
            } else if shaderType == ShaderType_SDF {
                renderEncoder.setRenderPipelineState(sdfPipelineState)
                renderEncoder.setFragmentSamplerState(mipmapSamplerState, index:0)
            } else if shaderType == ShaderType_Stencil_Begin {
                renderEncoder.setDepthStencilState(decrementStencilState)
                renderEncoder.setRenderPipelineState(stencilPipelineState)
                renderEncoder.setFragmentSamplerState(normalSamplerState, index:0)
            } else if shaderType == ShaderType_Stencil_End {
                renderEncoder.setDepthStencilState(incrementStencilState)
                renderEncoder.setRenderPipelineState(stencilPipelineState)
                renderEncoder.setFragmentSamplerState(normalSamplerState, index:0)
            }*/
            
            
            if unit.vertices.vertexCount() > 0 {
                drawRenderUnit(renderEncoder, unit)
            }
            
            /*
            if shaderType == ShaderType_Stencil_Begin {
                stencilValueCount = max(stencilValueCount - 1, 0)
                renderEncoder.setStencilReferenceValue(UInt32(stencilValueCount))
            }
            if shaderType == ShaderType_Stencil_End {
                stencilValueCount = min(stencilValueCount + 1, stencilValueMax)
                renderEncoder.setStencilReferenceValue(UInt32(stencilValueCount))
            }*/
        }
        renderUnits.removeAll()
        
        renderEncoder.endEncoding()
        
        commandBuffer.addCompletedHandler { (buffer) in
            self.submitRenderOnScreen()
        }
                
        if aborted == false {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
        
        if aborted == false {
            // Simple FPS so we can compare performance
            numFrames = numFrames + 1
            
            let currentTime = CFAbsoluteTimeGetCurrent()
            let elapsedTime = currentTime - lastFramesTime
            if elapsedTime > 1.0 {
                print("\(numFrames) fps")
                numFrames = 0
                lastFramesTime = currentTime
            }
        }
    }
    
    private func drawRenderUnit(_ renderEncoder:MTLRenderCommandEncoder, _ unit:RenderUnit) {
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
        
        let actual_bytes = unit.vertices.bytesCount()
        if actual_bytes <= 4096 {
            if let pointer = unit.vertices.bytes() {
                renderEncoder.setVertexBytes(pointer, length: actual_bytes, index: 0)
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
    /*
    private var textureCacheLock:NSObject = NSObject()
    private var urlStringFromBundlePathLock:NSObject = NSObject()
    private var renderAheadCountLock:NSObject = NSObject()
    
    private let serialQueue = DispatchQueue(label: "serial.queue", qos: .default)
    
    private func getDepthTexture(size:CGSize) -> MTLTexture {
        
        var textureWidth:Int = 128
        var textureHeight:Int = 128
        
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
    
    private func createTextureFromBytes(namePtr: UnsafePointer<Int8>?, bytesPtr: UnsafeMutableRawPointer?, bytesCount:size_t) {
        if let namePtr = namePtr {
            let name = String(cString: namePtr)
            if name.count == 0 {
                return
            }
            
            if let bytesPtr = bytesPtr {
                
                let textureLoaderOptions = [
                    MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                    MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
                    MTKTextureLoader.Option.SRGB: NSNumber(value: false),
                    MTKTextureLoader.Option.generateMipmaps: NSNumber(value: false)
                ]
                
                textureLoader.newTexture(data: Data(bytes: bytesPtr, count: bytesCount), options: textureLoaderOptions, completionHandler: { (texture, error) in
                    if let texture = texture {
                        objc_sync_enter(self.textureCacheLock)
                        self.textureCache[name] = texture
                        objc_sync_exit(self.textureCacheLock)
                        
                        // TODO: Mark cutlass as needing re-rendered
                        /*
                        DispatchQueue.main.async {
                            RenderEngineInternal_setNeedsRendered(nil)
                        }
                        */
                    }
                })
            }
        }
    }
    
    private func createTextureAsync(urlPtr: UnsafePointer<Int8>?) {
        if let urlPtr = urlPtr {
            let urlString = String(cString: urlPtr)
            if urlString.count == 0 {
                return
            }
            
            let textureLoaderOptions = [
                MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
                MTKTextureLoader.Option.SRGB: NSNumber(value: false),
                MTKTextureLoader.Option.generateMipmaps: NSNumber(value: false)
            ]
            
            let resolvedName = urlStringFromBundlePath(urlString)
            
            objc_sync_enter(textureCacheLock)
            let isLoading = isLoadingTextureCache[resolvedName]
            if isLoading != nil {
                objc_sync_exit(textureCacheLock)
                return
            }
            isLoadingTextureCache[resolvedName] = true
            objc_sync_exit(textureCacheLock)
            
            serialQueue.async {
                if urlString.starts(with: "http") == false {
                    do {
                        let texture = try self.textureLoader.newTexture(URL: URL(fileURLWithPath: resolvedName), options: textureLoaderOptions)
                        objc_sync_enter(self.textureCacheLock)
                        self.textureCache[resolvedName] = texture
                        objc_sync_exit(self.textureCacheLock)
                    } catch {
                        print("Texture failed to load: \(error)")
                    }
                    return
                }
                
                if let url = URL(string: resolvedName) {
                    URLSession.shared.dataTask(with: url) { (data, response, error) in
                        if let data = data {
                            self.textureLoader.newTexture(data: data, options: textureLoaderOptions, completionHandler: { (texture, error) in
                                if let texture = texture {
                                    objc_sync_enter(self.textureCacheLock)
                                    self.textureCache[resolvedName] = texture
                                    objc_sync_exit(self.textureCacheLock)
                                    
                                    // TODO: Flag need re-rendered
                                    /*
                                    DispatchQueue.main.async {
                                        RenderEngineInternal_setNeedsRendered(nil)
                                    }*/
                                }
                            })
                        }
                    }.resume()
                }
            }
        }
    }
    
    private func urlStringFromBundlePath(_ bundlePath:String) -> String {
        // name is a "url path" to a file.  These are like in planet:
        // "resources://landscape_desert.jpg"
        // "documents://landscape_desert.jpg"
        // "caches://landscape_desert.jpg"
        
        // This doesn't like being multi-threaded, because we use dictionary cache. So lock and then check again before loading
        objc_sync_enter(urlStringFromBundlePathLock)
        defer {
            objc_sync_exit(urlStringFromBundlePathLock)
        }
        
        let cachedPath = bundlePathCache[bundlePath]
        if cachedPath != nil {
            return cachedPath!
        }
        
        let pathComponents = bundlePath.components(separatedBy: ":/")
        var pathString = bundlePath
        
        switch pathComponents[0] {
        case "http":
            pathString = bundlePath
        case "https":
            pathString = bundlePath
        case "assets":
            if let resourcePath = Bundle.main.resourcePath {
                pathString = "\(resourcePath)/Assets/\(pathComponents[1])"
            }
        case "documents":
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            pathString = "\(documentsPath)/\(pathComponents[1])"
        case "caches":
            let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            pathString = "\(cachePath)/\(pathComponents[1])"
        default:
            // we default to resources:// and ".png" so that things like "imagename" are easy and possible
            if let resourcePath = Bundle.main.resourcePath {
                let ext = (bundlePath as NSString).pathExtension
                if ext.count == 0 {
                    pathString = "\(resourcePath)/Assets/\(bundlePath).png"
                }else{
                    pathString = "\(resourcePath)/Assets/\(bundlePath)"
                }
            }
        }
        
        bundlePathCache[bundlePath] = pathString
        
        return pathString
    }
 */
}
