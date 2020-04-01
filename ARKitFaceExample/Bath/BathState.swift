//
//  BathState.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 26.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

struct BathState {
    var isBlurInitiallySetUp: Bool = false
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
    var hairMoveStart: (point: CGPoint, time: TimeInterval)?
    var dirtMoveStart: (point: CGPoint, time: TimeInterval)?
    let minDistance: CGFloat = 50
    let minSpeed: CGFloat = 400
    
    var isCharacterFreezing: Bool = true
    
    var isMouthOpened: Bool = false
    var teethProgress: Int = 6
    var isMouthBusy: Bool {
        return isCharacterFreezing || teethState == .needsRinsing
    }
    var isMouthFlushing: Bool = false
    var teethState: TeethState {
        if teethProgress == 0 {
            return .needsRinsing
        }
        if teethProgress < 0 {
            return .fixed
        }
        return .dirty
    }
    
    var isMagentaCupFilled: Bool = false
    var isPurpleCupFilled: Bool = false

    var rinsingProgress = 6
    var rinsingReachedUpperBound: Bool = false
    
    var isToothbrushNotInCup: Bool = false
    
    var isTowelWet: Bool = false
    var dirtProgress: Int = 4
    var isDirtFixed: Bool {
        return dirtProgress <= 0
    }
}

enum WaterTemprature {
    case cold
    case hot
    case normal
    case none
}

enum TeethState {
    case dirty
    case needsRinsing
    case fixed
}
