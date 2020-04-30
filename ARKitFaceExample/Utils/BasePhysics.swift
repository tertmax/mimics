//
//  BasePhysics.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 30.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

class BasePhysics {
    
    enum BodyShape {
        case rect(size: CGSize)
        case circle(radius: CGFloat)
    }
    
    class func makeBody(shape: BodyShape, contact: PhysicsCategory, categoty: PhysicsCategory) -> SKPhysicsBody {
        var body: SKPhysicsBody
        switch shape {
        case .circle(let radius):
            body = SKPhysicsBody(circleOfRadius: radius)
        case .rect(let size):
            body = SKPhysicsBody(rectangleOf: size)
        }
        body.affectedByGravity = false
        body.contactTestBitMask = contact.mask
        body.categoryBitMask = categoty.mask
        body.collisionBitMask = 0
        
        return body
    }
}
