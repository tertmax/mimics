//
//  BathState.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 26.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

struct BathState {
    var isTakingDamage: Bool = false
    var isColdWaterOn: Bool = false
    var isHotWaterOn: Bool = false
    var waterTemprature: WaterTemprature {
        if isColdWaterOn && isHotWaterOn {
            return .normal
        }
        if isColdWaterOn && !isHotWaterOn {
            return .cold
        }
        if !isColdWaterOn && isHotWaterOn {
            return .hot
        }
        return .none
    }
    var currentRightHair: SKSpriteNode!
    
    var hairMoveStartLocation: CGPoint?
    let minDistance: CGFloat = 25
    
    var isMouthOpened: Bool = false
    var teethProgress: Int = 6
    var isMouthBusy: Bool = false
    var isMouthFlushing: Bool = false
    
    var isMagentaCupFilled: Bool = false
    var isPurpleCupFilled: Bool = false
    
    var rinsingProgress = 6
    var rinsingReachedUpperBound: Bool = false
    
    var isToothbrushNotInCup: Bool = false
}

enum WaterTemprature {
    case cold
    case hot
    case normal
    case none
}
