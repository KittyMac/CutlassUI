//
//  Yoga.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

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

public class Yoga {
    private var parent:Yoga?
    private var node:YGNodeRef
    
    private var views:[Viewable] = []
    private var _children:[Yoga] = []
    
    private var _pivot = GLKVector2Make(0.5,0.5)
    private var _anchor = GLKVector2Make(0.5,0.5)
    
    private var _rotation = GLKVector3Make(0, 0, 0)
    private var _scale = GLKVector3Make(1.0, 1.0, 1.0)
    
    private var _alpha:Float = 1.0
    private var _z:Float = 0.0
    
    private var _last_bounds:GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    
    private var _usesLeft:Bool = true
    private var _usesTop:Bool = true
    
    private var _safeTop:Bool = false
    private var _safeLeft:Bool = false
    private var _safeBottom:Bool = false
    private var _safeRight:Bool = false
    
    public init() {
        node = YGNodeNew()
    }
    
    
    public func print() {
        YGNodePrint(node, [.layout, .style, .children])
    }
    
    
    // MARK - Walkers
    
    public func layout() {
        // Before we can calculate the layout, we need to see if any of our children sizeToFit their content. If we do, we need
        // to have them set the size on the appropriate yoga node
        //preLayout()
        
        YGNodeCalculateLayout(node, YGNodeStyleGetWidth(node).value, YGNodeStyleGetHeight(node).value, .LTR)
        
        // postLayout gives the opporunity to nodes to adjust themselves based on the layout which just happened. Specifically,
        // if calls any custom() callbacks that exist on nodes
        //if postLayout() then
        //  YGNodeCalculateLayout(node, YGNodeStyleGetWidth(node).value, YGNodeStyleGetHeight(node).value, .LTR)
        //end
    }
    
    public func render(_ ctx:RenderFrameContext) -> Int {
        let n = render_recursive(0, ctx)
        return n
    }
    
    private func render_recursive(_ n:Int, _ ctx:RenderFrameContext) -> Int {
        var local_n:Int = n
        
        let local_left = YGNodeLayoutGetLeft(node)
        let local_top = YGNodeLayoutGetTop(node)
        let local_width = YGNodeLayoutGetWidth(node)
        let local_height = YGNodeLayoutGetHeight(node)
        
        if (local_width > 0) && (local_height > 0) && (_alpha > 0) {
            
            let pivotX = _pivot.x * local_width
            let pivotY = _pivot.y * local_height
            
            var local_matrix = GLKMatrix4Translate(ctx.matrix,
                                                   (local_left + (_anchor.x * local_width)) - (local_width / 2),
                                                   (local_top + (_anchor.y * local_height)) - (local_height / 2),
                                                   _z)
            
            local_matrix = GLKMatrix4Translate(local_matrix,
                                                pivotX,
                                                pivotY,
                                                0)
            
            if (_rotation.x != 0) {
                local_matrix = GLKMatrix4RotateX(local_matrix, _rotation.x)
            }
            if (_rotation.y != 0) {
                local_matrix = GLKMatrix4RotateX(local_matrix, _rotation.y)
            }
            if (_rotation.z != 0) {
                local_matrix = GLKMatrix4RotateX(local_matrix, _rotation.z)
            }
            
            if (_scale.x != 1.0) || (_scale.y != 1.0) || (_scale.z != 1.0) {
                local_matrix = GLKMatrix4Scale(local_matrix, _scale.x, _scale.y, _scale.z)
            }
            
            // TODO: parentContentOffset
            _last_bounds = GLKVector4Make(-pivotX, -pivotY, local_width, local_height)
            
            let view_ctx = RenderFrameContext(renderer: ctx.renderer,
                                              viewSize: ctx.viewSize,
                                              drawable: ctx.drawable,
                                                matrix: local_matrix,
                                                bounds: _last_bounds)
            /*
            let savedAlpha = ctx.alpha
            
            ctx.matrix = local_matrix
            ctx.nodeID = id()
            ctx.contentSize = contentSize()
            ctx.nodeSize = nodeSize()
            ctx.parentContentOffset = parentContentOffset
            ctx.alpha = frameContext.alpha * _alpha
            */
            for view in views {
                view.render(view_ctx)
                local_n += 1
            }
            
            local_matrix = GLKMatrix4Translate(local_matrix,
                                               -pivotX,
                                               -pivotY,
                                               0)
            
            let child_ctx = RenderFrameContext(renderer: ctx.renderer,
                                               viewSize: ctx.viewSize,
                                               drawable: ctx.drawable,
                                               matrix: local_matrix,
                                               bounds: _last_bounds)
            
            for child in _children {
                local_n = child.render_recursive(local_n, child_ctx)
            }
        }
        
        return local_n
    }
    
