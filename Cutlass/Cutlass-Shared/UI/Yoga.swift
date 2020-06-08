//
//  Yoga.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable file_length
// swiftlint:disable line_length

import Foundation
import Cutlass.Yoga
import GLKit
import Flynn

/* **************************************************
 Our goal is to have syntax like the following:
 
 Yoga.absolute().columns().safeTop().safeBottom().paddingRight(20).passingLeft(20).itemsCenter()
 .view( Scroll.horizontal(false) )
 .addChildren([
 Yoga.fit().width(percent:100).columns().center()
 .view( Color.red() )
 ])
 */

public typealias YogaID = UInt64
public typealias Pixel = Float

public class Yoga {
    private var parent: Yoga?
    private var node: YGNodeRef

    private var yogaID: YogaID

    private var views: [Viewable] = []
    private var _children: [Yoga] = []

    private var _pivot = GLKVector2Make(0.5, 0.5)
    private var _anchor = GLKVector2Make(0.5, 0.5)

    private var _rotation = GLKVector3Make(0, 0, 0)
    private var _scale = GLKVector3Make(1.0, 1.0, 1.0)

    private var _alpha: Float = 1.0
    private var _posZ: Float = 0.0

    private var _sizeToFit: Bool = false

    private var _lastBounds: GLKVector4 = GLKVector4Make(0, 0, 0, 0)

    private var _clips: Bool = false
    private var _clippingGeometry = BufferedGeometry()
    private var _clippingVertices: FloatAlignedArray?

    private var _usesLeft: Bool = true
    private var _usesTop: Bool = true

    private var _safeTop: Bool = false
    private var _safeLeft: Bool = false
    private var _safeBottom: Bool = false
    private var _safeRight: Bool = false

    public init() {
        node = YGNodeNew()
        yogaID = YGNodeGetID(node)
    }

    public func print() {
        YGNodePrint(node, [.layout, .style, .children])
    }

    // MARK: - Walkers

    func getNode(yodaID: YogaID) -> Yoga? {
        if yodaID == 0 {
            return nil
        }
        if self.yogaID == yodaID {
            return self
        }
        for child in _children {
            if let result = child.getNode(yodaID: yodaID) {
                return result
            }
        }
        return nil
    }

    public func layout() {
        // Before we can calculate the layout, we need to see if any of our children
        // sizeToFit their content. If we do, we need to have them set the size on the
        // appropriate yoga node preLayout()
        YGNodeCalculateLayout(node, YGNodeStyleGetWidth(node).value, YGNodeStyleGetHeight(node).value, .LTR)

        // postLayout gives the opporunity to nodes to adjust themselves based on the
        // layout which just happened. Specifically, if calls any custom() callbacks
        // that exist on nodes
        //if postLayout() then
        //  YGNodeCalculateLayout(node, YGNodeStyleGetWidth(node).value, YGNodeStyleGetHeight(node).value, .LTR)
        //end
    }

    public func render(_ ctx: RenderFrameContext) -> Int {
        return render_recursive(0, ctx)
    }

