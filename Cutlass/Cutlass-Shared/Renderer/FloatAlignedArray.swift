//
//  RenderUnit.swift
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

public class FloatAlignedArray {
    /*
    For generating geometry for use with Metal. These structs point to memory allocated using
    posix_memalign() and can be fed directly into metal buffers without copying.
    */
    static let alignment:Int = Int(getpagesize())
    static let floatSize:Int = MemoryLayout<Float>.size
    var _rawpointer:UnsafeMutableRawPointer? = nil
    var _pointer:UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: 0)
    var _alloc:Int = 0
    var _count:Int = 0
    var _vertexCount:Int = 0
    var _max:Int = 0
    
    static func alignedSize(_ size:Int) -> Int {
        let x = (size + FloatAlignedArray.alignment - 1)
        let y = (~(FloatAlignedArray.alignment - 1))
        return x & y
    }
    
    public func reserve(_ numFloats:Int) {
        if _max != numFloats {
            if _rawpointer != nil {
                dealloc()
            }
            _alloc = FloatAlignedArray.alignedSize(numFloats * FloatAlignedArray.floatSize)
            _count = 0
            _max = _alloc / FloatAlignedArray.floatSize
            
            let ret = posix_memalign(&_rawpointer, FloatAlignedArray.alignment, _alloc)
            if ret != noErr {
                let err = String(validatingUTF8: strerror(ret)) ?? "unknown error"
                fatalError("Unable to allocate aligned memory: \(err).")
            }
            
            _pointer = UnsafeMutablePointer<Float>(OpaquePointer(_rawpointer!))
        }
    }
    
    public func dealloc() {
        free(_pointer)
        _rawpointer = nil
    }
    
    public func clear() {
        _count = 0
        _vertexCount = 0
    }
    
    public func count() -> Int {
        return _count
    }
    
    public func vertexCount() -> Int {
        return _vertexCount
    }
    
    public func bytesCount() -> Int {
        return _count * FloatAlignedArray.floatSize
    }
    
    public func bytes() -> UnsafeMutableRawPointer? {
        return _rawpointer
    }
    
    public func pushQuadVC(_ v0:GLKVector3, _ v1:GLKVector3, _ v2:GLKVector3, _ v3:GLKVector3, _ c:GLKVector4) {
        if _count + 42 >= _max {
            fatalError("FloatAlignedArray does not have enough allocated space for \(_count) floats (max of \(_max))")
        }

        let local_pointer = _pointer + _count
        
        local_pointer[0] = v0.x; local_pointer[1] = v0.y; local_pointer[2] = v0.z
        local_pointer[3] = c.x; local_pointer[4] = c.y; local_pointer[5] = c.z; local_pointer[6] = c.w

        local_pointer[7] = v1.x; local_pointer[8] = v1.y; local_pointer[9] = v1.z
        local_pointer[10] = c.x; local_pointer[11] = c.y; local_pointer[12] = c.z; local_pointer[13] = c.w

        local_pointer[14] = v2.x; local_pointer[15] = v2.y; local_pointer[16] = v2.z
        local_pointer[17] = c.x; local_pointer[18] = c.y; local_pointer[19] = c.z; local_pointer[20] = c.w

        local_pointer[21] = v2.x; local_pointer[22] = v2.y; local_pointer[23] = v2.z
        local_pointer[24] = c.x; local_pointer[25] = c.y; local_pointer[26] = c.z; local_pointer[27] = c.w

        local_pointer[28] = v3.x; local_pointer[29] = v3.y; local_pointer[30] = v3.z
        local_pointer[31] = c.x; local_pointer[32] = c.y; local_pointer[33] = c.z; local_pointer[34] = c.w

        local_pointer[35] = v0.x; local_pointer[36] = v0.y; local_pointer[37] = v0.z
        local_pointer[38] = c.x; local_pointer[39] = c.y; local_pointer[40] = c.z; local_pointer[41] = c.w
        
        _count += 42
        _vertexCount += 6
    }
}
