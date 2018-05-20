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
    let location: GLint
}

// MARK: - uniform submission generic support

public protocol ProgramSubmissible {
    static func submit1Func() -> (GLint, Self) -> Void
    static func submit1VFunc() -> (GLint, GLsizei, UnsafePointer<Self>) -> Void
}

extension ProgramSubmissible {
    func submit(_ location: GLint) {
        Self.submit1Func()(location, self)
    }
    static func submitArray(_ array: [Self], location: GLint) {
        Self.submit1VFunc()(location, GLsizei(array.count), array)
    }
}

extension Array where Element : ProgramSubmissible {
    func submit(_ location: GLint) {
        Element.submitArray(self, location: location)
    }
}

// TODO: support for glUniform{2|3|4}{f|i|ui}(v)

extension GLint : ProgramSubmissible {
    public static func submit1Func() -> (GLint, GLint) -> Void {
        return glUniform1i
    }
   public  static func submit1VFunc() -> (GLint, GLsizei, UnsafePointer<GLint>) -> Void {
        return glUniform1iv
    }
}

extension GLuint : ProgramSubmissible {
    public static func submit1Func() -> (GLint, GLuint) -> Void {
        return glUniform1ui
    }
    public static func submit1VFunc() -> (GLint, GLsizei, UnsafePointer<GLuint>) -> Void {
        return glUniform1uiv
    }
}

extension GLfloat : ProgramSubmissible {
    public static func submit1Func() -> (GLint, GLfloat) -> Void {
        return glUniform1f
    }
    public static func submit1VFunc() -> (GLint, GLsizei, UnsafePointer<GLfloat>) -> Void {
        return glUniform1fv
    }
}



// MARK: -

typealias GetActiveVariableFunc = (GLuint, GLuint, GLsizei, UnsafeMutablePointer<GLsizei>?, UnsafeMutablePointer<GLint>, UnsafeMutablePointer<GLenum>, UnsafeMutablePointer<GLchar>) -> Void
typealias GetVariableLocationFunc = (GLuint, UnsafePointer<GLchar>) -> GLint

open class Program {
    
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
        if EAGLContext.current().api == .openGLES3 {
            vertFunc = Shader.basic300VertexShader()
            fragFunc = Shader.basic300FragmentShader()
        }
        else {
            // TODO: support legacy
            print("[Grift] Only OpenGLES3 is supported. Please create a GLES3 rendering context.")
        }
        self.init(shaders: [vertFunc, fragFunc])
    }
    
    open class func newProgramWithName(_ name: String) -> Program? {
        if let vShader = Shader.newVertexShaderWithName(name), let fShader = Shader.newFragmentShaderWithName(name) {
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
    
    open func use() {
        glUseProgram(name)
    }
    
    open func submitBuffer<T>(_ buffer: Buffer<T>, name: String) {
        if let location = attribs[name]?.location {
            glEnableVertexAttribArray(GLuint(location))
            buffer.submit(GLuint(location))
        }
    }
    
    open func submitTexture(_ texture: Texture, uniformName: String) {
        if let location = uniforms[uniformName]?.location {
            texture.submit(location)
        }
    }
    
    // Convert GLchar, GLbyte, GLshort, GLsizei to GLint
    // Convert GLboolean, GLubyte, GLushort to GLuint
    open func submitUniform<U:ProgramSubmissible>(_ value: U, uniformName: String) {
        if let location = uniforms[uniformName]?.location {
            value.submit(location)
        }
    }
    
    // MARK: OpenGL/ES state queries
    
    open func activeAttributeNames() -> [String] {
        return [String](attribs.keys)
    }
    
    open func activeUniformNames() -> [String] {
        return [String](uniforms.keys)
    }
    
    open func getActiveAttributes() -> [Variable] {
        let maxLength = getMaxAttributeNameLength()
        var attributes = [Variable]()
        for i in 0 ..< Int(getNumberOfActiveAttributes()) {
            if let attribute = getActiveAttributeAtIndex(GLuint(i), maxLength: maxLength) {
                attributes.append(attribute)
            }
        }
        return attributes
    }
    
    open func getActiveUniforms() -> [Variable] {
        let maxLength = getMaxUniformNameLength()
        var uniforms = [Variable]()
        for i in 0 ..< Int(getNumberOfActiveUniforms()) {
            if let uniform = getActiveUniformAtIndex(GLuint(i), maxLength: maxLength) {
                uniforms.append(uniform)
            }
        }
        return uniforms
    }
    
    func getActiveAttributeAtIndex(_ index: GLuint, maxLength: GLint) -> Variable? {
        return getActiveVariableAtIndex(index, maxLength: maxLength, getVariable: glGetActiveAttrib, getLocation: glGetAttribLocation)
    }
    
    func getActiveUniformAtIndex(_ index: GLuint, maxLength: GLint) -> Variable? {
        return getActiveVariableAtIndex(index, maxLength: maxLength, getVariable: glGetActiveUniform, getLocation: glGetUniformLocation)
    }
    
    func getActiveVariableAtIndex(_ index: GLuint, maxLength: GLint, getVariable: @escaping GetActiveVariableFunc, getLocation: GetVariableLocationFunc) -> Variable? {
        var size: GLint = 0
        var type: GLenum = 0
        let variableName = String(length: Int(maxLength), unsafeMutableBufferPointer: { (p: UnsafeMutableBufferPointer<Int8>) in
            getVariable(self.name, index, maxLength, nil, &size, &type, p.baseAddress!)
        })
        let location = getVariableLocation(variableName, getLocation: getLocation)
        return location == Program.UnknownLocation ? nil : Variable(name: variableName, type: type, size: size, location: location)
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
    
    func getProgramValue(_ value: GLenum) -> GLint {
        var result: GLint = 0
        glGetProgramiv(name, value, &result )
        return result
    }
    
    func getLocationsForAttributes(_ attributes: [String]) -> [String:GLint] {
        return getLocationsForStrings(attributes, function: getLocationOfAttribute)
    }
    
    func getLocationsForUniforms(_ uniforms: [String]) -> [String:GLint] {
        return getLocationsForStrings(uniforms, function: getLocationOfUniform)
    }
    
    func getLocationsForStrings(_ strings: [String], function: (String) -> GLint) -> [String:GLint] {
        var results = [String:GLint]()
        for attribute in strings {
            results[attribute] = function(attribute)
        }
        return results
    }
    
    open func getLocationOfAttribute(_ attribute: String) -> GLint {
        return getVariableLocation(attribute, getLocation: glGetAttribLocation)
    }
    
    open func getLocationOfUniform(_ uniform: String) -> GLint {
        return getVariableLocation(uniform, getLocation: glGetUniformLocation)
    }
    
    func getVariableLocation(_ variable: String, getLocation: GetVariableLocationFunc) -> GLint {
        var result: GLint = 0
        variable.withCString { (p: UnsafePointer<Int8>) in
            result = getLocation(self.name, p)
        }
        return result
    }
}
