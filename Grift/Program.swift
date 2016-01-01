//
//  Program.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

struct Uniform {
    let name: String
    let type: GLenum
    let size: GLint
    let location: GLint
}

class Program {
    
    static let UnknownLocation = GLint(-1)
    
    let name: GLuint
    
    init(vShader: Shader, fShader: Shader) {
        name = glCreateProgram()
        glAttachShader(name, vShader.name)
        glAttachShader(name, fShader.name)
        glLinkProgram(name)
    }
    
    convenience init() {
        var vertFunc: Shader!
        var fragFunc: Shader!
        if EAGLContext.currentContext().API == .OpenGLES3 {
            vertFunc = Shader.basic33VertexShader()
            fragFunc = Shader.basic33FragmentShader()
        }
        else {
            // TODO: support legacy
        }
        self.init(vShader: vertFunc, fShader: fragFunc)
    }
    
    func checkLinkStatus() -> Bool {
        return getProgramValue(GLenum(GL_LINK_STATUS)) == GL_TRUE
    }
    
    func getLinkInfo() -> String {
        let length = getLinkInfoLength()
        return String(length: Int(length), unsafeMutableBufferPointer: { (p: UnsafeMutableBufferPointer<Int8>) -> Void in
            var len = GLsizei(length)
            glGetProgramInfoLog(self.name, len, &len, p.baseAddress)
        })
    }
    
    func use() {
        glUseProgram(name)
    }
    
    func getLinkInfoLength() -> GLint {
        return getProgramValue(GLenum(GL_INFO_LOG_LENGTH))
    }
    
    func getActiveUniforms() -> [Uniform] {
        let maxLength = maxUniformNameLength()
        var uniforms = [Uniform]()
        for i in 0 ..< Int(numberOfActiveUniforms()) {
            uniforms.append(getActiveUniformAtIndex(GLuint(i), maxLength: maxLength))
        }
        return uniforms
    }
    
    func getActiveUniformAtIndex(index: GLuint, maxLength: GLint) -> Uniform {
        var size: GLint = 0
        var type: GLenum = 0
        let uniformName = String(length: Int(maxLength), unsafeMutableBufferPointer: { (p: UnsafeMutableBufferPointer<Int8>) in
            var length: GLsizei = 0
            glGetActiveUniform(self.name, index, maxLength, &length, &size, &type, p.baseAddress)
            })
        return Uniform(name: uniformName, type: type, size: size, location: locationOfUniform(uniformName))
    }
    
    func enableBuffer<T>(buffer: Buffer<T>, name: String) {
        let location = locationOfAttribute(name)
        if location != Program.UnknownLocation {
            glEnableVertexAttribArray(GLuint(location))
            let normalize = name == "normal" ? GL_TRUE : GL_FALSE
            glVertexAttribPointer(GLuint(location), buffer.typeSize, buffer.glType, GLboolean(normalize), 0, UnsafePointer<Void>())
        }
    }
    
    func numberOfActiveUniforms() -> GLint {
        return getProgramValue(GLenum(GL_ACTIVE_UNIFORMS))
    }
    
    func numberOfActiveAttributes() -> GLint {
        return getProgramValue(GLenum(GL_ACTIVE_ATTRIBUTES))
    }
    
    func maxUniformNameLength() -> GLint {
        return getProgramValue(GLenum(GL_ACTIVE_UNIFORM_MAX_LENGTH))
    }
    
    func maxAttributeNameLength() -> GLint {
        return getProgramValue(GLenum(GL_ACTIVE_ATTRIBUTE_MAX_LENGTH))
    }
    
    func getProgramValue(value: GLenum) -> GLint {
        var result: GLint = 0
        glGetProgramiv(name, value, &result )
        return result
    }
    
    func locationsForAttributes(attributes: [String]) -> [String:GLint] {
        return locationsForStrings(attributes, function: locationOfAttribute)
    }
    
    func locationsForUniforms(uniforms: [String]) -> [String:GLint] {
        return locationsForStrings(uniforms, function: locationOfUniform)
    }
    
    func locationsForStrings(strings: [String], function: (String) -> GLint) -> [String:GLint] {
        var results = [String:GLint]()
        for attribute in strings {
            results[attribute] = function(attribute)
        }
        return results
    }
    
    func locationOfAttribute(attribute: String) -> GLint {
        return locationForString(attribute, block: { (p: UnsafePointer<Int8>) in
            return glGetAttribLocation(self.name, p)
        })
    }
    
    func locationOfUniform(uniform: String) -> GLint {
        return locationForString(uniform, block: { (p: UnsafePointer<Int8>) in
            return glGetUniformLocation(self.name, p)
        })
    }
    
    func locationForString(string: String, block: (UnsafePointer<Int8>) -> GLint ) -> GLint {
        var result: GLint = 0
        string.withCString { (p: UnsafePointer<Int8>) in
            result = block(p)
        }
        return result
    }
}