    // MARK: - Yoga Setters
    
    @discardableResult public func removeAll() -> Self {
        _children.removeAll()
        YGNodeRemoveAllChildren(node)
        return self
    }
    
    @discardableResult public func view(_ view:Viewable) -> Self {
        views.append(view)
        return self
    }
    
    @discardableResult public func views(_ view:[Viewable]) -> Self {
        views.append(contentsOf: views)
        return self
    }
    
    @discardableResult public func child(_ yoga:Yoga) -> Self {
        _children.append(yoga)
        YGNodeInsertChild(node, yoga.node, YGNodeGetChildCount(node))
        return self
    }
    
    @discardableResult public func children(_ yogas:[Yoga]) -> Self {
        _children.append(contentsOf: yogas)
        for yoga in yogas {
            YGNodeInsertChild(node, yoga.node, YGNodeGetChildCount(node))
        }
        return self
    }
    
    // MARK: - YGNode Setters
    
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
    
    @discardableResult public func size(px:(Float,Float)) -> Self {
        YGNodeStyleSetWidth(node, px.0)
        YGNodeStyleSetHeight(node, px.1)
        return self
    }
    
    @discardableResult public func size(percent:(Float,Float)) -> Self {
        YGNodeStyleSetWidthPercent(node, percent.0)
        YGNodeStyleSetHeightPercent(node, percent.1)
        return self
    }
    
    @discardableResult public func bounds(_ x:Float, _ y:Float, _  w:Float, _ h:Float) -> Self {
        YGNodeStyleSetPosition(node, .start, x)
        YGNodeStyleSetPosition(node, .top, y)
        YGNodeStyleSetWidth(node, w)
        YGNodeStyleSetHeight(node, h)
        return self
    }
    
    @discardableResult public func grow(_ v:Float = 1.0) -> Self { YGNodeStyleSetFlexGrow(node, v); return self }
    @discardableResult public func shrink(_ v:Float = 1.0) -> Self { YGNodeStyleSetFlexShrink(node, v); return self }
    
    @discardableResult public func safeTop(_ v:Bool=true) -> Self { _safeTop = v; return self }
    @discardableResult public func safeLeft(_ v:Bool=true) -> Self { _safeLeft = v; return self }
    @discardableResult public func safeBottom(_ v:Bool=true) -> Self { _safeBottom = v; return self }
    @discardableResult public func safeRight(_ v:Bool=true) -> Self { _safeRight = v; return self }
    
    @discardableResult public func pivot(_ x:Float, _ y:Float) -> Self { _pivot = GLKVector2Make(x, y); return self }
    @discardableResult public func anchor(_ x:Float, _ y:Float) -> Self { _anchor = GLKVector2Make(x, y); return self }
    
    @discardableResult public func scaleX(_ v:Float) -> Self { _scale = GLKVector3Make(v, _scale.y, _scale.z); return self }
    @discardableResult public func scaleY(_ v:Float) -> Self { _scale = GLKVector3Make(_scale.x, v, _scale.z); return self }
    @discardableResult public func scaleZ(_ v:Float) -> Self { _scale = GLKVector3Make(_scale.x, _scale.y, v); return self }
    @discardableResult public func scaleAll(_ v:Float) -> Self { _scale = GLKVector3Make(v, v, v); return self }
    @discardableResult public func scale(_ v:GLKVector3) -> Self { _scale = v; return self }
    
    @discardableResult public func rotateX(_ v:Float) -> Self { _rotation = GLKVector3Make(v, _rotation.y, _rotation.z); return self }
    @discardableResult public func rotateY(_ v:Float) -> Self { _rotation = GLKVector3Make(_rotation.x, v, _rotation.z); return self }
    @discardableResult public func rotateZ(_ v:Float) -> Self { _rotation = GLKVector3Make(_rotation.x, _rotation.y, v); return self }
    @discardableResult public func rotate(_ v:GLKVector3) -> Self { _rotation = v; return self }
    
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
    
