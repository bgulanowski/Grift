//
//  Buffer.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

public struct Float2 {
    
    let x: GLfloat
    let y: GLfloat
    
    public init(x: GLfloat, y: GLfloat) {
        self.x = x
        self.y = y
    }
    
    public init(tuple: (GLfloat, GLfloat)) {
        x = tuple.0
        y = tuple.1
    }
}

public struct Float3 {
    
    let x: GLfloat
    let y: GLfloat
    let z: GLfloat
    
    public init(x: GLfloat, y: GLfloat, z: GLfloat) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(tuple: (GLfloat, GLfloat, GLfloat)) {
        x = tuple.0
        y = tuple.1
        z = tuple.2
    }
}

public struct Float4 {
    
    let x: GLfloat
    let y: GLfloat
    let z: GLfloat
    let w: GLfloat
    
    public init(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    public init(tuple: (GLfloat, GLfloat, GLfloat, GLfloat)) {
        x = tuple.0
        y = tuple.1
        z = tuple.2
        w = tuple.3
    }
}

public typealias Point2 = Float2
public typealias Point3 = Float3
public typealias Color = Float4
public typealias Normal = Float3
public typealias TexCoord = Float2

public class Buffer<T> {
    
    var name: GLuint = 0
    var target: GLenum {
        return GLenum(0)
    }
    var normalize: GLboolean {
        return GLboolean(GL_FALSE)
    }
    public let count: GLsizei
    public var typeSize: GLsizei {
        return GLsizei(sizeof(T))
    }
    public var glType: GLenum {
        return GLenum(0)
    }
    
    public init(elements: [T]) {
        count = GLsizei(elements.count)
        glGenBuffers(1, &name)
        glBindBuffer(target, name)
        glBufferData(target, elements.count * sizeof(T.Type), elements, GLenum(GL_STATIC_DRAW))
    }
    
    deinit {
        if name > 0 {
            delete()
        }
    }

    func bind() {
        glBindBuffer(target, name)
    }
    
    func submit(location: GLuint) {
        bind()
        glEnableVertexAttribArray(location)
        glVertexAttribPointer(GLuint(location), typeSize, glType, normalize, 0, UnsafePointer<Void>())
    }
    
    func delete() {
        glDeleteBuffers(1, &name)
        name = 0
    }
}

public class IndexBuffer : Buffer<GLuint> {
    override var target: GLenum {
        return GLenum(GL_ELEMENT_ARRAY_BUFFER)
    }
    override public var glType: GLenum {
        return GLenum(GL_INT)
    }
    override public init(elements: [GLuint]) {
        super.init(elements: elements)
    }
}

public class VertexBuffer<T> : Buffer<T> {
    override var target: GLenum {
        return GLenum(GL_ARRAY_BUFFER)
    }
    public override var glType: GLenum {
        return GLenum(GL_FLOAT)
    }
    public override init(elements: [T]) {
        super.init(elements: elements)
    }
}

public typealias Point2Buffer = VertexBuffer<Point2>
public typealias Point3Buffer = VertexBuffer<Point3>
public typealias ColorBuffer = VertexBuffer<Color>
public typealias TexCoordBuffer = VertexBuffer<TexCoord>

public class NormalBuffer : VertexBuffer<Normal> {
    override var normalize: GLboolean {
        return GLboolean(GL_TRUE)
    }
}