    private func render_recursive(_ renderN: Int, _ ctx: RenderFrameContext) -> Int {
        var localN: Int = renderN

        let localLeft = YGNodeLayoutGetLeft(node)
        let localTop = YGNodeLayoutGetTop(node)
        let localWidth = YGNodeLayoutGetWidth(node)
        let localHeight = YGNodeLayoutGetHeight(node)

        if _alpha > 0 {

            let pivotX = _pivot.x * localWidth
            let pivotY = _pivot.y * localHeight

            var localMatrix = GLKMatrix4Translate(ctx.view.matrix,
                                                   (localLeft + (_anchor.x * localWidth)) - (localWidth / 2),
                                                   (localTop + (_anchor.y * localHeight)) - (localHeight / 2),
                                                   _posZ)

            localMatrix = GLKMatrix4Translate(localMatrix,
                                                pivotX,
                                                pivotY,
                                                0)

            if _rotation.x != 0 {
                localMatrix = GLKMatrix4RotateX(localMatrix, _rotation.x)
            }
            if _rotation.y != 0 {
                localMatrix = GLKMatrix4RotateX(localMatrix, _rotation.y)
            }
            if _rotation.z != 0 {
                localMatrix = GLKMatrix4RotateX(localMatrix, _rotation.z)
            }

            if (_scale.x != 1.0) || (_scale.y != 1.0) || (_scale.z != 1.0) {
                localMatrix = GLKMatrix4Scale(localMatrix, _scale.x, _scale.y, _scale.z)
            }

            // TODO: parentContentOffset
            _lastBounds = GLKVector4Make(-pivotX, -pivotY, localWidth, localHeight)

            if _clips {
                let clipsCtx = ctx.clone(ViewFrameContext(yogaID, localMatrix, _lastBounds, Int64(localN)))
                pushClips(clipsCtx)
                localN += 1
            }

            for view in views {
                let viewCtx = ctx.clone(ViewFrameContext(yogaID, localMatrix, _lastBounds, Int64(localN), _sizeToFit))
                view.beRender(viewCtx)
                localN += 1
            }

            localMatrix = GLKMatrix4Translate(localMatrix,
                                               -pivotX,
                                               -pivotY,
                                               0)

            // TODO: set clipBounds...
            for child in _children {
                let childCtx = ctx.clone(ViewFrameContext(yogaID, localMatrix, _lastBounds, Int64(localN)))
                localN = child.render_recursive(localN, childCtx)
            }

            if _clips {
                let clipsCtx = ctx.clone(ViewFrameContext(yogaID, localMatrix, _lastBounds, Int64(localN)))
                popClips(clipsCtx)
                localN += 1
            }
        }

        return localN
    }

    private func pushClips(_ ctx: RenderFrameContext) {
        let geom = _clippingGeometry.next()

        _clippingVertices = geom.vertices

        if let vertices = _clippingVertices {
            vertices.reserve(6 * 7)
            vertices.clear()

            let xmin = ctx.view.bounds.xMin()
            let ymin = ctx.view.bounds.yMin()
            let xmax = ctx.view.bounds.xMax()
            let ymax = ctx.view.bounds.yMax()

            vertices.pushQuadVC(ctx.view.matrix,
                                GLKVector3Make(xmin, ymin, 0),
                                GLKVector3Make(xmax, ymin, 0),
                                GLKVector3Make(xmax, ymax, 0),
                                GLKVector3Make(xmin, ymax, 0),
                                GLKVector4Make(1.0, 1.0, 1.0, 1.0))

            ctx.renderer.beSubmitRenderUnit(ctx, RenderUnit(ctx,
                                                          .stencilBegin,
                                                          vertices,
                                                          ctx.view.bounds.size()))
            ctx.renderer.beSubmitRenderFinished(ctx)
        }
    }

    private func popClips(_ ctx: RenderFrameContext) {
        if let vertices = _clippingVertices {
            ctx.renderer.beSubmitRenderUnit(ctx, RenderUnit(ctx,
                                                          .stencilEnd,
                                                          vertices,
                                                          ctx.view.bounds.size()))
            ctx.renderer.beSubmitRenderFinished(ctx)
        }
    }

    // MARK: - Yoga Setters

    @discardableResult public func removeAll() -> Self {
        _children.removeAll()
        YGNodeRemoveAllChildren(node)
        return self
    }

    @discardableResult public func view(_ view: Viewable) -> Self {
        views.append(view)
        return self
    }

    @discardableResult public func views(_ view: [Viewable]) -> Self {
        views.append(contentsOf: views)
        return self
    }

    @discardableResult public func child(_ yoga: Yoga) -> Self {
        _children.append(yoga)
        YGNodeInsertChild(node, yoga.node, YGNodeGetChildCount(node))
        return self
    }

    @discardableResult public func children(_ yogas: [Yoga]) -> Self {
        _children.append(contentsOf: yogas)
        for yoga in yogas {
            YGNodeInsertChild(node, yoga.node, YGNodeGetChildCount(node))
        }
        return self
    }

