//
//  WarehouseAnimator.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 27.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

protocol WarehouseAnimatable: class {
    var nodes: WarehouseNodes! { get }
    var state: WarehouseState { get set }
}

class WarehouseAnimator {
    
    weak var animatable: WarehouseAnimatable?
    
    init(animatable: WarehouseAnimatable) {
        self.animatable = animatable
    }
    
    func runMoveBackground(newX: CGFloat) {
        guard let a = animatable else { return }
        let move = SKAction.moveTo(x: newX, duration: 0.1)
        a.nodes.background.run(move)
    }
    
    func runMoveFlashlightX(node: SKShapeNode, x: CGFloat) {
        let move = SKAction.moveTo(x: x, duration: 0.1)
        node.run(move)
    }
    
    func runMoveFlashlightY(node: SKShapeNode, y: CGFloat) {
        let move = SKAction.moveTo(y: y, duration: 0.1)
        node.run(move)
    }
    
    func runMouseWalking() {
        guard let a = animatable else { return }
        
        let changeTexture1 = SKAction.setTexture(SKTexture(imageNamed: R.image.wh_mouse1.name))
        let changeTexture2 = SKAction.setTexture(SKTexture(imageNamed: R.image.wh_mouse2.name))
        let changeTexture3 = SKAction.setTexture(SKTexture(imageNamed: R.image.wh_mouse3.name))
        let changeTexture4 = SKAction.setTexture(SKTexture(imageNamed: R.image.wh_mouse4.name))
        let changeTexture5 = SKAction.setTexture(SKTexture(imageNamed: R.image.wh_mouse5.name))
        
        let framePause = SKAction.wait(forDuration: 0.1)
        
        let frame1 = SKAction.sequence([changeTexture1, framePause])
        let frame2 = SKAction.sequence([changeTexture2, framePause])
        let frame3 = SKAction.sequence([changeTexture3, framePause])
        let frame4 = SKAction.sequence([changeTexture4, framePause])
        let frame5 = SKAction.sequence([changeTexture5, framePause])
        
        let framesSequence = SKAction.sequence([frame2, frame3, frame4, frame5, frame1])
        
        let moveRight = SKAction.moveBy(x: 150, y: 0, duration: 0.4)
        let moveLeft = SKAction.moveBy(x: -150, y: 0, duration: 0.4)
        
        let moveRightGroup = SKAction.group([framesSequence, moveRight, framePause, framePause])
        let moveLeftGroup = SKAction.group([framesSequence, moveLeft, framePause, framePause])
        
        let flip = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            a.nodes.mouse.xScale *= -1
        })
        
        let repeatMoveRight = SKAction.repeat(moveRightGroup, count: 6)
        let repeatMoveLeft = SKAction.repeat(moveLeftGroup, count: 6)
        let action = SKAction.sequence([repeatMoveRight, flip, framePause, framePause,
                                        repeatMoveLeft, flip, framePause, framePause])
        a.nodes.mouse.run(SKAction.repeatForever(action))
    }
    
    func runCandleFire() {
        guard let a = animatable else { return }
        let framesAction = BaseAnimator.AnimationActions.frameChange(textures: [
            SKTexture(imageNamed: R.image.wh_candle_fire2.name),
            SKTexture(imageNamed: R.image.wh_candle_fire3.name),
            SKTexture(imageNamed: R.image.wh_candle_fire4.name),
            SKTexture(imageNamed: R.image.wh_candle_fire1.name)
        ], pause: 0.1).action
        a.nodes.candleFire.run(SKAction.repeatForever(framesAction))
    }
}

