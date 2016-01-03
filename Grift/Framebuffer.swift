//
//  Framebuffer.swift
//  Grift
//
//  Created by Brent Gulanowski on 2016-01-01.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

public protocol FramebufferAttachable {
    func attachToFramebuffer(framebuffer: Framebuffer, attachmentPoint: GLenum) -> Void
}

public class Framebuffer : Bindable {
    
    var name: GLuint = 0
    public var colorAttachment0: FramebufferAttachable? {
        didSet {
            bind()
            if colorAttachment0 == nil {
                glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), GLuint(0))
            }
            else {
                colorAttachment0!.attachToFramebuffer(self, attachmentPoint: GLenum(GL_COLOR_ATTACHMENT0))
            }
        }
    }
    
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
