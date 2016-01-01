//
//  Shader.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

// FIXME: these are OpenGL 3 (desktop) shaders

let basic33VertexFunc =
"#version 330 core\n" +
"layout(location = 0) in vec3 position;\n" +
"layout(location = 1) in vec4 colour;\n" +
"smooth out vec4 vColour;\n" +
"uniform mat4 MVP;\n" +
"void main() {\n" +
"    vColour = colour;\n" +
"    gl_Position = MVP*vec4(position,1);\n" +
"}"

let basic33FragFunc =
"#version 330 core\n" +
"smooth in vec4 vColour;\n" +
"layout(location = 0) out vec4 vFragColor;\n" +
"void main() {\n" +
"    vFragColor = vColour;\n" +
"}"

extension String {
    subscript(range: Range<Int>) -> String {
        let start = startIndex.advancedBy(range.startIndex)
        let end = startIndex.advancedBy(range.endIndex)
        let range = Range<String.Index>(start: start, end: end)
        return substringWithRange(range)
    }
    
    init(block: (UnsafeMutablePointer<Int8>, Int) -> Void) {
        var result: String? = ""
        var info = [GLchar](count: 512, repeatedValue: 0)
        info.withUnsafeMutableBufferPointer({ (inout p: UnsafeMutableBufferPointer<Int8>) in
            block(p.baseAddress, 512-1)
            result = String.fromCString(p.baseAddress)
        })
        self = result!
    }
}

class Shader {
    
    let name: GLuint
    
    init(source: String, type: GLenum) {
        name = glCreateShader(type)
        source.withCString { (string: UnsafePointer<Int8>) in
            glShaderSource(name, 1, [string], [GLint(source.utf8.count)])
            glCompileShader(name)
            if !getCompileStatus() {
                print("Failed to compile shader \(source[0..<64]); error: \(getCompileInfo())")
            }
        }
    }
    
    func getCompileStatus() -> Bool {
        var result: GLint = 0
        glGetShaderiv(name, GLenum(GL_COMPILE_STATUS), &result)
        return result == GL_TRUE
    }
    
    func getCompileInfo() -> String? {
        return String(block: { (p: UnsafeMutablePointer<Int8>, length: Int) in
            var len = GLsizei(length)
            glGetShaderInfoLog(self.name, len, &len, p)
        })
    }
    
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