    @discardableResult public func clips(_ vvv: Bool) -> Self {
        _clips = vvv
        return self
    }

    // MARK: - YGNode Setters

    @discardableResult public func sizeToFit(_ bbb: Bool) -> Self {
        _sizeToFit = bbb
        return self
    }

    @discardableResult public func fill() -> Self {
        YGNodeStyleSetWidthPercent(node, 100)
        YGNodeStyleSetHeightPercent(node, 100)
        return self
    }

    @discardableResult public func fit() -> Self {
        YGNodeStyleSetWidthAuto(node)
        YGNodeStyleSetHeightAuto(node)
        return self
    }

    @discardableResult public func center() -> Self {
        YGNodeStyleSetJustifyContent(node, .center)
        YGNodeStyleSetAlignItems(node, .center)
        return self
    }

    @discardableResult public func size(_ posX: Pixel, _ posY: Pixel) -> Self {
        YGNodeStyleSetWidth(node, posX)
        YGNodeStyleSetHeight(node, posY)
        return self
    }

    @discardableResult public func size(_ pctX: Percentage, _ pctY: Percentage) -> Self {
        YGNodeStyleSetWidthPercent(node, pctX.value)
        YGNodeStyleSetHeightPercent(node, pctY.value)
        return self
    }

    @discardableResult public func bounds(_ posX: Float, _ posY: Float, _  width: Float, _ height: Float) -> Self {
        YGNodeStyleSetPosition(node, .start, posX)
        YGNodeStyleSetPosition(node, .top, posY)
        YGNodeStyleSetWidth(node, width)
        YGNodeStyleSetHeight(node, height)
        return self
    }

    @discardableResult public func grow(_ vvv: Float = 1.0) -> Self { YGNodeStyleSetFlexGrow(node, vvv); return self }
    @discardableResult public func shrink(_ vvv: Float = 1.0) -> Self { YGNodeStyleSetFlexShrink(node, vvv); return self }

    @discardableResult public func safeTop(_ vvv: Bool=true) -> Self { _safeTop = vvv; return self }
    @discardableResult public func safeLeft(_ vvv: Bool=true) -> Self { _safeLeft = vvv; return self }
    @discardableResult public func safeBottom(_ vvv: Bool=true) -> Self { _safeBottom = vvv; return self }
    @discardableResult public func safeRight(_ vvv: Bool=true) -> Self { _safeRight = vvv; return self }

    @discardableResult public func pivot(_ xxx: Float, _ yyy: Float) -> Self { _pivot = GLKVector2Make(xxx, yyy); return self }
    @discardableResult public func anchor(_ xxx: Float, _ yyy: Float) -> Self { _anchor = GLKVector2Make(xxx, yyy); return self }

    @discardableResult public func scaleX(_ vvv: Float) -> Self { _scale = GLKVector3Make(vvv, _scale.y, _scale.z); return self }
    @discardableResult public func scaleY(_ vvv: Float) -> Self { _scale = GLKVector3Make(_scale.x, vvv, _scale.z); return self }
    @discardableResult public func scaleZ(_ vvv: Float) -> Self { _scale = GLKVector3Make(_scale.x, _scale.y, vvv); return self }
    @discardableResult public func scaleAll(_ vvv: Float) -> Self { _scale = GLKVector3Make(vvv, vvv, vvv); return self }
    @discardableResult public func scale(_ vvv: GLKVector3) -> Self { _scale = vvv; return self }

    @discardableResult public func rotateX(_ vvv: Float) -> Self { _rotation = GLKVector3Make(vvv, _rotation.y, _rotation.z); return self }
    @discardableResult public func rotateY(_ vvv: Float) -> Self { _rotation = GLKVector3Make(_rotation.x, vvv, _rotation.z); return self }
    @discardableResult public func rotateZ(_ vvv: Float) -> Self { _rotation = GLKVector3Make(_rotation.x, _rotation.y, vvv); return self }
    @discardableResult public func rotate(_ vvv: GLKVector3) -> Self { _rotation = vvv; return self }

