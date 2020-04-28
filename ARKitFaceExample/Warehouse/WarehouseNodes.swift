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
        
        background = setupNode(name: "warehouse")
    }
}
