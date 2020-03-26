//
//  BathAnimator.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 26.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

protocol BathAnimatable: class {
    var nodes: BathNodes! { get }
    var state: BathState { get set }
}

class BathAnimator {
    
    weak var animatable: BathAnimatable?
    
    init(animatable: BathAnimatable) {
        self.animatable = animatable
    }
    
    func runDamage() {
        guard let a = animatable else { return }
        guard !a.state.isTakingDamage else { return }
        a.state.isTakingDamage = true
        let changeTexture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_eyes_damaged.name))
        let changeTextureBack = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_eyes_default.name))
        let pause = SKAction.wait(forDuration: 1)
        let returnToDefaultState = SKAction.customAction(withDuration: 0.0, actionBlock: { _,_ in
            a.nodes.leftEyeBall.isHidden = false
            a.nodes.rightEyeBall.isHidden = false
            a.state.isTakingDamage = false
        })
        
        let rotateClockwise = SKAction.rotate(byAngle: 0.3, duration: 0)
        let rotateOppositClockwise = SKAction.rotate(byAngle: -0.3, duration: 0)
        
        let leftBrowSequence = SKAction.sequence([rotateOppositClockwise, pause, rotateClockwise])
        let rightBrowSequence = SKAction.sequence([rotateClockwise, pause, rotateOppositClockwise])
        
        a.nodes.leftBrow.run(leftBrowSequence)
        a.nodes.rightBrow.run(rightBrowSequence)
        
        a.nodes.leftEyeBall.isHidden = true
        a.nodes.rightEyeBall.isHidden = true
        
        let eyesSequence = SKAction.sequence([changeTexture, pause, changeTextureBack, returnToDefaultState])
        a.nodes.eyes.run(eyesSequence)
    }
    
    func runSinkWater() {
        guard let a = animatable else { return }
        guard !a.nodes.water.hasActions() else { return }
        let changeTexture1 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_water2.name))
        let changeTexture2 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_water3.name))
        let changeTexture3 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_water1.name))
        let pause = SKAction.wait(forDuration: 0.15)
        let sequence = SKAction.sequence([changeTexture1, pause, changeTexture2, pause, changeTexture3, pause])
        
        a.nodes.water.run(SKAction.repeatForever(sequence))
        
        fadeIn(nodes: [a.nodes.water], duration: 0.3)
    }
    
    func stopSinkWater() {
        guard let a = animatable else { return }
        guard a.nodes.water.hasActions() else { return }
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let removeActions = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.water.removeAllActions()
        })
        a.nodes.water.run(SKAction.sequence([fadeOut, removeActions]))
    }
    
    func runFlyMovement() {
        guard let a = animatable else { return }
        let changeWings1 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_fly_wings_2.name))
        let changeWings2 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_fly_wings_1.name))
        let pause = SKAction.wait(forDuration: 0.1)
        let wingsSequence = SKAction.sequence([pause, changeWings1, pause, changeWings2])
        
        let noseScale1 = SKAction.scale(to: 1.6, duration: 0.5)
        let noseScale2 = SKAction.scale(to: 1, duration: 0.5)
        let noseSequence = SKAction.sequence([noseScale1, noseScale2])
        
        let leftPointStart = a.nodes.fly.initPoint
        let leftPointFinish = CGPoint(x: leftPointStart.x, y: leftPointStart.y - 130)
        let rightPointStart = CGPoint(x: -leftPointStart.x, y: leftPointStart.y - 130)
        let rightPointFinish = CGPoint(x: -leftPointStart.x, y: leftPointStart.y)
        
        let moveRight = SKAction.move(to: rightPointFinish, duration: 2)
        let moveDown = SKAction.move(to: rightPointStart, duration: 4)
        let moveLeft = SKAction.move(to: leftPointFinish, duration: 2)
        let moveUp = SKAction.move(to: leftPointStart, duration: 4)
        
        let flip = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.fly.xScale *= -1
        })
        
        let changeZPos = SKAction.customAction(withDuration: 0, actionBlock: { _,_  in
            a.nodes.fly.zPosition = a.nodes.fly.zPosition == 0 ? -2 : 0
        })
        
        let flySequence = SKAction.sequence([moveRight, moveDown, changeZPos, flip,
                                             moveLeft, moveUp, flip, changeZPos])
        
        a.nodes.flyWings.run(SKAction.repeatForever(wingsSequence))
        a.nodes.flyNose.run(SKAction.repeatForever(noseSequence))
        a.nodes.fly.run(SKAction.repeatForever(flySequence))
    }
    
    func runFallHairPiece(node: Node) {
        guard !node.inUse else { return }
        node.inUse = true
        let randomX = CGFloat.random(in: -50...50)
        let randomAngle = CGFloat.random(in: -4...4)
        let moveDown = SKAction.moveBy(x: randomX, y: -200, duration: 2)
        let rotate = SKAction.rotate(byAngle: randomAngle, duration: 2)
        let moveGroup = SKAction.group([moveDown, rotate])
        let pause = SKAction.wait(forDuration: 1.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let fadeSequence = SKAction.sequence([pause, fade])
        
        node.run(SKAction.group([moveGroup, fadeSequence]))
    }
    
    func runSpitAnimation() {
        guard let a = animatable else { return }
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let pause = SKAction.wait(forDuration: 0.3)
        let releaseMouth = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.state.isMouthBusy = false
        })
        
        let sequence = SKAction.sequence([fadeIn, pause, fadeOut])
        
        a.nodes.leftCheek.run(fadeOut)
        a.nodes.rightCheek.run(fadeOut)
        a.nodes.fallingWater1.run(sequence)
        a.nodes.fallingWater2.run(SKAction.sequence([pause, sequence]))
        a.nodes.fallingWater3.run(SKAction.sequence([pause, pause, sequence, releaseMouth]))
    }
    
    func runRotateColdValve(angle: CGFloat) {
        guard let a = animatable else { return }
        let rotate = SKAction.rotate(byAngle: angle, duration: 0.5)
        a.nodes.coldValve.run(rotate)
    }
    
    func runRotateHotValve(angle: CGFloat) {
        guard let a = animatable else { return }
        let rotate = SKAction.rotate(byAngle: angle, duration: 0.5)
        a.nodes.hotValve.run(rotate)
    }
    
    func runSteam() {
        guard let a = animatable else { return }
        let scale = SKAction.scale(to: 1.5, duration: 2)
        let appear = SKAction.fadeAlpha(to: 1, duration: 0.8)
        let fade = SKAction.fadeAlpha(to: 0, duration: 0.8)
        let resetScale = SKAction.scale(to: 1, duration: 0)
        let pause = SKAction.wait(forDuration: 2)
        let appearGroup = SKAction.group([scale, appear])
        let sequence = SKAction.sequence([appearGroup,fade, resetScale])
        a.nodes.steam1.run(SKAction.repeatForever(sequence))
        a.nodes.steam2.run(SKAction.repeatForever(SKAction.sequence([pause, sequence])))
        a.nodes.steam3.run(SKAction.repeatForever(SKAction.sequence([pause, pause, sequence])))
    }
    
    func stopSteam() {
        guard let a = animatable else { return }
        guard a.nodes.steam1.hasActions() else { return }
        let steamNodes = [a.nodes.steam1, a.nodes.steam2, a.nodes.steam3]
        for steam in steamNodes {
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let removeActions = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
                steam.removeAllActions()
            })
            steam.run(SKAction.sequence([fadeOut, removeActions]))
        }
    }
    
    func runColdCrane() {
        guard let a = animatable else { return }
        let coldCraneAction = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_crane_cold.name))
        a.nodes.crane.run(coldCraneAction)
    }
    
    func runDefaultCrane() {
        guard let a = animatable else { return }
        let defaultCraneAction = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_crane_default.name))
        a.nodes.crane.run(defaultCraneAction)
    }
    
    func swapNodes(oldNode: SKSpriteNode, newNode: SKSpriteNode, duration: TimeInterval = 0.0) {
        fadeOut(nodes: [oldNode], duration: duration)
        fadeIn(nodes: [newNode], duration: duration)
    }
    
    func fadeIn(nodes: [SKSpriteNode], duration: TimeInterval) {
        let fadeIn = SKAction.fadeIn(withDuration: duration)
        for node in nodes {
            node.run(fadeIn)
        }
    }
    
    func fadeOut(nodes: [SKSpriteNode], duration: TimeInterval) {
        let fadeOut = SKAction.fadeOut(withDuration: duration)
        for node in nodes {
            node.run(fadeOut)
        }
    }
    
    func runFillCup() {
        guard let a = animatable else { return }
        let changeTexture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_cup_magenta_filled.name))
        a.nodes.cupMagenta.run(changeTexture)
    }
    
    func runPutWaterInMouth() {
        guard let a = animatable else { return }
        let cupChangeTexture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_cup_magenta.name))
        a.nodes.cupMagenta.run(cupChangeTexture)
    }
    
}
