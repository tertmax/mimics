//
//  BathNodes.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 26.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

class BathNodes {
    let leftBrow: Node
    let rightBrow: Node
    let leftEyeBall: Node
    let rightEyeBall: Node
    let mouthDefault: Node
    let jawTop: Node
    let jawBottom: Node
    let lipTop: Node
    let lipBottom: Node
    let mouthInside: Node
    let water: Node
    let steam1: Node
    let steam2: Node
    let steam3: Node
    let pimple1Initial: Node
    let pimple1Bleeidng: Node
    let pimple1Fixed: Node
    let pimple2: Node
    let pimple1Pinch: Node
    let pimple2Pinch: Node
    let toothBrush: Node
    let razor: Node
    let towel: Node
    let wetTowel: Node
    let bandage: Node
    let toiletWater: Node
    let comb: Node
    let eyes: Node
    let coldValve: Node
    let hotValve: Node
    let crane: Node
    let hairLeftInitial: Node
    let hairLeftFixed: Node
    let hairRightInitial: Node
    let hairRightFixedLeft: Node
    let hairRightFixedRight: Node
    let hairRightFixedUp: Node
    let hairRightFixedDown: Node
    let leftCheek: Node
    let rightCheek: Node
    let mouthBrushed: Node
    let mouthBrushedWater: Node
    let fallingWater1: Node
    let fallingWater2: Node
    let fallingWater3: Node
    let fly: Node
    let flyBody: Node
    let flyNose: Node
    let flyWings: Node
    let cupMagenta: Node
    var hairPieces: [Node]
    let razorTop: Node
    let toothbrushTop: Node
    
    init(scene: SKScene?) {
        
        func setupNode(name: String, parentNode: SKSpriteNode? = nil, draggable: Bool = false) -> Node {
            if let child = parentNode?.childNode(withName: name) as? Node {
                child.setup(draggable: draggable)
                return child
            } else if let child = scene?.childNode(withName: name) as? Node {
                child.setup(draggable: draggable)
                return child
            } else {
                fatalError("No such node for Bath GameScene: \(name)")
            }
        }
        
        leftBrow = setupNode(name: R.string.bath.left_brow())
        rightBrow = setupNode(name: R.string.bath.right_brow())
        leftEyeBall = setupNode(name: R.string.bath.left_eyeball())
        rightEyeBall = setupNode(name: R.string.bath.right_eyeball())
        jawTop = setupNode(name: R.string.bath.jaw_top())
        jawBottom = setupNode(name: R.string.bath.jaw_bottom())
        lipTop = setupNode(name: R.string.bath.lip_top())
        lipBottom = setupNode(name: R.string.bath.lip_bottom())
        mouthInside = setupNode(name: R.string.bath.mouth_inside())
        mouthDefault = setupNode(name: R.string.bath.mouth_default())
        water = setupNode(name: R.string.bath.water())
        steam1 = setupNode(name: R.string.bath.steam1())
        steam2 = setupNode(name: R.string.bath.steam2())
        steam3 = setupNode(name: R.string.bath.steam3())
        pimple1Initial = setupNode(name: R.string.bath.pimple1_initial())
        pimple1Bleeidng = setupNode(name: R.string.bath.pimple1_bleedning())
        pimple1Fixed = setupNode(name: R.string.bath.pimple1_fixed())
        pimple2 = setupNode(name: R.string.bath.pimple2())
        pimple1Pinch = setupNode(name: R.string.bath.pimple1_pinch_zone())
        pimple2Pinch = setupNode(name: R.string.bath.pimple2_pinch_zone())
        eyes = setupNode(name: R.string.bath.eyes())
        coldValve = setupNode(name: R.string.bath.cold_valve())
        hotValve = setupNode(name: R.string.bath.hot_valve())
        crane = setupNode(name: R.string.bath.crane())
        hairLeftInitial = setupNode(name: R.string.bath.hair_left_initial())
        hairLeftFixed = setupNode(name: R.string.bath.hair_left_fixed())
        hairRightInitial = setupNode(name: R.string.bath.hair_right_initial())
        hairRightFixedLeft = setupNode(name: R.string.bath.hair_right_fixed_left())
        hairRightFixedRight = setupNode(name: R.string.bath.hair_right_fixed_right())
        hairRightFixedUp = setupNode(name: R.string.bath.hair_right_fixed_up())
        hairRightFixedDown = setupNode(name: R.string.bath.hair_right_fixed_down())
        leftCheek = setupNode(name: R.string.bath.left_cheek())
        rightCheek = setupNode(name: R.string.bath.right_cheek())
        mouthBrushed = setupNode(name: R.string.bath.mouth_brushed())
        mouthBrushedWater = setupNode(name: R.string.bath.mouth_brushed_water())
        fallingWater1 = setupNode(name: R.string.bath.water_falling1())
        fallingWater2 = setupNode(name: R.string.bath.water_falling2())
        fallingWater3 = setupNode(name: R.string.bath.water_falling3())
        fly = setupNode(name: R.string.bath.fly())
        flyBody = setupNode(name: R.string.bath.fly_body(), parentNode: fly)
        flyNose = setupNode(name: R.string.bath.fly_nose(), parentNode: fly)
        flyWings = setupNode(name: R.string.bath.fly_wings(), parentNode: fly)
        cupMagenta = setupNode(name: R.string.bath.magenta_cup())
        
        var hairs: [Node] = []
        for i in 2...45 {
            hairs.append(setupNode(name: R.string.bath.hair_piece() + String(i)))
        }
        hairPieces = hairs
        
        toothBrush = setupNode(name: R.string.bath.toothbrush(), draggable: true)
        razor = setupNode(name: R.string.bath.razor(), draggable: true)
        razor.additionalResetLogic = { razorNode in
            let changeTexture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_razor.name))
            razorNode.run(changeTexture)
        }
        towel = setupNode(name: R.string.bath.towel_dry(), draggable: true)
        wetTowel = setupNode(name: R.string.bath.towel_wet(), draggable: true)
        bandage = setupNode(name: R.string.bath.bandage(), draggable: true)
        toiletWater = setupNode(name: R.string.bath.toilet_water(), draggable: true)
        comb = setupNode(name: R.string.bath.comb(), draggable: true)
        
        razorTop = setupNode(name: R.string.bath.razor_top(), parentNode: razor)
        toothbrushTop = setupNode(name: R.string.bath.toothbrush_top(), parentNode: toothBrush)
        
    }
}
