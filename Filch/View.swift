//
//  View.swift
//  Grift
//
//  Created by Brent Gulanowski on 2016-01-06.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

import UIKit
import Grift

class View: UIView {

    var context: EAGLContext!
    var framebuffer: Framebuffer!
    var program: Program!
    var pointBuffer: Point3Buffer!
    var colorBuffer: ColorBuffer!
    var texCoordBuffer: Point2Buffer!
    var texture: Texture!
    
    var glLayer: CAEAGLLayer {
        return layer as! CAEAGLLayer
    }
    
    override class func layerClass() -> AnyClass {
        return CAEAGLLayer.self
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        prepareGL()
        render()
    }
    
    func prepareGL() {
        // this must happen first
        prepareContext()
        
        // these can happen in any order
        prepareDrawable()
        prepareRendererState()
        prepareShaders()
        prepareContent()
    }
    
    func prepareContext() {
        context = EAGLContext(API: .OpenGLES3)
        EAGLContext.setCurrentContext(context)
    }
    
    func prepareDrawable() {
        let colorBuffer = Renderbuffer()
        // renderbuffer storage must be allocated before it is attached to the framebuffer
        context.renderbufferStorage(colorBuffer, fromDrawable: glLayer)
        framebuffer = Framebuffer()
        framebuffer.setColorAttachment(colorBuffer, atIndex: 0)
    }
    
    func prepareShaders() {
        program = Program()
    }
    
    func prepareRendererState() {
        let size = bounds.size
        glViewport(0, 0, GLsizei(size.width), GLsizei(size.height))
        glClearColor(0.5, 0, 0, 1)
        
    }
    
    func prepareContent() {
        pointBuffer = makePoints()
        texCoordBuffer = makeTexCoords()
        colorBuffer = makeColors()
        texture = Texture.textureWithName("David", filetype: "png")
    }
    
    func makePoints() -> Point3Buffer {
        let elements = [
            Point3(tuple: (-0.5, -0.5, 0.0)),
            Point3(tuple: ( 0.5, -0.5, 0.0)),
            Point3(tuple: ( 0.5,  0.5, 0.0)),
            Point3(tuple: (-0.5,  0.5, 0.0)),
        ]
        return Point3Buffer(elements: elements)
    }
    
    func makeTexCoords() -> TexCoordBuffer {
        let elements = [
            // Y coordinates are flipped because iOS?
            TexCoord(tuple: (0.0, 1.0)),
            TexCoord(tuple: (1.0, 1.0)),
            TexCoord(tuple: (1.0, 0.0)),
            TexCoord(tuple: (0.0, 0.0)),
        ]
        return TexCoordBuffer(elements: elements)
    }
    
    func makeColors() -> ColorBuffer {
        let elements = [
            Color(x: 1, y: 0, z: 0, w: 1),
            Color(x: 0, y: 1, z: 0, w: 1),
            Color(x: 0, y: 0, z: 1, w: 1),
            Color(x: 1, y: 1, z: 0, w: 1)
        ]
        return ColorBuffer(elements: elements)
    }

    func render() {
        
        framebuffer.bind()
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT))
        
        program.use()
        
        // TODO: support for matrices in Program.submitUniformMatrix
        let matrix = Array<GLfloat>( arrayLiteral:
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        )
        
        glUniformMatrix4fv(program.getLocationOfUniform("MVP"), 1, GLboolean(GL_FALSE), matrix)
        glLineWidth(GLfloat(5.0))
        
        program.submitUniform(GLint(GL_TRUE), uniformName: "useTex")
        program.submitTexture(texture, uniformName: "texture")
        program.submitBuffer(pointBuffer, name: "position")
        program.submitBuffer(colorBuffer, name: "colour")
        program.submitBuffer(texCoordBuffer, name: "texCoord")
        
        glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, pointBuffer.count)
        
        self.context.presentRenderbuffer(Int(GL_FRAMEBUFFER))
    }
}
