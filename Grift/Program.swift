//
//  Program.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

public struct Variable {
    let name: String
    let type: GLenum
    let size: GLint
    let location: GLuint
}

typealias GetActiveVariableFunc = (GLuint, GLuint, GLsizei, UnsafeMutablePointer<GLsizei>, UnsafeMutablePointer<GLint>, UnsafeMutablePointer<GLenum>, UnsafeMutablePointer<GLchar>) -> Void
typealias GetVariableLocationFunc = (GLuint, UnsafePointer<GLchar>) -> GLint

public class Program {
    
    static let UnknownLocation = GLint(-1)
    
    var name: GLuint = 0
    var uniforms = [String:Variable]()
    var attribs = [String:Variable]()
    let shaders: [Shader]
    
    public init(shaders: [Shader]) {
        name = glCreateProgram()
        for shader in shaders {
            glAttachShader(name, shader.name)
        }
        self.shaders = shaders
        glLinkProgram(name)
        if !getLinkStatus() {
            print("Failed to link program; error: '\(getLinkInfo())'")
        }
        for uniform in getActiveUniforms() {
            uniforms[uniform.name] = uniform
        }
        for attrib in getActiveAttributes() {
            attribs[attrib.name] = attrib
        }
    }
    
    deinit {
        if name > 0 {
            delete()
        }
    }
    
    public convenience init() {
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
        self.init(shaders: [vertFunc, fragFunc])
    }
    
    public class func newProgramWithName(name: String) -> Program? {
        if let vShader = Shader.newVertexShaderWithName(name), fShader = Shader.newFragmentShaderWithName(name) {
            return Program(shaders: [vShader, fShader])
        }
        else {
            return nil
        }
    }
    
    func delete() {
        glDeleteProgram(name)
        name = 0
    }
    
    public func use() {
        glUseProgram(name)
    }
    
    public func submitBuffer<T>(buffer: Buffer<T>, name: String) {
        if let location = attribs[name]?.location {
            glEnableVertexAttribArray(location)
            buffer.submit(GLuint(location))
        }
    }
    
    public func submitTexture(texture: Texture, uniformName: String) {
        let location = getLocationOfUniform(uniformName)
        if location != Program.UnknownLocation {
            glActiveTexture(GLenum(0))
            texture.bind()
            glUniform1i(location, GLint(0))
        }
    }
    
    // MARK: OpenGL/ES state queries
    
    public func activeAttributeNames() -> [String] {
        return [String](attribs.keys)
    }
    
    public func activeUniformNames() -> [String] {
        return [String](uniforms.keys)
    }
    
    public func getActiveAttributes() -> [Variable] {
        let maxLength = getMaxAttributeNameLength()
        var attributes = [Variable]()
        for i in 0 ..< Int(getNumberOfActiveAttributes()) {
            if let attribute = getActiveAttributeAtIndex(GLuint(i), maxLength: maxLength) {
                attributes.append(attribute)
            }
        }
        return attributes
    }
    
    public func getActiveUniforms() -> [Variable] {
        let maxLength = getMaxUniformNameLength()
        var uniforms = [Variable]()
        for i in 0 ..< Int(getNumberOfActiveUniforms()) {
            if let uniform = getActiveUniformAtIndex(GLuint(i), maxLength: maxLength) {
                uniforms.append(uniform)
            }
        }
        return uniforms
    }
    
    func getActiveAttributeAtIndex(index: GLuint, maxLength: GLint) -> Variable? {
        return getActiveVariableAtIndex(index, maxLength: maxLength, getVariable: glGetActiveAttrib, getLocation: glGetAttribLocation)
    }
    
    func getActiveUniformAtIndex(index: GLuint, maxLength: GLint) -> Variable? {
        return getActiveVariableAtIndex(index, maxLength: maxLength, getVariable: glGetActiveUniform, getLocation: glGetUniformLocation)
    }
    
    func getActiveVariableAtIndex(index: GLuint, maxLength: GLint, getVariable: GetActiveVariableFunc, getLocation: GetVariableLocationFunc) -> Variable? {
        var size: GLint = 0
        var type: GLenum = 0
        let variableName = String(length: Int(maxLength), unsafeMutableBufferPointer: { (p: UnsafeMutableBufferPointer<Int8>) in
            getVariable(self.name, index, maxLength, nil, &size, &type, p.baseAddress)
        })
        let location = getVariableLocation(variableName, getLocation: getLocation)
        return location == Program.UnknownLocation ? nil : Variable(name: variableName, type: type, size: size, location: GLuint(location))
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
        return getVariableLocation(attribute, getLocation: glGetAttribLocation)
    }
    
    func getLocationOfUniform(uniform: String) -> GLint {
        return getVariableLocation(uniform, getLocation: glGetUniformLocation)
    }
    
    func getVariableLocation(variable: String, getLocation: GetVariableLocationFunc) -> GLint {
        var result: GLint = 0
        variable.withCString { (p: UnsafePointer<Int8>) in
            result = getLocation(self.name, p)
        }
        return result
    }
}
