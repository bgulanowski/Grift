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

public class Shader {
    
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
    
    func getShaderProperty(property: GLenum) -> GLint {
        var value: GLint = 0
        glGetShaderiv(name, property, &value)
        return value
    }
    
    // MARK: convenience factories
    
    public class func newVertexShaderWithName(name: String) -> Shader? {
        return newShaderWithName(name, type: GLenum(GL_VERTEX_SHADER))
    }
    
    public class func newFragmentShaderWithName(name: String) -> Shader? {
        return newShaderWithName(name, type: GLenum(GL_FRAGMENT_SHADER))
    }
    
    public class func newShaderWithName(name: String, type: GLenum) -> Shader? {
        if let url = NSBundle.mainBundle().URLForResource(name, withExtension: type == GLenum(GL_VERTEX_SHADER) ? "vp" : "fp") {
            return newShaderWithURL(url, type: type)
        }
        else {
            return nil
        }
    }
    
    public class func newShaderWithURL(url: NSURL, type: GLenum) -> Shader? {
        do {
            let source = try String(contentsOfURL: url)
            return Shader(source: source, type: type)
        }
        catch {
            return nil
        }
    }
    
    public class func newVertexShader(source: String) -> Shader {
        return Shader(source: source, type: GLenum(GL_VERTEX_SHADER))
    }
    
    public class func newFragmentShader(source: String) -> Shader {
        return Shader(source: source, type: GLenum(GL_FRAGMENT_SHADER))
    }
    
    public class func basic300VertexShader() -> Shader {
        return Shader(source: basic33VertexFunc, type: GLenum(GL_VERTEX_SHADER))
    }
    
    public class func basic300FragmentShader() -> Shader {
        return Shader(source: basic33FragFunc, type: GLenum(GL_FRAGMENT_SHADER))
    }
}

// MARK: - String Support

extension String {
    subscript(range: Range<Int>) -> String {
        let start = startIndex.advancedBy(range.startIndex)
        let end = startIndex.advancedBy(range.endIndex)
        let range = Range<String.Index>(start: start, end: end)
        return substringWithRange(range)
    }
    
    init(length: Int, unsafeMutableBufferPointer: (UnsafeMutableBufferPointer<Int8>) -> Void) {
        var result: String? = nil
        var info = [Int8](count: length+1, repeatedValue: 0)
        info.withUnsafeMutableBufferPointer({ (inout p: UnsafeMutableBufferPointer<Int8>) in
            unsafeMutableBufferPointer(p)
            result = String.fromCString(p.baseAddress)
        })
        self = result == nil ? "" : result!
    }
}