    @discardableResult public func origin(px:(Float,Float)) -> Self { YGNodeStyleSetPosition(node, .left, px.0); YGNodeStyleSetPosition(node, .top, px.1); _usesLeft = true; _usesTop = true; return self }
    @discardableResult public func origin(percent:(Float,Float)) -> Self { YGNodeStyleSetPositionPercent(node, .left, percent.0); YGNodeStyleSetPositionPercent(node, .top, percent.1); _usesLeft = true; _usesTop = true; return self }
    
    @discardableResult public func top(px:Float) -> Self { YGNodeStyleSetPosition(node, .top, px); _usesTop = true; return self }
    @discardableResult public func left(px:Float) -> Self { YGNodeStyleSetPosition(node, .left, px); _usesLeft = true; return self }
    @discardableResult public func bottom(px:Float) -> Self { YGNodeStyleSetPosition(node, .bottom, px); _usesTop = false; return self }
    @discardableResult public func right(px:Float) -> Self { YGNodeStyleSetPosition(node, .right, px); _usesLeft = false; return self }
    
    @discardableResult public func top(percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, .top, percent); _usesTop = true; return self }
    @discardableResult public func left(percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, .left, percent); _usesLeft = true; return self }
    @discardableResult public func bottom(percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, .bottom, percent); _usesTop = false; return self }
    @discardableResult public func right(percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, .right, percent); _usesLeft = false; return self }
    
    @discardableResult public func paddingAll(px:Float) -> Self { YGNodeStyleSetPadding(node, .all, px); return self }
    @discardableResult public func paddingTop(px:Float) -> Self { YGNodeStyleSetPadding(node, .top, px); return self }
    @discardableResult public func paddingLeft(px:Float) -> Self { YGNodeStyleSetPadding(node, .left, px); return self }
    @discardableResult public func paddingBottom(px:Float) -> Self { YGNodeStyleSetPadding(node, .bottom, px); return self }
    @discardableResult public func paddingRight(px:Float) -> Self { YGNodeStyleSetPadding(node, .right, px); return self }
    
    @discardableResult public func paddingAll(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .all, percent); return self }
    @discardableResult public func paddingTop(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .top, percent); return self }
    @discardableResult public func paddingLeft(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .left, percent); return self }
    @discardableResult public func paddingBottom(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .bottom, percent); return self }
    @discardableResult public func paddingRight(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .right, percent); return self }
    
    @discardableResult public func marginAll(px:Float) -> Self { YGNodeStyleSetMargin(node, .all, px); return self }
    @discardableResult public func marginTop(px:Float) -> Self { YGNodeStyleSetMargin(node, .top, px); return self }
    @discardableResult public func marginLeft(px:Float) -> Self { YGNodeStyleSetMargin(node, .left, px); return self }
    @discardableResult public func marginBottom(px:Float) -> Self { YGNodeStyleSetMargin(node, .bottom, px); return self }
    @discardableResult public func marginRight(px:Float) -> Self { YGNodeStyleSetMargin(node, .right, px); return self }
    
    @discardableResult public func marginAll(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .all, percent); return self }
    @discardableResult public func marginTop(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .top, percent); return self }
    @discardableResult public func marginLeft(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .left, percent); return self }
    @discardableResult public func marginBottom(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .bottom, percent); return self }
    @discardableResult public func marginRight(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .right, percent); return self }
    
    
    // These are direct calls to the Yoga methods (most of which require parameters)
    
    @discardableResult public func direction(_ v:YGDirection) -> Self { YGNodeStyleSetDirection(node, v); return self }
    @discardableResult public func flexDirection(_ v:YGFlexDirection) -> Self { YGNodeStyleSetFlexDirection(node, v); return self }
    
    @discardableResult public func justifyContent(_ v:YGJustify) -> Self { YGNodeStyleSetJustifyContent(node, v); return self }
    
    @discardableResult public func alignContent(_ v:YGAlign) -> Self { YGNodeStyleSetAlignContent(node, v); return self }
    @discardableResult public func alignItems(_ v:YGAlign) -> Self { YGNodeStyleSetAlignItems(node, v); return self }
    @discardableResult public func alignSelf(_ v:YGAlign) -> Self { YGNodeStyleSetAlignSelf(node, v); return self }
    
    @discardableResult public func positionType(_ v:YGPositionType) -> Self { YGNodeStyleSetPositionType(node, v); return self }
    
    @discardableResult public func overflow(_ v:YGOverflow) -> Self { YGNodeStyleSetOverflow(node, v); return self }
    @discardableResult public func display(_ v:YGDisplay) -> Self { YGNodeStyleSetDisplay(node, v); return self }
    
    @discardableResult public func flexWrap(_ v:YGWrap) -> Self { YGNodeStyleSetFlexWrap(node, v); return self }
    @discardableResult public func flex(_ v:Float) -> Self { YGNodeStyleSetFlex(node, v); return self }
    @discardableResult public func flexGrow(_ v:Float) -> Self { YGNodeStyleSetFlexGrow(node, v); return self }
    @discardableResult public func flexShrink(_ v:Float) -> Self { YGNodeStyleSetFlexShrink(node, v); return self }
    @discardableResult public func flexAuto() -> Self { YGNodeStyleSetFlexBasisAuto(node); return self }
    
    @discardableResult public func flexBasis(px:Float) -> Self { YGNodeStyleSetFlexBasis(node, px); return self }
    @discardableResult public func flexBasis(percent:Float) -> Self { YGNodeStyleSetFlexBasisPercent(node, percent); return self }
    
    @discardableResult public func position(edge:YGEdge, px:Float) -> Self { YGNodeStyleSetPosition(node, edge, px); return self }
    @discardableResult public func position(edge:YGEdge, percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, edge, percent); return self }
    
    @discardableResult public func margin(edge:YGEdge, px:Float) -> Self { YGNodeStyleSetMargin(node, edge, px); return self }
    @discardableResult public func margin(edge:YGEdge, percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, edge, percent); return self }
    @discardableResult public func marginAuto(v1:YGEdge) -> Self { YGNodeStyleSetMarginAuto(node, v1); return self }
    
    @discardableResult public func padding(edge:YGEdge, px:Float) -> Self { YGNodeStyleSetPadding(node, edge, px); return self }
    @discardableResult public func padding(edge:YGEdge, percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, edge, percent); return self }
    
    @discardableResult public func border(v1:YGEdge, v2:Float) -> Self { YGNodeStyleSetBorder(node, v1, v2); return self }
    
    @discardableResult public func width(px:Float) -> Self { YGNodeStyleSetWidth(node, px); return self }
    @discardableResult public func width(percent:Float) -> Self { YGNodeStyleSetWidthPercent(node, percent); return self }
    @discardableResult public func widthAuto() -> Self { YGNodeStyleSetWidthAuto(node); return self }
    
    @discardableResult public func height(px:Float) -> Self { YGNodeStyleSetHeight(node, px); return self }
    @discardableResult public func height(percent:Float) -> Self { YGNodeStyleSetHeightPercent(node, percent); return self }
    @discardableResult public func heightAuto() -> Self { YGNodeStyleSetHeightAuto(node); return self }
    
    @discardableResult public func minWidth(px:Float) -> Self { YGNodeStyleSetMinWidth(node, px); return self }
    @discardableResult public func minWidth(percent:Float) -> Self { YGNodeStyleSetMinWidthPercent(node, percent); return self }
    
    @discardableResult public func minHeight(px:Float) -> Self { YGNodeStyleSetMinHeight(node, px); return self }
    @discardableResult public func minHeight(percent:Float) -> Self { YGNodeStyleSetMinHeightPercent(node, percent); return self }
    
    @discardableResult public func maxWidth(px:Float) -> Self { YGNodeStyleSetMaxWidth(node, px); return self }
    @discardableResult public func maxWidth(percent:Float) -> Self { YGNodeStyleSetMaxWidthPercent(node, percent); return self }
    
    @discardableResult public func maxHeight(px:Float) -> Self { YGNodeStyleSetMaxHeight(node, px); return self }
    @discardableResult public func maxHeight(percent:Float) -> Self { YGNodeStyleSetMaxHeightPercent(node, percent); return self }
    
    @discardableResult public func aspectRatio(v:Float) -> Self { YGNodeStyleSetAspectRatio(node, v); return self }
    
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
