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
        let moveDown = SKAction.move(to: rightPointStart, duration: 0)
        let moveLeft = SKAction.move(to: leftPointFinish, duration: 2)
        let moveUp = SKAction.move(to: leftPointStart, duration: 0)
        let flipPause = SKAction.wait(forDuration: 2, withRange: 0)
        
        let playSound = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            self.runFlySound()
        })
        
        let pauseSound = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            self.pauseFlySound()
        })
        
        let flip = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.fly.xScale *= -1
        })
        
        let changeZPos = SKAction.customAction(withDuration: 0, actionBlock: { _,_  in
            a.nodes.fly.zPosition = a.nodes.fly.zPosition == 1 ? -2 : 1
        })
        
        let check = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            fixedSmellCallback()
        })
        
        let flySequence = SKAction.sequence([playSound, moveRight, pauseSound, flip, check,
                                             moveDown, flipPause, check,
                                             flipPause, changeZPos, check, playSound,
                                             moveLeft, pauseSound, flip, changeZPos, check, moveUp,
                                             flipPause, check, flipPause, check])
        
        a.nodes.flyWings.run(SKAction.repeatForever(wingsSequence))
        a.nodes.flyNose.run(SKAction.repeatForever(noseSequence))
        a.nodes.fly.run(SKAction.repeatForever(flySequence))
    }
    
    func runFlySound() {
        let increaseVolume = SKAction.changeVolume(to: 0.02, duration: 0.5)
        let play = SKAction.play()
        animatable?.nodes.flyAudio.run(SKAction.sequence([play, increaseVolume]))
    }
    
    func pauseFlySound() {
        let reduceVolume = SKAction.changeVolume(to: 0, duration: 0.5)
        let pause = SKAction.pause()
        animatable?.nodes.flyAudio.run(SKAction.sequence([reduceVolume, pause]))
    }
    
    func runFallHairPiece(node: Node) {
        guard !node.inUse else { return }
        let sounds = [
            R.string.bath.shave_sound2(),
            R.string.bath.shave_sound5(),
            R.string.bath.shave_sound6()
        ]
        let randomSound = sounds[Int.random(in: 0...2)]
        node.inUse = true
        let randomX = CGFloat.random(in: -50...50)
        let randomAngle = CGFloat.random(in: -4...4)
        let moveDown = SKAction.moveBy(x: randomX, y: -200, duration: 2)
        let rotate = SKAction.rotate(byAngle: randomAngle, duration: 2)
        let moveGroup = SKAction.group([moveDown, rotate])
        let pause = SKAction.wait(forDuration: 1.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let fadeSequence = SKAction.sequence([pause, fade])
        
        if Bool.random() && Bool.random() {
            BaseAnimator.playSound(name: randomSound, node: node)
        }
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
        guard let node = animatable?.nodes.cupMagenta else { return }
        BaseAnimator.changeTexture(node: node, textureName: R.image.bath_cup_magenta_filled.name)
        BaseAnimator.playSound(name: R.string.bath.fill_cup_sound(), node: node)
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

        let height = SKAction.resize(toHeight: a.nodes.thermometer.size.height / 1.2, duration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: a.nodes.thermometer.size.height / 6, duration: 0.5)
        a.nodes.redLine.run(SKAction.group([height,  moveUp]))
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
    
    func runBadSpray(completion: @escaping(() -> Void)) {
        guard let a = animatable else { return }
    
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let pause = SKAction.wait(forDuration: 0.2)
        
        let sequence = SKAction.sequence([fadeIn, pause, fadeOut])
        
        let reset = SKAction.customAction(withDuration: 0, actionBlock: {_,_ in
            completion()
        })
        
        a.nodes.badSpray1.run(sequence)
        a.nodes.badSpray2.run(SKAction.sequence([pause, sequence]))
        a.nodes.badSpray3.run(SKAction.sequence([pause, pause, sequence, reset]))
        
        BaseAnimator.playSound(name: R.string.bath.bad_spray_sound(), node: a.nodes.badSpray1)
    }
    
    func runGoodSpray(completion: @escaping(() -> Void)) {
        guard let a = animatable else { return }
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let pause = SKAction.wait(forDuration: 0.15)
        let check = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            completion()
        })

        let sequence = SKAction.sequence([fadeIn, pause, fadeOut])
        
        a.nodes.goodSpray1.run(SKAction.sequence([sequence]))
        a.nodes.goodSpray2.run(SKAction.sequence([pause, pause, sequence]))
        a.nodes.goodSpray3.run(SKAction.sequence([pause, pause, pause, pause, sequence, check]))
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
        
        let fly = a.nodes.fly
        
        var startPoint = CGPoint(x: fly.position.x, y: -50)
        if fly.position.x < 0 {
            startPoint.x -= 100
        } else {
            startPoint.x += 100
        }
        
        fly.position = startPoint
        
        let flip = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            fly.xScale *= -1
        })
        
        fly.removeAllActions()
        fly.zPosition = 4
        
        let firstMove = SKAction.moveTo(y: firstRoutePointY, duration: 1)
        firstMove.timingMode = .easeInEaseOut
        
        let secondMove = SKAction.moveTo(y: secondRoutePointY, duration: 0.5)
        secondMove.timingMode = .easeInEaseOut
        
        let thirdMove = SKAction.moveTo(y: endPoint.y, duration: 1)
        thirdMove.timingMode = .easeInEaseOut
        
        let ySequence = SKAction.sequence([firstMove, secondMove, thirdMove])
        
        let xAction = SKAction.moveTo(x: endPoint.x + 50, duration: 2.5)
        
        let attachToRazor = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            fly.removeFromParent()
            a.nodes.razor.addChild(fly)
            fly.position = .zero
            fly.position.x = -70
            fly.position.y = -a.nodes.razor.size.height * 1.5
            fly.xScale = fly.initXScale * 4
            fly.yScale = fly.initYScale * 4
            fly.zRotation = -1.5
            reachedRazorCallback()
        })
        
        let yAction = SKAction.moveTo(y: endPoint.y, duration: 2.5)
        
        let firstMoveXFromLeft = SKAction.moveTo(x: 0, duration: 1.5)
        firstMoveXFromLeft.timingMode = .easeInEaseOut
        
        let secondMoveXFromLeft = SKAction.moveTo(x: endPoint.x + 100, duration: 1)
        secondMoveXFromLeft.timingMode = .easeInEaseOut
        
        let xSequence = SKAction.sequence([firstMoveXFromLeft, flip, secondMoveXFromLeft])
        
        let playSound = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            self.runFlySound()
        })
        
        let pauseSound = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            self.pauseFlySound()
        })
        
        let moveFromRight = SKAction.sequence([playSound, SKAction.group([xAction, ySequence]), attachToRazor, pauseSound])
        let moveFromLeft = SKAction.sequence([playSound, SKAction.group([yAction, xSequence]), attachToRazor, pauseSound])
        
        if fly.position.x > 0 {
            fly.run(moveFromRight)
        } else {
            fly.run(moveFromLeft)
        }
    }
    
    func runDropRazor(completion: @escaping(() -> Void)) {
        guard let a = animatable else { return }
        let razor = a.nodes.razor
        let endY = a.nodes.bandage.position.y
        
        
        let delta: CGFloat = 1.587 - razor.zRotation
        let moveDown1 = SKAction.move(to: CGPoint(x: a.nodes.bandage.position.x / 2, y: endY + 10), duration: 1)
        let rotate1 = SKAction.rotate(byAngle: -6.2 + delta, duration: 1)
        
        let pause = SKAction.wait(forDuration: 0.3)
        
        let sound = BaseAnimator.AnimationActions.sound(name: R.string.bath.land_sound()).action
        
        let completion = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            completion()
        })
        
        let dropGroup = SKAction.group([moveDown1, rotate1])
        
        razor.run(SKAction.sequence([dropGroup, pause, sound, completion]))
    }
    
    func runFlyMoveToSpider(completion: @escaping(() -> Void)) {
        guard let a = animatable else { return }
        
        let fly = a.nodes.fly
        let end = a.nodes.spider.position
        let moveX = SKAction.moveTo(x: end.x, duration: 3.5)
        
        let moveY1 = SKAction.moveTo(y: fly.position.y - 30, duration: 0.5)
        moveY1.timingMode = .easeInEaseOut
        
        let moveY2 = SKAction.moveTo(y: 0, duration: 2)
        moveY2.timingMode = .easeInEaseOut
        
        let moveY3 = SKAction.moveTo(y: end.y - 30, duration: 1)
        moveY3.timingMode = .easeInEaseOut
        
        let shakeWeb = SKAction.scale(by: 1.1, duration: 0.3)
        let shakeWeb2 = SKAction.scale(by: 0.909, duration: 0.3)
        let webSequence = SKAction.sequence([shakeWeb, shakeWeb2])
        
        let completion = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.web.run(webSequence)
            completion()
        })
        
        let playSound = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            self.runFlySound()
        })
        
        let pauseSound = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            self.pauseFlySound()
        })
        
        let moveYSequence = SKAction.sequence([moveY1, moveY2, moveY3, completion])
        
        fly.run(SKAction.sequence([playSound, SKAction.group([moveX, moveYSequence]), pauseSound]) )
    }
    
    func runFallStick(completion: @escaping(() -> Void)) {
        guard let a = animatable else { return }
    
        var end = a.nodes.towel.initPoint
        end.x *= -1.3
        end.y -= 50
        let moveDown = SKAction.move(to: end, duration: 2)
        let rotate = SKAction.rotate(byAngle: 9.5, duration: 2)
        let completion = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            completion()
        })
        
        let fall = SKAction.group([moveDown, rotate])
        
        a.nodes.stick.run(SKAction.sequence([fall, completion]))
    }
    
    func runHeart() {
        guard let a = animatable else { return }
        guard !a.nodes.heart1.hasActions() else { return }
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let pause = SKAction.wait(forDuration: 0.7)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let pause2 = SKAction.wait(forDuration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 1.4)
        
        let reset1 = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.heart1.reset()
        })
        let reset2 = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.heart2.reset()
        })
        let reset3 = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.heart3.reset()
        })
        
        let fade = SKAction.sequence([fadeIn, pause, fadeOut])
        let moveHeart = SKAction.group([fade, moveUp])
        
        a.nodes.heart1.run(SKAction.sequence([pause2, pause2, moveHeart, reset1]))
        a.nodes.heart2.run(SKAction.sequence([moveHeart, reset2]))
        a.nodes.heart3.run(SKAction.sequence([pause2, moveHeart, reset3]))
    }
    
    func runAngrySpider() {
        guard let a = animatable else { return }
        
        let angry = Int(a.nodes.spiderHands.position.y) != Int(a.nodes.spiderHands.initPoint.y)
        
        let changeTexture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_spider_face_angry.name))
        let changeTextureBack = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_spider_face_default.name))
        let moveDownHands = SKAction.moveBy(x: 0, y: angry ? 0 : -12, duration: 0.3)
        let moveUpHands = SKAction.moveBy(x: 0, y: angry ? 0 : 12, duration: 0.3)
        let moveDownBody = SKAction.moveBy(x: 0, y: angry ? 0 : -7, duration: 0.3)
        let moveUpBody = SKAction.moveBy(x: 0, y: angry ? 0 : 7, duration: 0.3)
        let moveDownFace = SKAction.moveBy(x: 0, y: angry ? 0 : -5, duration: 0.3)
        let moveUpFace = SKAction.moveBy(x: 0, y: angry ? 0 : 5, duration: 0.3)
        let pause = SKAction.wait(forDuration: 1)
        
        let texture = SKAction.sequence([changeTexture, pause, changeTextureBack])
        let face = SKAction.sequence([moveDownFace, pause, moveUpFace])
        let hands = SKAction.sequence([moveDownHands, pause, moveUpHands])
        let body = SKAction.sequence([moveDownBody, pause, moveUpBody])
        
        a.nodes.spiderBody.run(body)
        a.nodes.spiderFace.run(texture)
        a.nodes.spiderFace.run(face)
        a.nodes.spiderHands.run(hands)
        
        if !angry {
            BaseAnimator.playSound(name: R.string.bath.angry_spider_sound(), node: a.nodes.spider)
        }
    }
    
    func runCleanEar(left: Bool, completion: @escaping(() -> Void)) {
        guard let a = animatable else { return }
        guard !a.nodes.stick.hasActions() else { return }
        let rotate1 = SKAction.rotate(byAngle: 0.3, duration: 0.2)
        let rotate2 = SKAction.rotate(byAngle: -0.6, duration: 0.2)
        let rotate3 = SKAction.rotate(byAngle: 0.3, duration: 0.2)
        let finish = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            if left {
                let texture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_stick_right_dirty.name))
                a.nodes.stickRight.run(texture)
            } else {
                let texture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_stick_left_dirty.name))
                a.nodes.stickLeft.run(texture)
            }
            completion()
        })
        
        a.nodes.stick.run(SKAction.sequence([rotate1, rotate2, rotate3, finish]))
    }
    
    func runCloseShirt() {
        guard let a = animatable else { return }
        BaseAnimator.fadeIn(nodes: [a.nodes.shirtFixed], duration: 0)
        BaseAnimator.fadeOut(nodes: [a.nodes.shirtInitial], duration: 0)
    }
    
    func runOpenShirt() {
        guard let a = animatable else { return }
        BaseAnimator.fadeOut(nodes: [a.nodes.shirtFixed], duration: 0)
        BaseAnimator.fadeIn(nodes: [a.nodes.shirtInitial], duration: 0)
    }
    
    func runPinchPimple1() {
        guard let a = animatable else { return }
        BaseAnimator.swapNodes(oldNode: a.nodes.pimple1Initial, newNode: a.nodes.pimple1Bleeidng, duration: 0.5)
        runDamage()
        BaseAnimator.playSound(name: R.string.bath.pimple1_sound(), node: a.nodes.pimple1Bleeidng)
    }
    
    func runPinchPimple2() {
        guard let a = animatable else { return }
        BaseAnimator.fadeOut(nodes: [a.nodes.pimple2], duration: 0.5)
        BaseAnimator.playSound(name: R.string.bath.pimple2_sound(), node: a.nodes.pimple2)
    }
    
    func runPinchPimple3() {
        guard let a = animatable else { return }
        BaseAnimator.fadeOut(nodes: [a.nodes.pimple3], duration: 0.5)
        BaseAnimator.playSound(name: R.string.bath.pimple2_sound(), node: a.nodes.pimple3)
    }
}
