//
//  RenderUnit.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

// swiftlint:disable function_parameter_count

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
    private static let alignment: Int = Int(getpagesize())
    private static let floatSize: Int = MemoryLayout<Float>.size
    private var _rawpointer: UnsafeMutableRawPointer?
    private var _pointer: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: 0)
    private var _alloc: Int = 0
    private var _count: Int = 0
    private var _vertexCount: Int = 0
    private var _max: Int = 0

    static func alignedSize(_ size: Int) -> Int {
        let xxx = (size + FloatAlignedArray.alignment - 1)
        let yyy = (~(FloatAlignedArray.alignment - 1))
        return xxx & yyy
    }

    public func reserve(_ numFloats: Int) {
        if (numFloats * FloatAlignedArray.floatSize) > _max {
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

    public func pushQuadVC(_ mat: GLKMatrix4,
                           _ vx0: GLKVector3,
                           _ vx1: GLKVector3,
                           _ vx2: GLKVector3,
                           _ vx3: GLKVector3,
                           _ ccc: GLKVector4) {
        if _count + 42 >= _max {
            fatalError("FloatAlignedArray does not have enough allocated space for \(_count) floats (max of \(_max))")
        }

        let localPointer = _pointer + _count

        let mv0 = GLKMatrix4MultiplyVector3WithTranslation(mat, vx0)
        let mv1 = GLKMatrix4MultiplyVector3WithTranslation(mat, vx1)
        let mv2 = GLKMatrix4MultiplyVector3WithTranslation(mat, vx2)
        let mv3 = GLKMatrix4MultiplyVector3WithTranslation(mat, vx3)

        // TODO: early rejection of offscreen geometry
        localPointer[0] = mv0.x; localPointer[1] = mv0.y; localPointer[2] = mv0.z
        localPointer[3] = ccc.x; localPointer[4] = ccc.y; localPointer[5] = ccc.z; localPointer[6] = ccc.w

        localPointer[7] = mv1.x; localPointer[8] = mv1.y; localPointer[9] = mv1.z
        localPointer[10] = ccc.x; localPointer[11] = ccc.y; localPointer[12] = ccc.z; localPointer[13] = ccc.w

        localPointer[14] = mv2.x; localPointer[15] = mv2.y; localPointer[16] = mv2.z
        localPointer[17] = ccc.x; localPointer[18] = ccc.y; localPointer[19] = ccc.z; localPointer[20] = ccc.w

        localPointer[21] = mv2.x; localPointer[22] = mv2.y; localPointer[23] = mv2.z
        localPointer[24] = ccc.x; localPointer[25] = ccc.y; localPointer[26] = ccc.z; localPointer[27] = ccc.w

        localPointer[28] = mv3.x; localPointer[29] = mv3.y; localPointer[30] = mv3.z
        localPointer[31] = ccc.x; localPointer[32] = ccc.y; localPointer[33] = ccc.z; localPointer[34] = ccc.w

        localPointer[35] = mv0.x; localPointer[36] = mv0.y; localPointer[37] = mv0.z
        localPointer[38] = ccc.x; localPointer[39] = ccc.y; localPointer[40] = ccc.z; localPointer[41] = ccc.w

        _count += 42
        _vertexCount += 6
    }

    public func pushQuadVCT(_ mat: GLKMatrix4,
                            _ vx0: GLKVector3,
                            _ vx1: GLKVector3,
                            _ vx2: GLKVector3,
                            _ vx3: GLKVector3,
                            _ ccc: GLKVector4,
                            _ st0: GLKVector2,
                            _ st1: GLKVector2,
                            _ st2: GLKVector2,
                            _ st3: GLKVector2) {
        if _count + 54 >= _max {
            fatalError("FloatAlignedArray does not have enough allocated space for \(_count) floats (max of \(_max))")
        }

        let localPointer = _pointer + _count

        let mv0 = GLKMatrix4MultiplyVector3WithTranslation(mat, vx0)
        let mv1 = GLKMatrix4MultiplyVector3WithTranslation(mat, vx1)
        let mv2 = GLKMatrix4MultiplyVector3WithTranslation(mat, vx2)
        let mv3 = GLKMatrix4MultiplyVector3WithTranslation(mat, vx3)

        // TODO: early rejection of offscreen geometry
        localPointer[0] = mv0.x; localPointer[1] = mv0.y; localPointer[2] = mv0.z
        localPointer[3] = ccc.x; localPointer[4] = ccc.y; localPointer[5] = ccc.z; localPointer[6] = ccc.w
        localPointer[7] = st0.x; localPointer[8] = st0.y

        localPointer[9] = mv1.x; localPointer[10] = mv1.y; localPointer[11] = mv1.z
        localPointer[12] = ccc.x; localPointer[13] = ccc.y; localPointer[14] = ccc.z; localPointer[15] = ccc.w
        localPointer[16] = st1.x; localPointer[17] = st1.y

        localPointer[18] = mv2.x; localPointer[19] = mv2.y; localPointer[20] = mv2.z
        localPointer[21] = ccc.x; localPointer[22] = ccc.y; localPointer[23] = ccc.z; localPointer[24] = ccc.w
        localPointer[25] = st2.x; localPointer[26] = st2.y

        localPointer[27] = mv2.x; localPointer[28] = mv2.y; localPointer[29] = mv2.z
        localPointer[30] = ccc.x; localPointer[31] = ccc.y; localPointer[32] = ccc.z; localPointer[33] = ccc.w
        localPointer[34] = st2.x; localPointer[35] = st2.y

        localPointer[36] = mv3.x; localPointer[37] = mv3.y; localPointer[38] = mv3.z
        localPointer[39] = ccc.x; localPointer[40] = ccc.y; localPointer[41] = ccc.z; localPointer[42] = ccc.w
        localPointer[43] = st3.x; localPointer[44] = st3.y

        localPointer[45] = mv0.x; localPointer[46] = mv0.y; localPointer[47] = mv0.z
        localPointer[48] = ccc.x; localPointer[49] = ccc.y; localPointer[50] = ccc.z; localPointer[51] = ccc.w
        localPointer[52] = st0.x; localPointer[53] = st0.y

        _count += 54
        _vertexCount += 6
    }
}
