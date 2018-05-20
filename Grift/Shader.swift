//
//  Shader.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

let basic33VertexFunc =
"#version 300 es\n" +
"layout(location = 0) in vec3 position;\n" +
"layout(location = 1) in vec4 colour;\n" +
"layout(location = 2) in vec2 texCoord;\n" +
"uniform mat4 MVP;\n" +
"out vec4 vColour;\n" +
"out vec2 vtexCoord;\n" +
"void main() {\n" +
"  vColour = colour;\n" +
"  vtexCoord = texCoord;\n" +
"  gl_Position = MVP*vec4(position,1);\n" +
"}\n"

let basic33FragFunc =
"#version 300 es\n" +
"precision highp float;" +
"uniform bool useTex;\n" +
"uniform sampler2D sampler;\n" +
"in vec4 vColour;\n" +
"in vec2 vtexCoord;\n" +
"layout(location = 0) out vec4 vFragColor;\n" +
"void main() {\n" +
"  if (useTex) {\n" +
"    vFragColor = texture(sampler, vtexCoord);\n" +
"  } else {" +
"    vFragColor = vColour;\n" +
"  }\n" +
"}\n"

open class Shader {
    
    var name: GLuint
    
    public init(source: String, type: GLenum) {
        name = glCreateShader(type)
        source.withCString { (string: UnsafePointer<Int8>) in
            glShaderSource(name, 1, [string], [GLint(source.utf8.count)])
        }
        glCompileShader(name)
        if !getCompileStatus() {
            let typeName = type == GLenum(GL_VERTEX_SHADER) ? "vertex" : "fragment"
            print("Failed to compile \(typeName) shader; \nError: '\(getCompileInfo())'")
        }
    }
    
    deinit {
        if name > 0 {
            delete()
        }
    }
    
    func delete() {
        glDeleteShader(name)
        name = 0
    }
    
    // MARK: OpenGL/ES state queries
    
    func getCompileStatus() -> Bool {
        return getShaderProperty(GLenum(GL_COMPILE_STATUS)) == GL_TRUE
    }
    
    func getCompileInfo() -> String {
        let logLength = getCompileInfoLength()
        return String(length: Int(logLength), unsafeMutableBufferPointer: { (p: UnsafeMutableBufferPointer<Int8>) -> Void in
            glGetShaderInfoLog(self.name, GLsizei(logLength), nil, p.baseAddress)
        })
    }
    
    func getCompileInfoLength() -> GLint {
        return getShaderProperty(GLenum(GL_INFO_LOG_LENGTH))
    }
    
    func getShaderProperty(_ property: GLenum) -> GLint {
        var value: GLint = 0
        glGetShaderiv(name, property, &value)
        return value
    }
    
    // MARK: convenience factories
    
    open class func newVertexShaderWithName(_ name: String) -> Shader? {
        return newShaderWithName(name, type: GLenum(GL_VERTEX_SHADER))
    }
    
    open class func newFragmentShaderWithName(_ name: String) -> Shader? {
        return newShaderWithName(name, type: GLenum(GL_FRAGMENT_SHADER))
    }
    
    open class func newShaderWithName(_ name: String, type: GLenum) -> Shader? {
        if let url = Bundle.main.url(forResource: name, withExtension: type == GLenum(GL_VERTEX_SHADER) ? "vp" : "fp") {
            return newShaderWithURL(url, type: type)
        }
        else {
            return nil
        }
    }
    
    open class func newShaderWithURL(_ url: URL, type: GLenum) -> Shader? {
        do {
            let source = try String(contentsOf: url)
            return Shader(source: source, type: type)
        }
        catch {
            return nil
        }
    }
    
    open class func newVertexShader(_ source: String) -> Shader {
        return Shader(source: source, type: GLenum(GL_VERTEX_SHADER))
    }
    
    open class func newFragmentShader(_ source: String) -> Shader {
        return Shader(source: source, type: GLenum(GL_FRAGMENT_SHADER))
    }
    
    open class func basic300VertexShader() -> Shader {
        return Shader(source: basic33VertexFunc, type: GLenum(GL_VERTEX_SHADER))
    }
    
    open class func basic300FragmentShader() -> Shader {
        return Shader(source: basic33FragFunc, type: GLenum(GL_FRAGMENT_SHADER))
    }
}

// MARK: - String Support

extension String {
    subscript(range: Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: range.lowerBound)
        let end = characters.index(startIndex, offsetBy: range.upperBound)
        let range = (start ..< end)
        return substring(with: range)
    }
    
    init(length: Int, unsafeMutableBufferPointer: (UnsafeMutableBufferPointer<Int8>) -> Void) {
        var result: String? = nil
        var info = [Int8](repeating: 0, count: length+1)
        info.withUnsafeMutableBufferPointer({ (p: inout UnsafeMutableBufferPointer<Int8>) in
            unsafeMutableBufferPointer(p)
            result = String(cString: p.baseAddress!)
        })
        self = result == nil ? "" : result!
    }
}
