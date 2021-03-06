//
//  GriftTests.swift
//  GriftTests
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import XCTest
@testable import Grift

class GriftTests: XCTestCase {

    var context: EAGLContext!
    var layer: CAEAGLLayer!
    
    override func setUp() {
        super.setUp()
        var once: dispatch_once_t = 0
        dispatch_once(&once) { () -> Void in
            self.context = EAGLContext(API: .OpenGLES3)
            self.layer = CAEAGLLayer()
            UIApplication.sharedApplication().keyWindow?.layer.addSublayer(self.layer)
            self.context.renderbufferStorage(Int(GL_RENDERBUFFER), fromDrawable: self.layer)
        }
    }
    
    //    override func tearDown() {
    //        // Put teardown code here. This method is called after the invocation of each test method in the class.
    //        super.tearDown()
    //    }
    
    func test() {
        EAGLContext.setCurrentContext(context)
        let program = Program()
        XCTAssertNotEqual(GLint(program.name), Program.UnknownLocation)
    }
}
