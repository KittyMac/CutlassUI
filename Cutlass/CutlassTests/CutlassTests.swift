//
//  CutlassTests.swift
//  CutlassTests
//
//  Created by Rocco Bowling on 5/14/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import XCTest
@testable import Cutlass

class CutlassTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testYoga1() {
        let node = Yoga().size(1024,768).center().top(percent:10)
                         .view( Color() )
        node.layout()
        node.print()
    }

}
