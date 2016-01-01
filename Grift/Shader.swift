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
"#version 300 es\n\n" +
"layout(location = 0) in vec3 position;\n" +
"layout(location = 1) in vec4 colour;\n" +
"out vec4 vColour;\n" +
"uniform mat4 MVP;\n" +
"void main() {\n" +
"    vColour = colour;\n" +
"    gl_Position = MVP*vec4(position,1);\n" +
"}\n"

let basic33FragFunc =
"#version 300 es\n\n" +
"precision highp float;" +
"in vec4 vColour;\n" +
"layout(location = 0) out vec4 vFragColor;\n" +
"void main() {\n" +
"    vFragColor = vColour;\n" +
"}\n"

class Shader {
    
    let name: GLuint
    
    init(source: String, type: GLenum) {
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
    
    class func newVertexShader(source: String) -> Shader {
        return Shader(source: source, type: GLenum(GL_VERTEX_SHADER))
    }
    
    class func newFragmentShader(source: String) -> Shader {
        return Shader(source: source, type: GLenum(GL_FRAGMENT_SHADER))
    }
    
    class func basic33VertexShader() -> Shader {
        return Shader(source: basic33VertexFunc, type: GLenum(GL_VERTEX_SHADER))
    }
    
    class func basic33FragmentShader() -> Shader {
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
