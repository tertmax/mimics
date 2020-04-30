//
//  WarehouseNodes.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 27.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

class WarehouseNodes {
    
    let background: Node
    let mouse: Node
    let candle: Node
    let candleFire: Node
    let cheese: Node
    let lense: Node
    let flashlight: SKShapeNode
    let lenseBeam: Node
    
    init(scene: SKScene?) {
        
        func setupNode(name: String, parentNode: SKSpriteNode? = nil, draggable: Bool = false) -> Node {
            if let child = parentNode?.childNode(withName: name) as? Node {
                child.setup(draggable: draggable)
                return child
            } else if let child = scene?.childNode(withName: name) as? Node {
                child.setup(draggable: draggable)
                return child
            } else {
                fatalError("No such node for Warehouse GameScene: \(name)")
            }
        }
        
        background = setupNode(name: R.string.wh.warehouse())
        mouse = setupNode(name: R.string.wh.mouse(), parentNode: background)
        
        candle = setupNode(name: R.string.wh.candle(), parentNode: background)
        candleFire = setupNode(name: R.string.wh.candle_fire(), parentNode: candle)
        
        cheese = setupNode(name: R.string.wh.cheese(), parentNode: background)
        lense = setupNode(name: R.string.wh.lense(), parentNode: background)
        lenseBeam = setupNode(name: R.string.wh.lense_beam(), parentNode: lense)
        
        
        // MARK: - Flashlight and mask
        
        let fullScreen = SKSpriteNode(color: .black, size: background.size)
        fullScreen.alpha = 0.95
        
        let mask = SKSpriteNode(color: .white, size: background.size)
        mask.alpha = 1
        
        let circle = SKShapeNode(circleOfRadius: 150)
        circle.fillColor = .white
        circle.lineWidth = 0
        circle.alpha = 0.001
        circle.blendMode = .replace
        circle.position = background.position
        
        mask.addChild(circle)
        
        let crop = SKCropNode()
        crop.maskNode = mask
        crop.addChild(fullScreen)
        crop.zPosition = 10
        
        background.scene?.addChild(crop)
        
        flashlight = circle
        
    }
}
