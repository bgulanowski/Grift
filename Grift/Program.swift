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
            print("[Grift] Only OpenGLES3 is supported. Please create a GLES3 rendering context.")
        }
        self.init(vShader: vertFunc, fShader: fragFunc)
    }
    
    func use() {
        glUseProgram(name)
    }
    
    func enableBuffer<T>(buffer: Buffer<T>, name: String) {
        let location = getLocationOfAttribute(name)
        if location != Program.UnknownLocation {
            glEnableVertexAttribArray(GLuint(location))
            let normalize = name == "normal" ? GL_TRUE : GL_FALSE
            glVertexAttribPointer(GLuint(location), buffer.typeSize, buffer.glType, GLboolean(normalize), 0, UnsafePointer<Void>())
        }
    }
    
    // MARK: OpenGL/ES state queries
    
    func getActiveUniformNames() -> [String] {
        return getActiveUniforms().map { (uniform: Uniform) in
            return uniform.name
        }
    }
    
    func getActiveUniforms() -> [Uniform] {
        let maxLength = getMaxUniformNameLength()
        var uniforms = [Uniform]()
        for i in 0 ..< Int(getNumberOfActiveUniforms()) {
            uniforms.append(getActiveUniformAtIndex(GLuint(i), maxLength: maxLength))
        }
        return uniforms
    }
    
    func getActiveUniformAtIndex(index: GLuint, maxLength: GLint) -> Uniform {
        var size: GLint = 0
        var type: GLenum = 0
        let uniformName = String(length: Int(maxLength), unsafeMutableBufferPointer: { (p: UnsafeMutableBufferPointer<Int8>) in
            glGetActiveUniform(self.name, index, maxLength, nil, &size, &type, p.baseAddress)
            })
        return Uniform(name: uniformName, type: type, size: size, location: getLocationOfUniform(uniformName))
    }
    
    func getLinkInfo() -> String {
        let length = getLinkInfoLength()
        return String(length: Int(length), unsafeMutableBufferPointer: { (p: UnsafeMutableBufferPointer<Int8>) -> Void in
            var len = GLsizei(length)
            glGetProgramInfoLog(self.name, len, &len, p.baseAddress)
        })
    }

    func getLinkStatus() -> Bool {
        return getProgramValue(GLenum(GL_LINK_STATUS)) == GL_TRUE
    }
    
    func getLinkInfoLength() -> GLint {
        return getProgramValue(GLenum(GL_INFO_LOG_LENGTH))
    }

    func getNumberOfActiveUniforms() -> GLint {
        return getProgramValue(GLenum(GL_ACTIVE_UNIFORMS))
    }
    
    func getNumberOfActiveAttributes() -> GLint {
        return getProgramValue(GLenum(GL_ACTIVE_ATTRIBUTES))
    }
    
    func getMaxUniformNameLength() -> GLint {
        return getProgramValue(GLenum(GL_ACTIVE_UNIFORM_MAX_LENGTH))
    }
    
    func getMaxAttributeNameLength() -> GLint {
        return getProgramValue(GLenum(GL_ACTIVE_ATTRIBUTE_MAX_LENGTH))
    }
    
    func getProgramValue(value: GLenum) -> GLint {
        var result: GLint = 0
        glGetProgramiv(name, value, &result )
        return result
    }
    
    func getLocationsForAttributes(attributes: [String]) -> [String:GLint] {
        return getLocationsForStrings(attributes, function: getLocationOfAttribute)
    }
    
    func getLocationsForUniforms(uniforms: [String]) -> [String:GLint] {
        return getLocationsForStrings(uniforms, function: getLocationOfUniform)
    }
    
    func getLocationsForStrings(strings: [String], function: (String) -> GLint) -> [String:GLint] {
        var results = [String:GLint]()
        for attribute in strings {
            results[attribute] = function(attribute)
        }
        return results
    }
    
    func getLocationOfAttribute(attribute: String) -> GLint {
        return getLocationForString(attribute, block: { (p: UnsafePointer<Int8>) in
            return glGetAttribLocation(self.name, p)
        })
    }
    
    func getLocationOfUniform(uniform: String) -> GLint {
        return getLocationForString(uniform, block: { (p: UnsafePointer<Int8>) in
            return glGetUniformLocation(self.name, p)
        })
    }
    
    func getLocationForString(string: String, block: (UnsafePointer<Int8>) -> GLint ) -> GLint {
        var result: GLint = 0
        string.withCString { (p: UnsafePointer<Int8>) in
            result = block(p)
        }
        return result
    }
}