    @discardableResult public func rows() -> Self { YGNodeStyleSetFlexDirection(node, .row); return self }
    @discardableResult public func columns() -> Self { YGNodeStyleSetFlexDirection(node, .column); return self }

    @discardableResult public func rowsReversed() -> Self { YGNodeStyleSetFlexDirection(node, .rowReverse); return self }
    @discardableResult public func columnsReversed() -> Self { YGNodeStyleSetFlexDirection(node, .columnReverse); return self }

    @discardableResult public func rightToLeft() -> Self { YGNodeStyleSetDirection(node, .RTL); return self }
    @discardableResult public func leftToRight() -> Self { YGNodeStyleSetDirection(node, .LTR); return self }

    @discardableResult public func justifyStart() -> Self { YGNodeStyleSetJustifyContent(node, .flexStart); return self }
    @discardableResult public func justifyCenter() -> Self { YGNodeStyleSetJustifyContent(node, .center); return self }
    @discardableResult public func justifyEnd() -> Self { YGNodeStyleSetJustifyContent(node, .flexEnd); return self }
    @discardableResult public func justifyBetween() -> Self { YGNodeStyleSetJustifyContent(node, .spaceBetween); return self }
    @discardableResult public func justifyAround() -> Self { YGNodeStyleSetJustifyContent(node, .spaceAround); return self }
    @discardableResult public func justifyEvenly() -> Self { YGNodeStyleSetJustifyContent(node, .spaceEvenly); return self }

    @discardableResult public func nowrap() -> Self { YGNodeStyleSetFlexWrap(node, .noWrap); return self }
    @discardableResult public func wrap() -> Self { YGNodeStyleSetFlexWrap(node, .wrap); return self }

    @discardableResult public func itemsAuto() -> Self { YGNodeStyleSetAlignItems(node, .auto); return self }
    @discardableResult public func itemsStart() -> Self { YGNodeStyleSetAlignItems(node, .flexStart); return self }
    @discardableResult public func itemsCenter() -> Self { YGNodeStyleSetAlignItems(node, .center); return self }
    @discardableResult public func itemsEnd() -> Self { YGNodeStyleSetAlignItems(node, .flexEnd); return self }
    @discardableResult public func itemsBetween() -> Self { YGNodeStyleSetAlignItems(node, .spaceBetween); return self }
    @discardableResult public func itemsAround() -> Self { YGNodeStyleSetAlignItems(node, .spaceAround); return self }
    @discardableResult public func itemsBaseline() -> Self { YGNodeStyleSetAlignItems(node, .baseline); return self }
    @discardableResult public func itemsStretch() -> Self { YGNodeStyleSetAlignItems(node, .stretch); return self }

    @discardableResult public func selfAuto() -> Self { YGNodeStyleSetAlignSelf(node, .auto); return self }
    @discardableResult public func selfStart() -> Self { YGNodeStyleSetAlignSelf(node, .flexStart); return self }
    @discardableResult public func selfCenter() -> Self { YGNodeStyleSetAlignSelf(node, .center); return self }
    @discardableResult public func selfEnd() -> Self { YGNodeStyleSetAlignSelf(node, .flexEnd); return self }
    @discardableResult public func selfBetween() -> Self { YGNodeStyleSetAlignSelf(node, .spaceBetween); return self }
    @discardableResult public func selfAround() -> Self { YGNodeStyleSetAlignSelf(node, .spaceAround); return self }
    @discardableResult public func selfBaseline() -> Self { YGNodeStyleSetAlignSelf(node, .baseline); return self }
    @discardableResult public func selfStretch() -> Self { YGNodeStyleSetAlignSelf(node, .stretch); return self }

    @discardableResult public func absolute() -> Self { YGNodeStyleSetPositionType(node, .absolute); return self }
    @discardableResult public func relative() -> Self { YGNodeStyleSetPositionType(node, .relative); return self }

