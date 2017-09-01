//
//  LogfileTests.swift
//  LogfileTests
//
//  Created by Bart van Kuik on 31/08/2017.
//  Copyright © 2017 DutchVirtual. All rights reserved.
//

import XCTest
@testable import Logfile

class LogfileTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testWrite() {
        let startsize = Logfile.size()
        Logfile.write(line: "test")
        let stopsize = Logfile.size()
        XCTAssert(stopsize > startsize, "After writing to logfile, size should've become bigger")
    }

    func testClear() {
        Logfile.write(line: "test")
        let size = Logfile.size()
        Logfile.clear()
        let newsize = Logfile.size()
        XCTAssert(newsize < size, "After clearing logfile, size should've become smaller")
        XCTAssert(newsize == 0, "After clearing logfile, size should've become zero")
    }

    func testRotate() {
        let teststr = "0123456789\n"
        var localsize: UInt64 = 0
        Logfile.clear()
        Logfile.maxLogSize = 100

        let nLoops = (Int(Logfile.maxLogSize) / teststr.characters.count) + 1
        (0 ..< nLoops).forEach { _ in
            localsize += UInt64(teststr.characters.count)
            let sizeBeforeRotate = Logfile.size()
            Logfile.write(line: teststr)

            if localsize > Logfile.maxLogSize {
                let sizeAfterRotate = Logfile.size()
                XCTAssert(sizeAfterRotate < sizeBeforeRotate, "After log rotation, the new size should be small")
            }
        }
    }

    func testGather() {
        let teststr = "0123456789\n"
        var localsize = 0
        Logfile.clear()
        Logfile.maxLogSize = 100

        let nLoops = (Int(Logfile.maxLogSize) / teststr.characters.count) + 1
        (0 ..< nLoops).forEach { _ in
            localsize += teststr.characters.count
            Logfile.write(line: teststr)
        }

        let result = Logfile.gather()
        XCTAssert(result.characters.count == localsize, "Gathered log doesn't have correct size")
    }
    
}
