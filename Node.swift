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
    var draggable: Bool = false
    var inUse: Bool = false
    
    func setup(draggable: Bool) {
        self.initPoint = self.position
        self.draggable = draggable
        self.initXScale = self.xScale
        self.initYScale = self.yScale
    }
    
    func startUsing() {
        inUse = true
    }
    
    func stopUsing() {
        inUse = false
    }
}
