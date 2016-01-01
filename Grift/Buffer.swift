//
//  Buffer.swift
//  Grift
//
//  Created by Brent Gulanowski on 2015-12-31.
//  Copyright © 2015 Lichen Labs. All rights reserved.
//

import Foundation
import OpenGLES

struct Float2 {
    let x: GLfloat
    let y: GLfloat
}

struct Float3 {
    let x: GLfloat
    let y: GLfloat
    let z: GLfloat
}

struct Float4 {
    let x: GLfloat
    let y: GLfloat
    let z: GLfloat
    let w: GLfloat
}

typealias Point3 = Float3
typealias Color = Float4
typealias Normal = Float4
typealias TexCoord = Float2

class Buffer<T> {
    
    var name: GLuint = 0
    var target: GLenum {
        return GLenum(0)
    }
    let count: Int
    var typeSize: GLsizei {
        return GLsizei(sizeof(T))
    }
    var glType: GLenum {
        return GLenum(0)
    }
    
    init(elements: [T]) {
        count = elements.count
        glGenBuffers(1, &name)
        glBindBuffer(target, name)
        glBufferData(target, elements.count * sizeof(T.Type), elements, GLenum(GL_STATIC_DRAW))
    }
    
    func bind() {
        glBindBuffer(target, name)
    }
    
    func delete() {
        glDeleteBuffers(1, &name)
        name = 0
    }
}

class IndexBuffer : Buffer<GLuint> {
    override var target: GLenum {
        return GLenum(GL_ELEMENT_ARRAY_BUFFER)
    }
    override var glType: GLenum {
        return GLenum(GL_INT)
    }
}

class VertexBuffer<T> : Buffer<T> {
    override var target: GLenum {
        return GLenum(GL_ARRAY_BUFFER)
    }
    override var glType: GLenum {
        return GLenum(GL_FLOAT)
    }
}

typealias PointBuffer = VertexBuffer<Point3>
typealias ColorBuffer = VertexBuffer<Color>
typealias NormalBuffer = VertexBuffer<Normal>
typealias TexCoordBuffer = VertexBuffer<TexCoord>