    @discardableResult public func origin(_ posX: Pixel, _ posY: Pixel) -> Self { YGNodeStyleSetPosition(node, .left, posX); YGNodeStyleSetPosition(node, .top, posY); _usesLeft = true; _usesTop = true; return self }
    @discardableResult public func origin(_ pctX: Percentage, _ pctY: Percentage) -> Self { YGNodeStyleSetPositionPercent(node, .left, pctX.value); YGNodeStyleSetPositionPercent(node, .top, pctY.value); _usesLeft = true; _usesTop = true; return self }

    @discardableResult public func top(_ pixel: Pixel) -> Self { YGNodeStyleSetPosition(node, .top, pixel); _usesTop = true; return self }
    @discardableResult public func left(_ pixel: Pixel) -> Self { YGNodeStyleSetPosition(node, .left, pixel); _usesLeft = true; return self }
    @discardableResult public func bottom(_ pixel: Pixel) -> Self { YGNodeStyleSetPosition(node, .bottom, pixel); _usesTop = false; return self }
    @discardableResult public func right(_ pixel: Pixel) -> Self { YGNodeStyleSetPosition(node, .right, pixel); _usesLeft = false; return self }

    @discardableResult public func top(_ percent: Percentage) -> Self { YGNodeStyleSetPositionPercent(node, .top, percent.value); _usesTop = true; return self }
    @discardableResult public func left(_ percent: Percentage) -> Self { YGNodeStyleSetPositionPercent(node, .left, percent.value); _usesLeft = true; return self }
    @discardableResult public func bottom(_ percent: Percentage) -> Self { YGNodeStyleSetPositionPercent(node, .bottom, percent.value); _usesTop = false; return self }
    @discardableResult public func right(_ percent: Percentage) -> Self { YGNodeStyleSetPositionPercent(node, .right, percent.value); _usesLeft = false; return self }

    @discardableResult public func paddingAll(_ pixel: Pixel) -> Self { YGNodeStyleSetPadding(node, .all, pixel); return self }
    @discardableResult public func paddingTop(_ pixel: Pixel) -> Self { YGNodeStyleSetPadding(node, .top, pixel); return self }
    @discardableResult public func paddingLeft(_ pixel: Pixel) -> Self { YGNodeStyleSetPadding(node, .left, pixel); return self }
    @discardableResult public func paddingBottom(_ pixel: Pixel) -> Self { YGNodeStyleSetPadding(node, .bottom, pixel); return self }
    @discardableResult public func paddingRight(_ pixel: Pixel) -> Self { YGNodeStyleSetPadding(node, .right, pixel); return self }

    @discardableResult public func paddingAll(_ percent: Percentage) -> Self { YGNodeStyleSetPaddingPercent(node, .all, percent.value); return self }
    @discardableResult public func paddingTop(_ percent: Percentage) -> Self { YGNodeStyleSetPaddingPercent(node, .top, percent.value); return self }
    @discardableResult public func paddingLeft(_ percent: Percentage) -> Self { YGNodeStyleSetPaddingPercent(node, .left, percent.value); return self }
    @discardableResult public func paddingBottom(_ percent: Percentage) -> Self { YGNodeStyleSetPaddingPercent(node, .bottom, percent.value); return self }
    @discardableResult public func paddingRight(_ percent: Percentage) -> Self { YGNodeStyleSetPaddingPercent(node, .right, percent.value); return self }

    @discardableResult public func marginAll(_ pixel: Pixel) -> Self { YGNodeStyleSetMargin(node, .all, pixel); return self }
    @discardableResult public func marginTop(_ pixel: Pixel) -> Self { YGNodeStyleSetMargin(node, .top, pixel); return self }
    @discardableResult public func marginLeft(_ pixel: Pixel) -> Self { YGNodeStyleSetMargin(node, .left, pixel); return self }
    @discardableResult public func marginBottom(_ pixel: Pixel) -> Self { YGNodeStyleSetMargin(node, .bottom, pixel); return self }
    @discardableResult public func marginRight(_ pixel: Pixel) -> Self { YGNodeStyleSetMargin(node, .right, pixel); return self }

