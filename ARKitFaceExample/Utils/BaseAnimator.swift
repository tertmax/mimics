//
//  BaseAnimator.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 27.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

class BaseAnimator {
    
    class func swapNodes(oldNode: SKSpriteNode, newNode: SKSpriteNode, duration: TimeInterval = 0.0) {
        fadeOut(nodes: [oldNode], duration: duration)
        fadeIn(nodes: [newNode], duration: duration)
    }
    
    class func fadeIn(nodes: [SKSpriteNode], duration: TimeInterval) {
        let fadeIn = AnimationActions.fadeIn(duration: duration).action
        for node in nodes {
            node.run(fadeIn)
        }
    }
    
    class func fadeOut(nodes: [SKSpriteNode], duration: TimeInterval) {
        let fadeOut = AnimationActions.fadeOut(duration: duration).action
        for node in nodes {
            node.run(fadeOut)
        }
    }
    
    class func changeAlpha(nodes: [SKSpriteNode], alpha: CGFloat, duration: TimeInterval) {
        let changeAlpha = AnimationActions.changeAlpha(by: alpha, duration: duration).action
        for node in nodes {
            node.run(changeAlpha)
        }
    }
    
    class func changeTexture(node: SKSpriteNode?, textureName: String) {
        let changeTexture = AnimationActions.setTexture(textureName: textureName).action
        node?.run(changeTexture)
    }
}

private extension BaseAnimator {
    enum AnimationActions {
        case fadeIn(duration: TimeInterval)
        case fadeOut(duration: TimeInterval)
        case changeAlpha(by: CGFloat, duration: TimeInterval)
        case setTexture(textureName: String)
        case rotateBy(angle: CGFloat, duration: TimeInterval)
        
        var action: SKAction {
            switch self {
            case .fadeIn(let duration):
                return SKAction.fadeIn(withDuration: duration)
            case .fadeOut(let duration):
                return SKAction.fadeOut(withDuration: duration)
            case .changeAlpha(let step, let duration):
                return SKAction.fadeAlpha(by: step, duration: duration)
            case .setTexture(let textureName):
                return SKAction.setTexture(SKTexture(imageNamed: textureName))
            case .rotateBy(let angle, let duration):
                return SKAction.rotate(byAngle: angle, duration: duration)
            }
        }
    }
}
