//
//  CustomRenderer.swift
//  SwiftUIKit
//
//  Created by Zach Eriksen on 1/19/20.
//

import MetalKit

@available(iOS 9.0, *)
public class CustomRenderer: NSObject {
    // Dummy
    public func getMesh() -> MDLMesh {
        return Primitive.makeCube(device: device, size: 1)
    }
    
    public var mesh: MTKMesh?
    public var vertexBuffer: MTLBuffer?
    public var pipelineState: MTLRenderPipelineState?
    public var vertexFunction: MTLFunction?
    public var fragmentFunction: MTLFunction?
    public var computePipelineState: MTLComputePipelineState?
    public var clearColor: MTLClearColor?
    public var renderMethod: ((MTLRenderCommandEncoder) -> Void)?
    
    public var vertexShaderName: String = "vertex_main"
    public var fragmentShaderName: String = "fragment_main"
    public var computeShaderName: String?
    var timer: Float = 0
    
    public override init() {
        super.init()
        
        vertex { vertexShaderName }
            .fragment { fragmentShaderName }
            .mesh { _ in getMesh() }
        
    }
    
    @discardableResult
    public func mesh(_ closure: (MTLDevice) -> MDLMesh) -> Self {
        do{
            mesh = try MTKMesh(mesh: closure(device), device: device)
        } catch let error {
            print(error.localizedDescription)
        }
        
        vertexBuffer = mesh?.vertexBuffers[0].buffer
        return self
    }
    
    @discardableResult
    public func vertex(shaderName: () -> String) -> Self {
        let defaultLibrary = try? device.makeLibrary(source: defaultShaders, options: nil)
        let library = device.makeDefaultLibrary() ?? defaultLibrary
        
        vertexFunction = library?.makeFunction(name: shaderName())
        
        return self
    }
    
    @discardableResult
    public func fragment(shaderName: () -> String) -> Self {
        let defaultLibrary = try? device.makeLibrary(source: defaultShaders, options: nil)
        let library = device.makeDefaultLibrary() ?? defaultLibrary
        
        fragmentFunction = library?.makeFunction(name: shaderName())
        
        return self
    }
    
    @discardableResult
    public func compute(shaderName: () -> String) -> Self {
        
        let defaultLibrary = try? device.makeLibrary(source: defaultShaders, options: nil)
        let library = device.makeDefaultLibrary() ?? defaultLibrary
        
        if let kernel = library?.makeFunction(name: shaderName()) {
            computePipelineState = try? device.makeComputePipelineState(function: kernel)
        }
        
        return self
    }
    
    @discardableResult
    public func clear(color: () -> MTLClearColor) -> Self {
        clearColor = color()
        
        return self
    }
    
    @discardableResult
    public func render(encoder: @escaping (MTLRenderCommandEncoder) -> Void) -> Self {
        renderMethod = encoder
        
        return self
    }
}

@available(iOS 9.0, *)
extension CustomRenderer: Renderer {
    
    public func load(metalView: MTKView) {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        if let mesh = mesh {
            pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        }
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // Protocol
        if let color = clearColor {
            metalView.clearColor = color
        }
        metalView.delegate = self
    }
    
    public func configure(renderEncoder: MTLRenderCommandEncoder) -> MTLRenderCommandEncoder? {
        
        guard let pipelineState = pipelineState,
            let mesh = mesh else {
                return nil
        }
        
        timer += 0.05
        var currentTime = sin(timer)
        var al = abs(currentTime)
        
        renderEncoder.setVertexBytes(&currentTime,
                                     length: MemoryLayout<Float>.stride,
                                     index: 1)
        renderEncoder.setFragmentBytes(&al,
                                       length: MemoryLayout<Float>.stride,
                                       index: 0)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        for submesh in mesh.submeshes {
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: submesh.indexCount,
                                                indexType: submesh.indexType,
                                                indexBuffer: submesh.indexBuffer.buffer,
                                                indexBufferOffset: submesh.indexBuffer.offset)
            
        }
        
        return renderEncoder
    }
    
    public func configure(computeEncoder: MTLComputeCommandEncoder) -> MTLComputeCommandEncoder? {
        return computeEncoder
    }
}

@available(iOS 9.0, *)
extension CustomRenderer: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    
    public func draw(in view: MTKView) {
        draw(metalView: view)
    }
}
