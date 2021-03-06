//
//  Renderbuffer.swift
//  Grift
//
//  Created by Brent Gulanowski on 2016-01-03.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

public class Renderbuffer : Bindable, FramebufferAttachable {
    
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
        glDeleteRenderbuffers(1, &name)
    }
    
    func bind() {
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), name)
    }
    
    
    
    public func attachToFramebuffer(framebuffer: Framebuffer, attachmentPoint: GLenum) {
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), attachmentPoint, GLenum(GL_RENDERBUFFER), name)
    }
}

public extension EAGLContext {
    func renderbufferStorage(renderbuffer: Renderbuffer, fromDrawable: EAGLDrawable!) {
        renderbuffer.bind()
        self.renderbufferStorage(Int(GL_RENDERBUFFER), fromDrawable: fromDrawable)
    }
}