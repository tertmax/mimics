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
    let pimple3: Node
    let pimple1Pinch: Node
    let pimple2Pinch: Node
    let pimple3Pinch: Node
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
    let dirt: Node
    let mirrorShape: Node
    let coldEffectsHead: [Node]
    let coldEffectNose: Node
    let mouthCold: Node
    let shirtZone: Node
    let badSpray1: Node
    let badSpray2: Node
    let badSpray3: Node
    let goodSpray1: Node
    let goodSpray2: Node
    let goodSpray3: Node
    let stick: Node
    let stickLeft: Node
    let stickRight: Node
    let spider: Node
    let spiderHands: Node
    let spiderLegs: Node
    let spiderFace: Node
    let spiderBody: Node
    let web: Node
    let earLeft: Node
    let earRight: Node
    let earpieceLeft: Node
    let earpieceRight: Node
    let stickLeftSwipe: Node
    let stickRightSwipe: Node
    let heart1: Node
    let heart2: Node
    let heart3: Node
    let thermometer: Node
    let shirtInitial: Node
    let shirtFixed: Node
    let redLine: Node
    let mirrorZone1: Node
    let mirrorZone2: Node
    let mirrorZone3: Node
    let flyAudio: SKAudioNode
    
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
        pimple3 = setupNode(name: R.string.bath.pimple3())
        pimple1Pinch = setupNode(name: R.string.bath.pimple1_pinch_zone())
        pimple2Pinch = setupNode(name: R.string.bath.pimple2_pinch_zone())
        pimple3Pinch = setupNode(name: R.string.bath.pimple3_pinch_zone())
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
        dirt = setupNode(name: R.string.bath.dirt())
        mirrorShape = setupNode(name: R.string.bath.mirror_shape())
        mouthCold = setupNode(name: R.string.bath.mouth_cold())
        shirtZone = setupNode(name: R.string.bath.shirt_zone())
        web = setupNode(name: R.string.bath.web())
        earLeft = setupNode(name: R.string.bath.ear_left())
        earRight = setupNode(name: R.string.bath.ear_right())
        earpieceLeft = setupNode(name: R.string.bath.earpiece_left())
        earpieceRight = setupNode(name: R.string.bath.earpiece_right())
        stickRightSwipe = setupNode(name: R.string.bath.stick_right_swipe())
        stickLeftSwipe = setupNode(name: R.string.bath.stick_left_swipe())
        heart1 = setupNode(name: R.string.bath.heart1())
        heart2 = setupNode(name: R.string.bath.heart2())
        heart3 = setupNode(name: R.string.bath.heart3())
        thermometer = setupNode(name: R.string.bath.thermometer())
        shirtInitial = setupNode(name: R.string.bath.shirt_initial())
        shirtFixed = setupNode(name: R.string.bath.shirt_fixed())
        mirrorZone1 = setupNode(name: R.string.bath.mirror_zone1())
        mirrorZone2 = setupNode(name: R.string.bath.mirror_zone2())
        mirrorZone3 = setupNode(name: R.string.bath.mirror_zone3())
        
        redLine = setupNode(name: R.string.bath.thermometer_line(), parentNode: thermometer)
        var hairs: [Node] = []
        for i in 2...91 {
            hairs.append(setupNode(name: R.string.bath.hair_piece() + String(i)))
        }
        hairPieces = hairs
        
        var coldEffects: [Node] = []
        for i in 1...4 {
            coldEffects.append(setupNode(name: R.string.bath.coldeffect_head() + String(i)))
        }
        coldEffectsHead = coldEffects
        
        coldEffectNose = setupNode(name: R.string.bath.coldeffect_nose())
        
        toothBrush = setupNode(name: R.string.bath.toothbrush(), draggable: true)
        razor = setupNode(name: R.string.bath.razor(), draggable: false)
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
        
        badSpray1 = setupNode(name: R.string.bath.bad_spray1(), parentNode: toiletWater)
        badSpray2 = setupNode(name: R.string.bath.bad_spray2(), parentNode: toiletWater)
        badSpray3 = setupNode(name: R.string.bath.bad_spray3(), parentNode: toiletWater)
        
        goodSpray1 = setupNode(name: R.string.bath.good_spray1(), parentNode: toiletWater)
        goodSpray2 = setupNode(name: R.string.bath.good_spray2(), parentNode: toiletWater)
        goodSpray3 = setupNode(name: R.string.bath.good_spray3(), parentNode: toiletWater)
        
        stick = setupNode(name: R.string.bath.ear_stick())
        stickLeft = setupNode(name: R.string.bath.stick_left(), parentNode: stick)
        stickRight = setupNode(name: R.string.bath.stick_right(), parentNode: stick)
        
        spider = setupNode(name: R.string.bath.spider())
        spiderLegs = setupNode(name: R.string.bath.spider_legs(), parentNode: spider)
        spiderHands = setupNode(name: R.string.bath.spider_hands(), parentNode: spider)
        spiderFace = setupNode(name: R.string.bath.spider_face(), parentNode: spider)
        spiderBody = setupNode(name: R.string.bath.spider_body(), parentNode: spider)
        
        flyAudio = SKAudioNode(fileNamed: R.string.bath.fly_sound())
        flyAudio.autoplayLooped = true
        flyAudio.run(SKAction.changeVolume(to: 0, duration: 0))
        fly.addChild(flyAudio)
    }
}
