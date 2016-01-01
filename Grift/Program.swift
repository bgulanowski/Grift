//
//  Program.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

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
        var res: GLint = 0
        glGetProgramiv(name, GLenum(GL_LINK_STATUS), &res)
        return res == GL_TRUE
    }
    
    func getLinkInfo() -> String {
        return String(block: { (p: UnsafeMutablePointer<Int8>, length: Int) in
            var len = GLsizei(length)
            glGetProgramInfoLog(self.name, len, &len, p)
        })
    }
    
    func use() {
        glUseProgram(name)
    }
    
    func enableBuffer<T>(buffer: Buffer<T>, name: String) {
        let location = locationOfAttribute(name)
        if location != Program.UnknownLocation {
            glEnableVertexAttribArray(GLuint(location))
            let normalize = name == "normal" ? GL_TRUE : GL_FALSE
            glVertexAttribPointer(GLuint(location), buffer.typeSize, buffer.glType, GLboolean(normalize), 0, UnsafePointer<Void>())
        }
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
