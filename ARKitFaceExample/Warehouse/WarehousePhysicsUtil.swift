//
//  WarehousePhysicsUtil.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 30.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

class WarehousePhysicsUtil {
    
    enum Contact: UInt32, PhysicsCategory {
        
        var mask: UInt32 {
            return self.rawValue
        }
        
        static func create(value: UInt32) -> PhysicsCategory? {
            return Contact(rawValue: value)
        }
        
        case other = 0
        case lense = 1
        case flashlight = 2
       
    }

    func createPhyscisBodies(nodes: WarehouseNodes) {
        
        //MARK: - Lense
        let lenseSize = CGSize(width: 10, height: 10)
        let lense = makeRectBody(size: lenseSize, contact: .flashlight, categoty: .lense)
        nodes.lense.physicsBody = lense
        
        //MARK: - Flashlight
        let flashlightRadius = nodes.flashlight.frame.size.height / 2
        let flashlight = makeCircleBody(radius: flashlightRadius, contact: .lense, category: .flashlight)
        nodes.flashlight.physicsBody = flashlight
    }
    
    private func makeRectBody(size: CGSize, contact: Contact, categoty: Contact) -> SKPhysicsBody {
        return BasePhysics.makeBody(shape: .rect(size: size), contact: contact, categoty: categoty)
    }
    
    private func makeCircleBody(radius: CGFloat, contact: Contact, category: Contact) -> SKPhysicsBody {
        return BasePhysics.makeBody(shape: .circle(radius: radius), contact: contact, categoty: category)
    }
}
