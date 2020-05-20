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
 Yoga.fit().widthPercent(100).columns().center()
 .view( Color.red() )
 ])
 */

class Yoga {
    var parent:Yoga?
    var node:YGNodeRef
    
    var views:[Actor] = []
    
    private var _pivot = GLKVector2Make(0.5,0.5)
    private var _anchor = GLKVector2Make(0.5,0.5)
    
    private var _rotation = GLKVector3Make(0, 0, 0)
    private var _scale = GLKVector3Make(1.0, 1.0, 1.0)
    
    private var _usesLeft:Bool = true
    private var _usesTop:Bool = true
    
    private var _safeTop:Bool = false
    private var _safeLeft:Bool = false
    private var _safeBottom:Bool = false
    private var _safeRight:Bool = false
    
    init() {
        node = YGNodeNew()
    }
    
    
    func print() {
        YGNodePrint(node, [.layout, .style, .children])
    }
    
    
    // MARK - Walkers
    
    func layout() {
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
    
    
    // MARK: - Yoga Setters
    
    @discardableResult func view(_ view:Actor) -> Self {
        views.append(view)
        return self
    }
    
    // MARK: - YGNode Setters
    
    @discardableResult func fill() -> Self {
        YGNodeStyleSetWidthPercent(node, 100)
        YGNodeStyleSetHeightPercent(node, 100)
        return self
    }
    
    @discardableResult func fit() -> Self {
        YGNodeStyleSetWidthAuto(node)
        YGNodeStyleSetHeightAuto(node)
        return self
    }
    
    @discardableResult func center() -> Self {
        YGNodeStyleSetJustifyContent(node, .center)
        YGNodeStyleSetAlignItems(node, .center)
        return self
    }
    
    @discardableResult func size(_ w:Float, _ h:Float) -> Self {
        YGNodeStyleSetWidth(node, w)
        YGNodeStyleSetHeight(node, h)
        return self
    }
    
    @discardableResult func sizePercent(_ w:Float, _ h:Float) -> Self {
        YGNodeStyleSetWidthPercent(node, w)
        YGNodeStyleSetHeightPercent(node, h)
        return self
    }
    
    @discardableResult func bounds(_ x:Float, _ y:Float, _  w:Float, _ h:Float) -> Self {
        YGNodeStyleSetPosition(node, .start, x)
        YGNodeStyleSetPosition(node, .top, y)
        YGNodeStyleSetWidth(node, w)
        YGNodeStyleSetHeight(node, h)
        return self
    }
    
    @discardableResult func grow(_ v:Float = 1.0) -> Self { YGNodeStyleSetFlexGrow(node, v); return self }
    @discardableResult func shrink(_ v:Float = 1.0) -> Self { YGNodeStyleSetFlexShrink(node, v); return self }
    
    @discardableResult func safeTop(_ v:Bool=true) -> Self { _safeTop = v; return self }
    @discardableResult func safeLeft(_ v:Bool=true) -> Self { _safeLeft = v; return self }
    @discardableResult func safeBottom(_ v:Bool=true) -> Self { _safeBottom = v; return self }
    @discardableResult func safeRight(_ v:Bool=true) -> Self { _safeRight = v; return self }
    
    @discardableResult func pivot(_ x:Float, _ y:Float) -> Self { _pivot = GLKVector2Make(x, y); return self }
    @discardableResult func anchor(_ x:Float, _ y:Float) -> Self { _anchor = GLKVector2Make(x, y); return self }
    
    @discardableResult func scaleX(_ v:Float) -> Self { _scale = GLKVector3Make(v, _scale.y, _scale.z); return self }
    @discardableResult func scaleY(_ v:Float) -> Self { _scale = GLKVector3Make(_scale.x, v, _scale.z); return self }
    @discardableResult func scaleZ(_ v:Float) -> Self { _scale = GLKVector3Make(_scale.x, _scale.y, v); return self }
    @discardableResult func scaleAll(_ v:Float) -> Self { _scale = GLKVector3Make(v, v, v); return self }
    @discardableResult func scale(_ v:GLKVector3) -> Self { _scale = v; return self }
    
    @discardableResult func rotateX(_ v:Float) -> Self { _rotation = GLKVector3Make(v, _rotation.y, _rotation.z); return self }
    @discardableResult func rotateY(_ v:Float) -> Self { _rotation = GLKVector3Make(_rotation.x, v, _rotation.z); return self }
    @discardableResult func rotateZ(_ v:Float) -> Self { _rotation = GLKVector3Make(_rotation.x, _rotation.y, v); return self }
    @discardableResult func rotate(_ v:GLKVector3) -> Self { _rotation = v; return self }
    
    @discardableResult func rows() -> Self { YGNodeStyleSetFlexDirection(node, .row); return self }
    @discardableResult func columns() -> Self { YGNodeStyleSetFlexDirection(node, .column); return self }
    
    @discardableResult func rowsReversed() -> Self { YGNodeStyleSetFlexDirection(node, .rowReverse); return self }
    @discardableResult func columnsReversed() -> Self { YGNodeStyleSetFlexDirection(node, .columnReverse); return self }
    
    @discardableResult func rightToLeft() -> Self { YGNodeStyleSetDirection(node, .RTL); return self }
    @discardableResult func leftToRight() -> Self { YGNodeStyleSetDirection(node, .LTR); return self }
    
    @discardableResult func justifyStart() -> Self { YGNodeStyleSetJustifyContent(node, .flexStart); return self }
    @discardableResult func justifyCenter() -> Self { YGNodeStyleSetJustifyContent(node, .center); return self }
    @discardableResult func justifyEnd() -> Self { YGNodeStyleSetJustifyContent(node, .flexEnd); return self }
    @discardableResult func justifyBetween() -> Self { YGNodeStyleSetJustifyContent(node, .spaceBetween); return self }
    @discardableResult func justifyAround() -> Self { YGNodeStyleSetJustifyContent(node, .spaceAround); return self }
    @discardableResult func justifyEvenly() -> Self { YGNodeStyleSetJustifyContent(node, .spaceEvenly); return self }
    
    @discardableResult func nowrap() -> Self { YGNodeStyleSetFlexWrap(node, .noWrap); return self }
    @discardableResult func wrap() -> Self { YGNodeStyleSetFlexWrap(node, .wrap); return self }
    
    @discardableResult func itemsAuto() -> Self { YGNodeStyleSetAlignItems(node, .auto); return self }
    @discardableResult func itemsStart() -> Self { YGNodeStyleSetAlignItems(node, .flexStart); return self }
    @discardableResult func itemsCenter() -> Self { YGNodeStyleSetAlignItems(node, .center); return self }
    @discardableResult func itemsEnd() -> Self { YGNodeStyleSetAlignItems(node, .flexEnd); return self }
    @discardableResult func itemsBetween() -> Self { YGNodeStyleSetAlignItems(node, .spaceBetween); return self }
    @discardableResult func itemsAround() -> Self { YGNodeStyleSetAlignItems(node, .spaceAround); return self }
    @discardableResult func itemsBaseline() -> Self { YGNodeStyleSetAlignItems(node, .baseline); return self }
    @discardableResult func itemsStretch() -> Self { YGNodeStyleSetAlignItems(node, .stretch); return self }
    
    @discardableResult func selfAuto() -> Self { YGNodeStyleSetAlignSelf(node, .auto); return self }
    @discardableResult func selfStart() -> Self { YGNodeStyleSetAlignSelf(node, .flexStart); return self }
    @discardableResult func selfCenter() -> Self { YGNodeStyleSetAlignSelf(node, .center); return self }
    @discardableResult func selfEnd() -> Self { YGNodeStyleSetAlignSelf(node, .flexEnd); return self }
    @discardableResult func selfBetween() -> Self { YGNodeStyleSetAlignSelf(node, .spaceBetween); return self }
    @discardableResult func selfAround() -> Self { YGNodeStyleSetAlignSelf(node, .spaceAround); return self }
    @discardableResult func selfBaseline() -> Self { YGNodeStyleSetAlignSelf(node, .baseline); return self }
    @discardableResult func selfStretch() -> Self { YGNodeStyleSetAlignSelf(node, .stretch); return self }
    
    @discardableResult func absolute() -> Self { YGNodeStyleSetPositionType(node, .absolute); return self }
    @discardableResult func relative() -> Self { YGNodeStyleSetPositionType(node, .relative); return self }
    
    @discardableResult func origin(_ x:Float, _ y:Float) -> Self { YGNodeStyleSetPosition(node, .left, x); YGNodeStyleSetPosition(node, .top, y); _usesLeft = true; _usesTop = true; return self }
    @discardableResult func originPercent(_ x:Float, _ y:Float) -> Self { YGNodeStyleSetPositionPercent(node, .left, x); YGNodeStyleSetPositionPercent(node, .top, y); _usesLeft = true; _usesTop = true; return self }
    
    @discardableResult func top(px:Float) -> Self { YGNodeStyleSetPosition(node, .top, px); _usesTop = true; return self }
    @discardableResult func left(px:Float) -> Self { YGNodeStyleSetPosition(node, .left, px); _usesLeft = true; return self }
    @discardableResult func bottom(px:Float) -> Self { YGNodeStyleSetPosition(node, .bottom, px); _usesTop = false; return self }
    @discardableResult func right(px:Float) -> Self { YGNodeStyleSetPosition(node, .right, px); _usesLeft = false; return self }
    
    @discardableResult func top(percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, .top, percent); _usesTop = true; return self }
    @discardableResult func left(percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, .left, percent); _usesLeft = true; return self }
    @discardableResult func bottom(percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, .bottom, percent); _usesTop = false; return self }
    @discardableResult func right(percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, .right, percent); _usesLeft = false; return self }
    
    @discardableResult func paddingAll(px:Float) -> Self { YGNodeStyleSetPadding(node, .all, px); return self }
    @discardableResult func paddingTop(px:Float) -> Self { YGNodeStyleSetPadding(node, .top, px); return self }
    @discardableResult func paddingLeft(px:Float) -> Self { YGNodeStyleSetPadding(node, .left, px); return self }
    @discardableResult func paddingBottom(px:Float) -> Self { YGNodeStyleSetPadding(node, .bottom, px); return self }
    @discardableResult func paddingRight(px:Float) -> Self { YGNodeStyleSetPadding(node, .right, px); return self }
    
    @discardableResult func paddingAll(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .all, percent); return self }
    @discardableResult func paddingTop(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .top, percent); return self }
    @discardableResult func paddingLeft(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .left, percent); return self }
    @discardableResult func paddingBottom(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .bottom, percent); return self }
    @discardableResult func paddingRight(percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, .right, percent); return self }
    
    @discardableResult func marginAll(px:Float) -> Self { YGNodeStyleSetMargin(node, .all, px); return self }
    @discardableResult func marginTop(px:Float) -> Self { YGNodeStyleSetMargin(node, .top, px); return self }
    @discardableResult func marginLeft(px:Float) -> Self { YGNodeStyleSetMargin(node, .left, px); return self }
    @discardableResult func marginBottom(px:Float) -> Self { YGNodeStyleSetMargin(node, .bottom, px); return self }
    @discardableResult func marginRight(px:Float) -> Self { YGNodeStyleSetMargin(node, .right, px); return self }
    
    @discardableResult func marginAll(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .all, percent); return self }
    @discardableResult func marginTop(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .top, percent); return self }
    @discardableResult func marginLeft(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .left, percent); return self }
    @discardableResult func marginBottom(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .bottom, percent); return self }
    @discardableResult func marginRight(percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, .right, percent); return self }
    
    
    // These are direct calls to the Yoga methods (most of which require parameters)
    
    @discardableResult func direction(_ v:YGDirection) -> Self { YGNodeStyleSetDirection(node, v); return self }
    @discardableResult func flexDirection(_ v:YGFlexDirection) -> Self { YGNodeStyleSetFlexDirection(node, v); return self }
    
    @discardableResult func justifyContent(_ v:YGJustify) -> Self { YGNodeStyleSetJustifyContent(node, v); return self }
    
    @discardableResult func alignContent(_ v:YGAlign) -> Self { YGNodeStyleSetAlignContent(node, v); return self }
    @discardableResult func alignItems(_ v:YGAlign) -> Self { YGNodeStyleSetAlignItems(node, v); return self }
    @discardableResult func alignSelf(_ v:YGAlign) -> Self { YGNodeStyleSetAlignSelf(node, v); return self }
    
    @discardableResult func positionType(_ v:YGPositionType) -> Self { YGNodeStyleSetPositionType(node, v); return self }
    
    @discardableResult func overflow(_ v:YGOverflow) -> Self { YGNodeStyleSetOverflow(node, v); return self }
    @discardableResult func display(_ v:YGDisplay) -> Self { YGNodeStyleSetDisplay(node, v); return self }
    
    @discardableResult func flexWrap(_ v:YGWrap) -> Self { YGNodeStyleSetFlexWrap(node, v); return self }
    @discardableResult func flex(_ v:Float) -> Self { YGNodeStyleSetFlex(node, v); return self }
    @discardableResult func flexGrow(_ v:Float) -> Self { YGNodeStyleSetFlexGrow(node, v); return self }
    @discardableResult func flexShrink(_ v:Float) -> Self { YGNodeStyleSetFlexShrink(node, v); return self }
    @discardableResult func flexAuto() -> Self { YGNodeStyleSetFlexBasisAuto(node); return self }
    
    @discardableResult func flexBasis(px:Float) -> Self { YGNodeStyleSetFlexBasis(node, px); return self }
    @discardableResult func flexBasis(percent:Float) -> Self { YGNodeStyleSetFlexBasisPercent(node, percent); return self }
    
    @discardableResult func position(edge:YGEdge, px:Float) -> Self { YGNodeStyleSetPosition(node, edge, px); return self }
    @discardableResult func position(edge:YGEdge, percent:Float) -> Self { YGNodeStyleSetPositionPercent(node, edge, percent); return self }
    
    @discardableResult func margin(edge:YGEdge, px:Float) -> Self { YGNodeStyleSetMargin(node, edge, px); return self }
    @discardableResult func margin(edge:YGEdge, percent:Float) -> Self { YGNodeStyleSetMarginPercent(node, edge, percent); return self }
    @discardableResult func marginAuto(v1:YGEdge) -> Self { YGNodeStyleSetMarginAuto(node, v1); return self }
    
    @discardableResult func padding(edge:YGEdge, px:Float) -> Self { YGNodeStyleSetPadding(node, edge, px); return self }
    @discardableResult func padding(edge:YGEdge, percent:Float) -> Self { YGNodeStyleSetPaddingPercent(node, edge, percent); return self }
    
    @discardableResult func border(v1:YGEdge, v2:Float) -> Self { YGNodeStyleSetBorder(node, v1, v2); return self }
    
    @discardableResult func width(px:Float) -> Self { YGNodeStyleSetWidth(node, px); return self }
    @discardableResult func width(percent:Float) -> Self { YGNodeStyleSetWidthPercent(node, percent); return self }
    @discardableResult func widthAuto() -> Self { YGNodeStyleSetWidthAuto(node); return self }
    
    @discardableResult func height(px:Float) -> Self { YGNodeStyleSetHeight(node, px); return self }
    @discardableResult func height(percent:Float) -> Self { YGNodeStyleSetHeightPercent(node, percent); return self }
    @discardableResult func heightAuto() -> Self { YGNodeStyleSetHeightAuto(node); return self }
    
    @discardableResult func minWidth(px:Float) -> Self { YGNodeStyleSetMinWidth(node, px); return self }
    @discardableResult func minWidth(percent:Float) -> Self { YGNodeStyleSetMinWidthPercent(node, percent); return self }
    
    @discardableResult func minHeight(px:Float) -> Self { YGNodeStyleSetMinHeight(node, px); return self }
    @discardableResult func minHeight(percent:Float) -> Self { YGNodeStyleSetMinHeightPercent(node, percent); return self }
    
    @discardableResult func maxWidth(px:Float) -> Self { YGNodeStyleSetMaxWidth(node, px); return self }
    @discardableResult func maxWidth(percent:Float) -> Self { YGNodeStyleSetMaxWidthPercent(node, percent); return self }
    
    @discardableResult func maxHeight(px:Float) -> Self { YGNodeStyleSetMaxHeight(node, px); return self }
    @discardableResult func maxHeight(percent:Float) -> Self { YGNodeStyleSetMaxHeightPercent(node, percent); return self }
    
    @discardableResult func aspectRatio(v:Float) -> Self { YGNodeStyleSetAspectRatio(node, v); return self }
    
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
