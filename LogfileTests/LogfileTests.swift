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
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
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
    
}