    @discardableResult public func marginAll(_ percent: Percentage) -> Self { YGNodeStyleSetMarginPercent(node, .all, percent.value); return self }
    @discardableResult public func marginTop(_ percent: Percentage) -> Self { YGNodeStyleSetMarginPercent(node, .top, percent.value); return self }
    @discardableResult public func marginLeft(_ percent: Percentage) -> Self { YGNodeStyleSetMarginPercent(node, .left, percent.value); return self }
    @discardableResult public func marginBottom(_ percent: Percentage) -> Self { YGNodeStyleSetMarginPercent(node, .bottom, percent.value); return self }
    @discardableResult public func marginRight(_ percent: Percentage) -> Self { YGNodeStyleSetMarginPercent(node, .right, percent.value); return self }

    // These are direct calls to the Yoga methods (most of which require parameters)

    @discardableResult public func direction(_ vvv: YGDirection) -> Self { YGNodeStyleSetDirection(node, vvv); return self }
    @discardableResult public func flexDirection(_ vvv: YGFlexDirection) -> Self { YGNodeStyleSetFlexDirection(node, vvv); return self }

    @discardableResult public func justifyContent(_ vvv: YGJustify) -> Self { YGNodeStyleSetJustifyContent(node, vvv); return self }

    @discardableResult public func alignContent(_ vvv: YGAlign) -> Self { YGNodeStyleSetAlignContent(node, vvv); return self }
    @discardableResult public func alignItems(_ vvv: YGAlign) -> Self { YGNodeStyleSetAlignItems(node, vvv); return self }
    @discardableResult public func alignSelf(_ vvv: YGAlign) -> Self { YGNodeStyleSetAlignSelf(node, vvv); return self }

    @discardableResult public func positionType(_ vvv: YGPositionType) -> Self { YGNodeStyleSetPositionType(node, vvv); return self }

    @discardableResult public func overflow(_ vvv: YGOverflow) -> Self { YGNodeStyleSetOverflow(node, vvv); return self }
    @discardableResult public func display(_ vvv: YGDisplay) -> Self { YGNodeStyleSetDisplay(node, vvv); return self }

    @discardableResult public func flexWrap(_ vvv: YGWrap) -> Self { YGNodeStyleSetFlexWrap(node, vvv); return self }
    @discardableResult public func flex(_ vvv: Float) -> Self { YGNodeStyleSetFlex(node, vvv); return self }
    @discardableResult public func flexGrow(_ vvv: Float) -> Self { YGNodeStyleSetFlexGrow(node, vvv); return self }
    @discardableResult public func flexShrink(_ vvv: Float) -> Self { YGNodeStyleSetFlexShrink(node, vvv); return self }
    @discardableResult public func flexAuto() -> Self { YGNodeStyleSetFlexBasisAuto(node); return self }

    @discardableResult public func flexBasis(_ pixel: Pixel) -> Self { YGNodeStyleSetFlexBasis(node, pixel); return self }
    @discardableResult public func flexBasis(_ percent: Percentage) -> Self { YGNodeStyleSetFlexBasisPercent(node, percent.value); return self }

    @discardableResult public func position(edge: YGEdge, _ pixel: Pixel) -> Self { YGNodeStyleSetPosition(node, edge, pixel); return self }
    @discardableResult public func position(edge: YGEdge, _ percent: Percentage) -> Self { YGNodeStyleSetPositionPercent(node, edge, percent.value); return self }

    @discardableResult public func margin(edge: YGEdge, _ pixel: Pixel) -> Self { YGNodeStyleSetMargin(node, edge, pixel); return self }
    @discardableResult public func margin(edge: YGEdge, _ percent: Percentage) -> Self { YGNodeStyleSetMarginPercent(node, edge, percent.value); return self }
    @discardableResult public func marginAuto(edge: YGEdge) -> Self { YGNodeStyleSetMarginAuto(node, edge); return self }

    @discardableResult public func padding(edge: YGEdge, _ pixel: Pixel) -> Self { YGNodeStyleSetPadding(node, edge, pixel); return self }
    @discardableResult public func padding(edge: YGEdge, _ percent: Percentage) -> Self { YGNodeStyleSetPaddingPercent(node, edge, percent.value); return self }

