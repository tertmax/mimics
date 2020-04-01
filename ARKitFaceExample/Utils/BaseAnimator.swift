//
//  BaseAnimator.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 27.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

class BaseAnimator {
    
    class func swapNodes(oldNode: SKNode, newNode: SKNode, duration: TimeInterval = 0.0) {
        fadeOut(nodes: [oldNode], duration: duration)
        fadeIn(nodes: [newNode], duration: duration)
    }
    
    class func fadeIn(nodes: [SKNode], duration: TimeInterval, completion: (() -> Void)? = nil) {
        let fadeIn = AnimationActions.fadeIn(duration: duration, completion: completion).action
        for node in nodes {
            node.run(fadeIn)
        }
    }
    
    class func fadeOut(nodes: [SKNode], duration: TimeInterval, completion: (() -> Void)? = nil) {
        let fadeOut = AnimationActions.fadeOut(duration: duration, completion: completion).action
        for node in nodes {
            node.run(fadeOut)
        }
    }
    
    class func changeAlpha(nodes: [SKNode], alpha: CGFloat, duration: TimeInterval) {
        let changeAlpha = AnimationActions.changeAlpha(by: alpha, duration: duration).action
        for node in nodes {
            node.run(changeAlpha)
        }
    }
    
    class func changeTexture(node: SKSpriteNode?, textureName: String) {
        let changeTexture = AnimationActions.setTexture(textureName: textureName).action
        node?.run(changeTexture)
    }
    
    class func scale(nodes: [SKNode], to scale: CGFloat, duration: TimeInterval) {
        let scale = AnimationActions.scale(to: scale, duration: duration).action
        for node in nodes {
            node.run(scale)
        }
    }
}

extension BaseAnimator {
    enum AnimationActions {
        case fadeIn(duration: TimeInterval, completion: (() -> Void)? = nil)
        case fadeOut(duration: TimeInterval, completion: (() -> Void)? = nil)
        case changeAlpha(by: CGFloat, duration: TimeInterval)
        case setTexture(textureName: String)
        case rotateBy(angle: CGFloat, duration: TimeInterval)
        case scale(to: CGFloat, duration: TimeInterval)
        
        var action: SKAction {
            switch self {
            case .fadeIn(let duration, let completion):
                let fadeIn = SKAction.fadeIn(withDuration: duration)
                let completion = SKAction.customAction(withDuration: 0, actionBlock: { _, _ in
                    completion?()
                })
                return SKAction.sequence([fadeIn, completion])
            case .fadeOut(let duration, let completion):
                let fadeOut = SKAction.fadeOut(withDuration: duration)
                let completion = SKAction.customAction(withDuration: 0, actionBlock: { _, _ in
                    completion?()
                })
                return SKAction.sequence([fadeOut, completion])
            case .changeAlpha(let step, let duration):
                return SKAction.fadeAlpha(by: step, duration: duration)
            case .setTexture(let textureName):
                return SKAction.setTexture(SKTexture(imageNamed: textureName))
            case .rotateBy(let angle, let duration):
                return SKAction.rotate(byAngle: angle, duration: duration)
            case .scale(let scale, let duration):
                return SKAction.scale(to: scale, duration: duration)
            }
        }
    }
    
}
