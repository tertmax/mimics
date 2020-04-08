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
        
        BaseAnimator.fadeIn(nodes: [a.nodes.water], duration: 0.3)
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
    
    func runFlyMovement(fixedSmellCallback: @escaping(() -> Void)) {
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
        
//        let pause = SKAction.wait(forDuration: 4)
        
        let flip = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.fly.xScale *= -1
        })
        
        let changeZPos = SKAction.customAction(withDuration: 0, actionBlock: { _,_  in
            a.nodes.fly.zPosition = a.nodes.fly.zPosition == 0 ? -2 : 0
        })
        
        let check = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            fixedSmellCallback()
        })
        
        let flySequence = SKAction.sequence([moveRight, moveDown, changeZPos, flip, check,
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
    
    func runSpitAnimation(completion: @escaping(() -> Void)) {
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let pause = SKAction.wait(forDuration: 0.3)
        let releaseMouth = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            completion()
        })
        
        let sequence = SKAction.sequence([fadeIn, pause, fadeOut])
        
        animatable?.nodes.leftCheek.run(fadeOut)
        animatable?.nodes.rightCheek.run(fadeOut)
        animatable?.nodes.fallingWater1.run(sequence)
        animatable?.nodes.fallingWater2.run(SKAction.sequence([pause, sequence]))
        animatable?.nodes.fallingWater3.run(SKAction.sequence([pause, pause, sequence, releaseMouth]))
    }
    
    func runRotateColdValve(angle: CGFloat) {
        let rotate = SKAction.rotate(byAngle: angle, duration: 0.5)
        animatable?.nodes.coldValve.run(rotate)
    }
    
    func runRotateHotValve(angle: CGFloat) {
        let rotate = SKAction.rotate(byAngle: angle, duration: 0.5)
        animatable?.nodes.hotValve.run(rotate)
    }
    
    func runSteam() {
        let scale = SKAction.scale(to: 1.5, duration: 2)
        let appear = SKAction.fadeAlpha(to: 1, duration: 0.8)
        let fade = SKAction.fadeAlpha(to: 0, duration: 0.8)
        let resetScale = SKAction.scale(to: 1, duration: 0)
        let pause = SKAction.wait(forDuration: 2)
        let appearGroup = SKAction.group([scale, appear])
        let sequence = SKAction.sequence([appearGroup,fade, resetScale])
        animatable?.nodes.steam1.run(SKAction.repeatForever(sequence))
        animatable?.nodes.steam2.run(SKAction.repeatForever(SKAction.sequence([pause, sequence])))
        animatable?.nodes.steam3.run(SKAction.repeatForever(SKAction.sequence([pause, pause, sequence])))
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
        BaseAnimator.changeTexture(node: animatable?.nodes.crane, textureName: R.image.bath_tap_crane_cold.name)
    }
    
    func runDefaultCrane() {
        BaseAnimator.changeTexture(node: animatable?.nodes.crane, textureName: R.image.bath_tap_crane_default.name)
    }
    
    func runFillCup() {
        BaseAnimator.changeTexture(node: animatable?.nodes.cupMagenta, textureName: R.image.bath_cup_magenta_filled.name)
    }
    
    func runPutWaterInMouth() {
        BaseAnimator.changeTexture(node: animatable?.nodes.cupMagenta, textureName: R.image.bath_cup_magenta.name)
    }
    
    func runRemovePaste() {
        BaseAnimator.changeTexture(node: animatable?.nodes.toothBrush, textureName: R.image.bath_toothbrush.name)
    }
    
    func runCleanTeeth() {
        BaseAnimator.changeTexture(node: animatable?.nodes.jawTop, textureName: R.image.bath_jaw_top_fixed.name)
        BaseAnimator.changeTexture(node: animatable?.nodes.jawBottom, textureName: R.image.bath_jaw_bottom_fixed.name)
    }
    
    func runWetTowel() {
        BaseAnimator.changeTexture(node: animatable?.nodes.towel, textureName: R.image.bath_towel_wet.name)
    }

    func runUpdateDirtAlpha() {
        guard let a = animatable else { return }
        guard a.nodes.dirt.alpha > 0 else { return }
        BaseAnimator.changeAlpha(nodes: [a.nodes.dirt], alpha: -0.2, duration: 0.2)
    }
    
    func runShowBlur(node: SKCropNode) {
        guard node.alpha == 0 else { return }
        BaseAnimator.fadeIn(nodes: [node], duration: 2)
    }
    
    func runHideBlur(node: SKCropNode) {
        guard node.alpha == 1 else { return }
        BaseAnimator.fadeOut(nodes: [node], duration: 1)
    }
    
    func runRazorInUse() {
        guard let a = animatable else { return }
        let changeTexture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_razor_inuse.name))
        let rotate = SKAction.rotate(toAngle: 0, duration: 0)
        
        a.nodes.razor.run(changeTexture)
        a.nodes.razor.run(rotate)
    }
    
    func runHeatCharacter(completion: @escaping (() -> Void)) {
        guard let a = animatable else { return }
        var coldNodes = a.nodes.coldEffectsHead
        coldNodes.append(a.nodes.coldEffectNose)
        BaseAnimator.fadeOut(nodes: coldNodes, duration: 1)
        BaseAnimator.fadeOut(nodes: [a.nodes.mouthCold], duration: 0)
        BaseAnimator.fadeIn(nodes: [a.nodes.mouthDefault], duration: 0, completion: completion)
    }
    
    func runFreezeEffects() {
        guard let a = animatable else { return }
        let scaleDown = BaseAnimator.AnimationActions.scale(to: 0.8, duration: 0.5).action
        let scaleUp = BaseAnimator.AnimationActions.scale(to: 1.2, duration: 0.5).action
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        let repeatSequence = SKAction.repeatForever(sequence)
        for node in a.nodes.coldEffectsHead {
            node.run(repeatSequence)
        }
    }
    
    func runBadSpray(completion: (() -> Void)) {
        guard let a = animatable else { return }
        let deodorantNode = a.nodes.toiletWater
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let pause = SKAction.wait(forDuration: 0.2)
        
        let sequence = SKAction.sequence([fadeIn, pause, fadeOut])
        
        let reset = SKAction.customAction(withDuration: 0, actionBlock: {_,_ in
            deodorantNode.needsReset = true
            deodorantNode.reset()
        })
        
        a.nodes.badSpray1.run(sequence)
        a.nodes.badSpray2.run(SKAction.sequence([pause, sequence]))
        a.nodes.badSpray3.run(SKAction.sequence([pause, pause, sequence, reset]))

    }
    
    func runGoodSpray(completion: @escaping(() -> Void)) {
        guard let a = animatable else { return }
        var count = 1
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let pause = SKAction.wait(forDuration: 0.15)
        let check = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            if !a.nodes.toiletWater.isContactingWith(a.nodes.shirtZone) {
                self.stopGoodSpray()
            } else if count > 0 {
                count -= 1
            } else if count == 0 {
                self.stopGoodSpray()
                completion()
            }
        })

        let sequence = SKAction.sequence([fadeIn, pause, fadeOut])
        
        a.nodes.goodSpray1.run(SKAction.repeatForever(SKAction.sequence([sequence, pause, pause, pause, pause])))
        a.nodes.goodSpray2.run(SKAction.repeatForever(SKAction.sequence([pause, pause, sequence, pause, pause])))
        a.nodes.goodSpray3.run(SKAction.repeatForever(SKAction.sequence([pause, pause, pause, pause, sequence, check])))
    }
    
    func stopGoodSpray() {
        guard let a = animatable else { return }
        a.nodes.goodSpray1.removeAllActions()
        a.nodes.goodSpray2.removeAllActions()
        a.nodes.goodSpray3.removeAllActions()
        
        BaseAnimator.fadeOut(nodes: [a.nodes.goodSpray1, a.nodes.goodSpray2, a.nodes.goodSpray3], duration: 0.1)
    }
    
    func runFlyMoveToRazor(reachedRazorCallback: @escaping(() -> Void)) {
        guard let a = animatable else { return }
        let endPoint = a.nodes.razor.position
        
        let firstRoutePointY = endPoint.y / 3
        let secondRoutePointY = endPoint.y / 4
        
        a.nodes.fly.removeAllActions()
        a.nodes.fly.zPosition = 4
        
        let firstMove = SKAction.moveTo(y: firstRoutePointY, duration: 1)
        firstMove.timingMode = .easeInEaseOut
        
        let secondMove = SKAction.moveTo(y: secondRoutePointY, duration: 0.5)
        secondMove.timingMode = .easeInEaseOut
        
        let thirdMove = SKAction.moveTo(y: endPoint.y, duration: 1)
        thirdMove.timingMode = .easeInEaseOut
        
        let ySequence = SKAction.sequence([firstMove, secondMove, thirdMove])
        
        let xAction = SKAction.moveTo(x: endPoint.x + 100, duration: 2.5)
        
        let attachToRazor = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            let fly = a.nodes.fly
            fly.removeFromParent()
            a.nodes.razor.addChild(fly)
            fly.position = .zero
            fly.position.x = -70
            fly.position.y = -a.nodes.razor.size.height * 1.5
            fly.xScale = fly.initXScale * 3
            fly.yScale = fly.initYScale * 3
            fly.zRotation = -1.5
            reachedRazorCallback()
        })
        
        a.nodes.fly.run(SKAction.sequence([SKAction.group([xAction, ySequence]), attachToRazor]))
    }
    
    func runDropRazor(completion: @escaping(() -> Void)) {
        guard let a = animatable else { return }
        let razor = a.nodes.razor
        let endY = a.nodes.bandage.position.y
        
        let moveDown1 = SKAction.move(to: CGPoint(x: a.nodes.bandage.position.x / 2, y: endY + 10), duration: 1)
        let rotate1 = SKAction.rotate(byAngle: -6.2, duration: 1)
        
        let pause = SKAction.wait(forDuration: 0.3)
        
        
        let completion = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            completion()
        })
        
        let dropGroup = SKAction.group([moveDown1, rotate1])
        
        razor.run(SKAction.sequence([dropGroup, pause, completion]))
    }
}
