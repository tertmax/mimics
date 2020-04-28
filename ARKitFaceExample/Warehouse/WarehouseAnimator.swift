//
//  WarehouseAnimator.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 27.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

protocol WarehouseAnimatable: class {
    var nodes: WarehouseNodes! { get }
    var state: WarehouseState { get set }
}

class WarehouseAnimator {
    
    weak var animatable: WarehouseAnimatable?
    
    init(animatable: WarehouseAnimatable) {
        self.animatable = animatable
    }
    
    func runMoveBackground(newX: CGFloat) {
        guard let a = animatable else { return }
        let move = SKAction.moveTo(x: newX, duration: 0.1)
        a.nodes.background.run(move)
    }
    
    func runMoveFlashlightX(node: SKShapeNode, x: CGFloat) {
        let move = SKAction.moveTo(x: x, duration: 0.1)
        node.run(move)
    }
    
    func runMoveFlashlightY(node: SKShapeNode, y: CGFloat) {
        let move = SKAction.moveTo(y: y, duration: 0.1)
        node.run(move)
    }
}
    
