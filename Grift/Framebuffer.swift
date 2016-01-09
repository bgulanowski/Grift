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
    var colorAttachments = [FramebufferAttachable?](count: 16, repeatedValue: nil)
    
    // TODO: depth and stencil attachments
    
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
    
    public func setColorAttachment(attachment: FramebufferAttachable?, atIndex index: Int) {
        let attachmentPoint = GLenum(GL_COLOR_ATTACHMENT0) + GLenum(index)
        bind(false)
        if attachment == nil {
            glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), attachmentPoint, GLenum(GL_RENDERBUFFER), GLuint(0))
        }
        else {
            attachment?.attachToFramebuffer(self, attachmentPoint: attachmentPoint)
        }
        colorAttachments[index] = attachment
    }
    
    public func colorAttachmentAtIndex(index: Int) -> FramebufferAttachable? {
        return colorAttachments[index]
    }
    
    public func bind() {
        bind(false)
    }
    
    public func bind(forReading: Bool) {
        glBindFramebuffer(GLenum(forReading ? GL_READ_FRAMEBUFFER : GL_DRAW_FRAMEBUFFER), name)
    }
}
