//
//  Texture.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES
import GLKit

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
    
    // TODO: inefficient; better to track dirty state, and update all dirty params at once in bind()
    public var minFilter: GLint {
        didSet {
            bind()
            setParameter(GL_TEXTURE_MIN_FILTER, value: minFilter)
        }
    }
    
    public var magFilter: GLint {
        didSet {
            bind()
            setParameter(GL_TEXTURE_MAG_FILTER, value: magFilter)
        }
    }
    
    public var wrapS: GLint {
        didSet {
            bind()
            setParameter(GL_TEXTURE_WRAP_S, value: wrapS)
        }
    }
    
    public var wrapT: GLint {
        didSet {
            bind()
            setParameter(GL_TEXTURE_WRAP_T, value: wrapT)
        }
    }

    public init(name: GLuint, size: CGSize, type: GLenum, format: GLenum) {
        self.name = name
        self.size = size
        self.type = type
        self.format = format
        minFilter = GL_NEAREST
        magFilter = GL_NEAREST
        wrapS = GL_CLAMP_TO_EDGE
        wrapT = GL_CLAMP_TO_EDGE
    }

    convenience public init(size: CGSize, type: GLenum, format: GLenum) {
        var name: GLuint = 0
        glGenTextures(1, &name)
        self.init(name: name, size: size, type: type, format: format)
    }
    
    // TODO: replace NSData with a Swift array
    convenience public init(size: CGSize, type: GLenum, format: GLenum, data: NSData?) {
        self.init(size: size, type: type, format: format)
        loadTexture(data)
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

    public convenience init(size: CGSize, data: NSData?) {
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
        // TODO: target should support texture rectangle on OS X
        glBindTexture(GLenum(GL_TEXTURE_2D), GLuint(name))
    }
    
    func submit(location: GLint) {
        // TODO: support other texture units
        glActiveTexture(GLenum(GL_TEXTURE0))
        bind()
        glUniform1i(location, GLint(0))
    }
    
    public func setParameter(parameter: GLint, value: GLint) {
        // TODO: target should support texture rectangle on OS X
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(parameter), value);
    }
    
    public func attachToFramebuffer(framebuffer: Framebuffer, attachmentPoint: GLenum) {
        // TODO: `target` (first arg) might need to support GL_READ_FRAMEBUFFER
        // TODO: `texTarget` (third arg) should be whatever was used to create bind/load the texture in createTexture()
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), attachmentPoint, GLenum(GL_TEXTURE_2D), name, 0)
    }
    
    func loadTexture(data: NSData?) {
        glBindTexture(GLenum(GL_TEXTURE_2D), name)
        let bytes: UnsafePointer<Void> = data != nil ? data!.bytes : UnsafePointer<Void>()
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(size.width), GLsizei(size.height), 0, format, type, bytes)
    }
    
    func generateMipmap() {
        glBindTexture(GLenum(GL_TEXTURE_2D), name)
        glGenerateMipmap(GLenum(GL_TEXTURE_2D))
    }
}

public extension Texture {
    public class func textureWithURL(url: NSURL) -> Texture? {
        var texture: Texture?
        do {
            let info = try GLKTextureLoader.textureWithContentsOfURL(url, options: nil)
            texture = Texture(name: info.name, size: CGSize(width: Int(info.width), height: Int(info.height)), type: GLenum(0), format: GLenum(0))
        }
        catch {
            // no idea what to do, don't really care
            texture = Texture(size: CGSize(width: 1.0, height: 1.0), color: UIColor.greenColor())
        }
        return texture
    }

    public class func textureWithName(name: String, filetype: String) -> Texture? {
        var texture: Texture?
        if let url = NSBundle.mainBundle().URLForResource(name, withExtension: filetype) {
            texture = textureWithURL(url)
        }
        return texture
    }
}