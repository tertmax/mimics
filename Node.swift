//
//  Node.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 17.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import ARKit

class Node: SKSpriteNode {
    
    var initPoint: CGPoint = .zero
    var initXScale: CGFloat = 0.7
    var initYScale: CGFloat = 0.7
    var initRotation: CGFloat = 0
    var initZPosition: CGFloat = 0
    var draggable: Bool = false
    var inUse: Bool = false
    var additionalResetLogic: ((Node) -> Void)?
    var needsReset: Bool = true
    
    func setup(draggable: Bool) {
        self.initPoint = self.position
        self.draggable = draggable
        self.initXScale = self.xScale
        self.initYScale = self.yScale
        self.initRotation = self.zRotation
        self.initZPosition = self.zPosition
    }
    
    func isContactingWith(_ node: SKSpriteNode) -> Bool {
        guard let nodeBody = node.physicsBody, let selfBody = self.physicsBody,
            selfBody.allContactedBodies().contains(nodeBody) else { return false }
        return true
    }
    
    func reset() {
        guard needsReset else {
            needsReset.toggle()
            return
        }
        xScale = initXScale
        yScale = initYScale
        position = initPoint
        zPosition = initZPosition
        zRotation = initRotation
        inUse = false
        additionalResetLogic?(self)
    }
}
