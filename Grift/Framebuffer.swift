//
//  Framebuffer.swift
//  Grift
//
//  Created by Brent Gulanowski on 2016-01-01.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

public class Framebuffer {
    
    var name: GLuint = 0
    
    public init() {
        glGenFramebuffers(1, &name)
    }
    
    deinit {
        if name > 0 {
            delete()
        }
    }
    
    func delete() {
        glDeleteFramebuffers(1, &name)
        name = 0
    }
    
    public func bind() {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), name)
    }
}