    @discardableResult public func border(edge: YGEdge, pixel: Pixel) -> Self { YGNodeStyleSetBorder(node, edge, pixel); return self }

    @discardableResult public func width(_ pixel: Pixel) -> Self { YGNodeStyleSetWidth(node, pixel); return self }
    @discardableResult public func width(_ percent: Percentage) -> Self { YGNodeStyleSetWidthPercent(node, percent.value); return self }
    @discardableResult public func widthAuto() -> Self { YGNodeStyleSetWidthAuto(node); return self }

    @discardableResult public func height(_ pixel: Pixel) -> Self { YGNodeStyleSetHeight(node, pixel); return self }
    @discardableResult public func height(_ percent: Percentage) -> Self { YGNodeStyleSetHeightPercent(node, percent.value); return self }
    @discardableResult public func heightAuto() -> Self { YGNodeStyleSetHeightAuto(node); return self }

    @discardableResult public func minWidth(_ pixel: Pixel) -> Self { YGNodeStyleSetMinWidth(node, pixel); return self }
    @discardableResult public func minWidth(_ percent: Percentage) -> Self { YGNodeStyleSetMinWidthPercent(node, percent.value); return self }

    @discardableResult public func minHeight(_ pixel: Pixel) -> Self { YGNodeStyleSetMinHeight(node, pixel); return self }
    @discardableResult public func minHeight(_ percent: Percentage) -> Self { YGNodeStyleSetMinHeightPercent(node, percent.value); return self }

    @discardableResult public func maxWidth(_ pixel: Pixel) -> Self { YGNodeStyleSetMaxWidth(node, pixel); return self }
    @discardableResult public func maxWidth(_ percent: Percentage) -> Self { YGNodeStyleSetMaxWidthPercent(node, percent.value); return self }

    @discardableResult public func maxHeight(_ pixel: Pixel) -> Self { YGNodeStyleSetMaxHeight(node, pixel); return self }
    @discardableResult public func maxHeight(_ percent: Percentage) -> Self { YGNodeStyleSetMaxHeightPercent(node, percent.value); return self }

    @discardableResult public func aspectRatio(ratio: Float) -> Self { YGNodeStyleSetAspectRatio(node, ratio); return self }

    func getWidth() -> Float { return YGNodeLayoutGetWidth(node); }
    func getHeight() -> Float { return YGNodeLayoutGetHeight(node); }

    /*
     fun _handleNAN(v:Float):Float -> Self { if v.nan() then 0.0 else v end }
     
     fun getRotateX():Float -> Self { _rotation.x; return self }
     fun getRotateY():Float -> Self { _rotation.y; return self }
     fun getRotateZ():Float -> Self { _rotation.z; return self }
     
     fun getPivot():GLKVector2 -> Self { _pivot }
     fun getAnchor():GLKVector2 -> Self { _anchor }
     fun getScale():GLKVector3 -> Self { _scale }
     fun getWidth():Float -> Self { _handleNAN(YGNodeLayoutGetWidth(node)); return self }
     fun getHeight():Float -> Self { _handleNAN(YGNodeLayoutGetHeight(node)); return self }
     
     
     func getZ():Float -> Self { _z }
     func z(v:Float) -> Self { _z = v }
     
     // These overloaded methods try to determine in what aspect "X" and "Y" are meant in the node's style, and then gets or sets those
     // in that manner. This is used by Laba when animating so that it doesn't need to worry about how the user set those in the style
     fun getY():Float -> Self { if _usesTop then _handleNAN(YGNodeStyleGetPositionFloat(node, .top)) else _handleNAN(YGNodeStyleGetPositionFloat(node, .bottom)) end }
     fun getX():Float -> Self { if _usesLeft then _handleNAN(YGNodeStyleGetPositionFloat(node, .left)) else _handleNAN(YGNodeStyleGetPositionFloat(node, .right)) end }
     func y(v:Float) -> Self { if _usesTop then top(v) else bottom(v) end }
     func x(v:Float) -> Self { if _usesLeft then left(v) else YGNodeStyleSetPosition(node, .right, v) end }
     */
}
