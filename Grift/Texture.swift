//
//  Texture.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

typealias BOOL = Bool

extension Int {
    public func isPowerOf2() -> Bool {
        var i = 1
        while i < self {
            i <<= 1
        }
        return i == self
    }
}

extension CGSize {
    public func isPowerOf2() -> Bool {
        return Int(width).isPowerOf2() && Int(height).isPowerOf2()
    }
}

public struct Colorf {
    let r: GLfloat
    let g: GLfloat
    let b: GLfloat
    let a: GLfloat
    
    public init(color: UIColor) {
        var r_: CGFloat = 0.0
        var g_: CGFloat = 0.0
        var b_: CGFloat = 0.0
        var a_: CGFloat = 0.0
        UIColor.redColor().getRed(&r_, green: &g_, blue: &b_, alpha: &a_)
        (r, g, b, a) = (GLfloat(r_), GLfloat(g_), GLfloat(b_), GLfloat(a_))
    }
}

public class Texture : Bindable, FramebufferAttachable {
    
    let size: CGSize
    let type: GLenum
    let format: GLenum
    var name: GLuint = 0
    
    public init(size: CGSize, type: GLenum, format: GLenum, data: NSData) {
        self.size = size
        self.type = type
        self.format = format
        createTexture(data)
    }
    
    deinit {
        if name > 0 {
            delete()
        }
    }
    
    func delete() {
        glDeleteTextures(1, &name)
        name = 0
    }

    public convenience init(size: CGSize, data: NSData) {
        self.init(size: size, type: GLenum(GL_UNSIGNED_BYTE), format: GLenum(GL_RGBA), data: data)
    }
    
    public convenience init(size: CGSize, color: UIColor) {
        let count = size_t(size.width) * size_t(size.height)
        let colors = [Colorf](count: count, repeatedValue: Colorf(color: color))
        var data: NSData!
        colors.withUnsafeBufferPointer { (p: UnsafeBufferPointer<Colorf>) in
            data = NSData(bytes: p.baseAddress, length: p.count * sizeof(Colorf))
        }
        self.init(size: size, data: data)
    }
    
    func bind() {
        glBindTexture(GLenum(GL_TEXTURE_2D), GLuint(name))
    }
    
    public func attachToFramebuffer(framebuffer: Framebuffer, attachmentPoint: GLenum) {
        // TODO: `target` (first arg) might need to support GL_READ_FRAMEBUFFER
        // TODO: `texTarget` (third arg) should be whatever was used to create bind/load the texture in createTexture()
        glFramebufferTexture2D(GLenum(GL_DRAW_FRAMEBUFFER), attachmentPoint, GLenum(GL_TEXTURE_2D), name, 0)
    }
    
    func createTexture(data: NSData) {
        glGenTextures(1, &name)
        glBindTexture(GLenum(GL_TEXTURE_2D), name)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(size.width), GLsizei(size.height), 0, format, type, data.bytes)
        glGenerateMipmap(GLenum(GL_TEXTURE_2D))
    }
}
