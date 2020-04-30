//
//  BathPhysicsUtil.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 26.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit


class BathPhysicsUtil {
    
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
        case towel = 2048
        case dirt = 4096
        case shirt = 8196
        case toiletWater = 16392
        case leftEar = 32784
        case rightEar = 65568
        case stickLeft = 131136
        case stickRight = 262272
    }

    func createPhyscisBodies(nodes: BathNodes) {
        
        // Hair
        let hairScale = CGAffineTransform(scaleX: 0.4, y: 0.35)
        let leftHairInitial = makeRectBody(size: nodes.hairLeftInitial.size.applying(hairScale),
                                           contact: .comb, categoty: .hair)
        let leftHairFixed = makeRectBody(size: nodes.hairLeftFixed.size.applying(hairScale),
                                         contact: .comb, categoty: .hair)
        let rightHairInitial = makeRectBody(size: nodes.hairRightInitial.size.applying(hairScale),
                                            contact: .comb, categoty: .hair)
        let rightHairFixedRight = makeRectBody(size: nodes.hairRightFixedRight.size.applying(hairScale),
                                               contact: .comb, categoty: .hair)
        let rightHairFixedLeft = makeRectBody(size: nodes.hairRightFixedLeft.size.applying(hairScale),
                                              contact: .comb, categoty: .hair)
        let rightHairFixedUp = makeRectBody(size: nodes.hairRightFixedUp.size.applying(hairScale),
                                            contact: .comb, categoty: .hair)
        let rightHairFixedDown = makeRectBody(size: nodes.hairRightFixedDown.size.applying(hairScale),
                                              contact: .comb, categoty: .hair)
        
        nodes.hairLeftInitial.physicsBody = leftHairInitial
        nodes.hairLeftFixed.physicsBody = leftHairFixed
        nodes.hairRightInitial.physicsBody = rightHairInitial
        nodes.hairRightFixedRight.physicsBody = rightHairFixedRight
        nodes.hairRightFixedLeft.physicsBody = rightHairFixedLeft
        nodes.hairRightFixedUp.physicsBody = rightHairFixedUp
        nodes.hairRightFixedDown.physicsBody = rightHairFixedDown
        
        // Comb
        
        let combScale = CGAffineTransform(scaleX: 0.75, y: 0.75)
        let comb = makeRectBody(size: nodes.comb.size.applying(combScale), contact: .hair, categoty: .comb)
        nodes.comb.physicsBody = comb
        
        // Toothbrush
        
        let toothBrush = makeRectBody(size: nodes.toothbrushTop.size, contact: .teeth, categoty: .toothBrush)
        nodes.toothbrushTop.physicsBody = toothBrush
        
        // Teeth
        let teethScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        let jawTop = makeRectBody(size: nodes.jawTop.size.applying(teethScale), contact: .toothBrush, categoty: .teeth)
        nodes.jawTop.physicsBody = jawTop
        
        let jawBottom = makeRectBody(size: nodes.jawBottom.size.applying(teethScale), contact: .toothBrush, categoty: .teeth)
        nodes.jawBottom.physicsBody = jawBottom
        
        // Mouth brushed
        
        let brushedMouthScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        let mouthBrushed = makeRectBody(size: nodes.mouthBrushed.size.applying(brushedMouthScale), contact: .cup, categoty: .mouthBrushed)
        nodes.mouthBrushed.physicsBody = mouthBrushed
        
        // Water
        
        let waterScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        let water = makeRectBody(size: nodes.water.size.applying(waterScale), contact: .cup, categoty: .water)
        nodes.water.physicsBody = water
        
        // Cups
        
        let cupScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        let cupMagenta = makeRectBody(size: nodes.cupMagenta.size.applying(cupScale), contact: .water, categoty: .cup)
        nodes.cupMagenta.physicsBody = cupMagenta
        
        // Hair pieces
        
        let hairPieceScale = CGAffineTransform(scaleX: 0.3, y: 0.7)
        for hairNode in nodes.hairPieces {
            let hairPiece = makeRectBody(size: hairNode.size.applying(hairPieceScale), contact: .razor, categoty: .hairPiece)
            hairNode.physicsBody = hairPiece
        }
        
        // Razor
        
        let razorBlade = makeRectBody(size: nodes.razorTop.size, contact: .hairPiece, categoty: .razor)
        nodes.razorTop.physicsBody = razorBlade
        
        // Pimple1
        
        let pimple1 = makeRectBody(size: nodes.pimple1Bleeidng.size, contact: .bandage, categoty: .pimple)
        nodes.pimple1Bleeidng.physicsBody = pimple1
        
        // Bandage
         
        let bandage = makeRectBody(size: nodes.bandage.size, contact: .pimple, categoty: .bandage)
        nodes.bandage.physicsBody = bandage
        
        // Towel
        
        let towelScale = CGAffineTransform(scaleX: 0.6, y: 0.6)
        
        let towel = SKPhysicsBody(rectangleOf: nodes.towel.size.applying(towelScale))
        towel.affectedByGravity = false
        towel.contactTestBitMask = Contact.dirt.rawValue | Contact.water.rawValue
        towel.categoryBitMask = Contact.towel.rawValue
        towel.collisionBitMask = Contact.other.rawValue
        
        nodes.towel.physicsBody = towel
        
        // Dirt
        
        let dirtScale = CGAffineTransform(scaleX: 0.6, y: 0.6)
        let dirt = makeRectBody(size: nodes.dirt.size.applying(dirtScale), contact: .towel, categoty: .dirt)
        nodes.dirt.physicsBody = dirt
        
        // Toilet water
        
        let toiletWaterScale = CGAffineTransform(scaleX: 0.6, y: 0.6)
        let toiletWater = makeRectBody(size: nodes.toiletWater.size.applying(toiletWaterScale),
                                       contact: .shirt, categoty: .toiletWater)
        toiletWater.usesPreciseCollisionDetection = true
        nodes.toiletWater.physicsBody = toiletWater
        
        // Shirt
        
        let shirt = makeRectBody(size: nodes.shirtZone.size, contact: .toiletWater, categoty: .shirt)
        nodes.shirtZone.physicsBody = shirt
        
        // Left stick
        
        let leftStick = makeRectBody(size: nodes.stickLeft.size, contact: .rightEar, categoty: .stickLeft)
        nodes.stickLeft.physicsBody = leftStick
        
        // Right stick
        
        let rightStick = makeRectBody(size: nodes.stickRight.size, contact: .leftEar, categoty: .stickRight)
        nodes.stickRight.physicsBody = rightStick
        
        // Left ear
        
        let leftEar = makeRectBody(size: nodes.earLeft.size, contact: .stickRight, categoty: .leftEar)
        nodes.earLeft.physicsBody = leftEar
        
        // Right ear
        
        let rightEar = makeRectBody(size: nodes.earRight.size, contact: .stickLeft, categoty: .rightEar)
        nodes.earRight.physicsBody = rightEar
    }

    private func makeRectBody(size: CGSize, contact: Contact, categoty: Contact) -> SKPhysicsBody {
        return BasePhysics.makeBody(shape: .rect(size: size), contact: contact, categoty: categoty)
    }
}
