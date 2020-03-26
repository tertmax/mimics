//
//  BathPhysicsUtil.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 26.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

enum Contact: UInt32, PhysicsCategory {
    
    var mask: UInt32 {
        return self.rawValue
    }
    
    static func create(value: UInt32) -> PhysicsCategory? {
        return Contact(rawValue: value)
    }
    
    case other = 0
    case comb = 1
    case hair = 2
    case teeth = 4
    case toothBrush = 8
    case cup = 16
    case water = 32
    case hairPiece = 64
    case razor = 128
    case mouthBrushed = 256
    case pimple = 512
    case bandage = 1024
}

class BathPhysicsUtil {
    func createPhyscisBodies(nodes: BathNodes) {
        
        // Hair
        let hairScale = CGAffineTransform(scaleX: 0.4, y: 0.35)
        let leftHairInitial = SKPhysicsBody(rectangleOf: nodes.hairLeftInitial.size.applying(hairScale))
        let leftHairFixed = SKPhysicsBody(rectangleOf: nodes.hairLeftFixed.size.applying(hairScale))
        let rightHairInitial = SKPhysicsBody(rectangleOf: nodes.hairRightInitial.size.applying(hairScale))
        let rightHairFixedRight = SKPhysicsBody(rectangleOf: nodes.hairRightFixedRight.size.applying(hairScale))
        let rightHairFixedLeft = SKPhysicsBody(rectangleOf: nodes.hairRightFixedLeft.size.applying(hairScale))
        let rightHairFixedUp = SKPhysicsBody(rectangleOf: nodes.hairRightFixedUp.size.applying(hairScale))
        let rightHairFixedDown = SKPhysicsBody(rectangleOf: nodes.hairRightFixedDown.size.applying(hairScale))
        
        let hairBodies: [SKPhysicsBody] = [leftHairInitial, leftHairFixed,
                                           rightHairInitial, rightHairFixedRight,
                                           rightHairFixedLeft, rightHairFixedUp, rightHairFixedDown]
        for body in hairBodies {
            body.affectedByGravity = false
            body.contactTestBitMask = Contact.comb.rawValue
            body.categoryBitMask = Contact.hair.rawValue
            body.collisionBitMask = Contact.other.rawValue
        }
        
        nodes.hairLeftInitial.physicsBody = leftHairInitial
        nodes.hairLeftFixed.physicsBody = leftHairFixed
        nodes.hairRightInitial.physicsBody = rightHairInitial
        nodes.hairRightFixedRight.physicsBody = rightHairFixedRight
        nodes.hairRightFixedLeft.physicsBody = rightHairFixedLeft
        nodes.hairRightFixedUp.physicsBody = rightHairFixedUp
        nodes.hairRightFixedDown.physicsBody = rightHairFixedDown
        
        // Comb
        
        let combScale = CGAffineTransform(scaleX: 0.75, y: 0.75)
        let comb = SKPhysicsBody(rectangleOf: nodes.comb.size.applying(combScale))
        comb.affectedByGravity = false
        comb.contactTestBitMask = Contact.hair.rawValue
        comb.categoryBitMask = Contact.comb.rawValue
        comb.collisionBitMask = Contact.other.rawValue
        
        nodes.comb.physicsBody = comb
        
        // Toothbrush
        
        let toothBrush = SKPhysicsBody(rectangleOf: nodes.toothbrushTop.size)
        toothBrush.affectedByGravity = false
        toothBrush.contactTestBitMask = Contact.teeth.rawValue
        toothBrush.categoryBitMask = Contact.toothBrush.rawValue
        toothBrush.collisionBitMask = Contact.other.rawValue
        
        nodes.toothbrushTop.physicsBody = toothBrush
        
        // Teeth
        let teethScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        let jawTop = SKPhysicsBody(rectangleOf: nodes.jawTop.size.applying(teethScale))
        jawTop.affectedByGravity = false
        jawTop.contactTestBitMask = Contact.toothBrush.rawValue
        jawTop.categoryBitMask = Contact.teeth.rawValue
        jawTop.collisionBitMask = Contact.other.rawValue
        
        nodes.jawTop.physicsBody = jawTop
        
        let jawBottom = SKPhysicsBody(rectangleOf: nodes.jawBottom.size.applying(teethScale))
        jawBottom.affectedByGravity = false
        jawBottom.contactTestBitMask = Contact.toothBrush.rawValue
        jawBottom.categoryBitMask = Contact.teeth.rawValue
        jawBottom.collisionBitMask = Contact.other.rawValue
        
        nodes.jawBottom.physicsBody = jawBottom
        
        // Mouth brushed
        let brushedMouthScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        let mouthBrushed = SKPhysicsBody(rectangleOf: nodes.mouthBrushed.size.applying(brushedMouthScale))
        mouthBrushed.affectedByGravity = false
        mouthBrushed.contactTestBitMask = Contact.cup.rawValue
        mouthBrushed.categoryBitMask = Contact.mouthBrushed.rawValue
        mouthBrushed.collisionBitMask = Contact.other.rawValue
        
        nodes.mouthBrushed.physicsBody = mouthBrushed
        
        // Water
        
        let waterScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        let water = SKPhysicsBody(rectangleOf: nodes.water.size.applying(waterScale))
        water.affectedByGravity = false
        water.contactTestBitMask = Contact.cup.rawValue
        water.categoryBitMask = Contact.water.rawValue
        water.collisionBitMask = Contact.other.rawValue
        
        nodes.water.physicsBody = water
        
        // Cups
        
        let cupScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        let cupMagenta = SKPhysicsBody(rectangleOf: nodes.cupMagenta.size.applying(cupScale))
        cupMagenta.affectedByGravity = false
        cupMagenta.contactTestBitMask = Contact.water.rawValue
        cupMagenta.categoryBitMask = Contact.cup.rawValue
        cupMagenta.collisionBitMask = Contact.other.rawValue
        
        nodes.cupMagenta.physicsBody = cupMagenta
        
        // Hair pieces
        
        let hairPieceScale = CGAffineTransform(scaleX: 0.3, y: 0.7)
        for hairNode in nodes.hairPieces {
            let hairPiece = SKPhysicsBody(rectangleOf: hairNode.size.applying(hairPieceScale))
            hairPiece.affectedByGravity = false
            hairPiece.contactTestBitMask = Contact.razor.rawValue
            hairPiece.categoryBitMask = Contact.hairPiece.rawValue
            hairPiece.collisionBitMask = Contact.other.rawValue
            
            hairNode.physicsBody = hairPiece
        }
        
        // Razor
        
        let razorScale = CGAffineTransform(scaleX: 0.5, y: 0.08)
        let razorRect = nodes.razorTop.size
        
        let razorBlade = SKPhysicsBody(rectangleOf: razorRect)
        razorBlade.affectedByGravity = false
        razorBlade.contactTestBitMask = Contact.hairPiece.rawValue
        razorBlade.categoryBitMask = Contact.razor.rawValue
        razorBlade.collisionBitMask = Contact.other.rawValue
        
        nodes.razorTop.physicsBody = razorBlade
        
        // Pimple1
        
        let pimple1 = SKPhysicsBody(rectangleOf: nodes.pimple1Bleeidng.size)
        pimple1.affectedByGravity = false
        pimple1.contactTestBitMask = Contact.bandage.rawValue
        pimple1.categoryBitMask = Contact.pimple.rawValue
        pimple1.collisionBitMask = Contact.other.rawValue
        
        nodes.pimple1Bleeidng.physicsBody = pimple1
        
        // Bandage
        
        let bandage = SKPhysicsBody(rectangleOf: nodes.bandage.size)
        bandage.affectedByGravity = false
        bandage.contactTestBitMask = Contact.pimple.rawValue
        bandage.categoryBitMask = Contact.bandage.rawValue
        bandage.collisionBitMask = Contact.other.rawValue
        
        nodes.bandage.physicsBody = bandage
    }
}
