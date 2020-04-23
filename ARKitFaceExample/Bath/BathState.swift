//
//  BathState.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 26.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

struct BathState {
    
    var winCondition: Bool {
        return isSmellFixed &&
        teethFixed &&
        isLeftEarCleaned &&
        isRightEarCleaned &&
        !isCharacterFreezing &&
        isShirtFixed &&
        pimplesFixed &&
        isShaved &&
        isDirtFixed &&
        isHairFixed &&
        stickState == .reseted
    }
    
    var winCallback: (() -> Void)?
    
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
    
    var isCharacterFreezing: Bool = true {
        didSet {
            checkWin()
        }
    }
    
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
    
    var teethFixed: Bool = false {
        didSet {
            checkWin()
        }
    }
    
    var isMagentaCupFilled: Bool = false
    var isBrushMovedToSink: Bool = false

    var rinsingProgress = 6
    var rinsingReachedUpperBound: Bool = false
    
    var isToothbrushNotInCup: Bool = false
    
    var isTowelWet: Bool = false
    var dirtProgress: Int = 4
    var isDirtFixed: Bool {
        return dirtProgress <= 0
    }
    var isSmellFixed: Bool = false {
        didSet {
            checkWin()
        }
    }
    
    var deodorantReachedLowerBound = false
    var deodorantFixingProgress = 1
    
    var isDeodorantFixed: Bool = false
    var isShirtFixed: Bool = false {
        didSet {
            checkWin()
        }
    }
    
    var flyState: FlyState = .flying
    
    var leftEarProgress = 1
    var rightEarProgress = 1
    var stickState: StickState = .reseted {
        didSet {
            checkWin()
        }
    }
    var isLeftEarCleaned: Bool = false {
        didSet {
            checkWin()
        }
    }
    var isRightEarCleaned: Bool = false {
        didSet {
            checkWin()
        }
    }
    
    var pimple1Fixed: Bool = false {
        didSet {
            checkWin()
        }
    }
    var pimple2Fixed: Bool = false {
        didSet {
            checkWin()
        }
    }
    var pimple3Fixed: Bool = false {
        didSet {
            checkWin()
        }
    }
    
    var pimplesFixed: Bool {
        return pimple1Fixed && pimple2Fixed && pimple3Fixed
    }
    
    var isShaved: Bool = false {
        didSet {
            checkWin()
        }
    }
    
    var isHairFixed: Bool = false {
        didSet {
            checkWin()
        }
    }
    
    var isBlurSoundPlaying: Bool = false
    var mirrorSounds: [String] = [
        R.string.bath.mirror1_sound(),
        R.string.bath.mirror3_sound(),
        R.string.bath.mirror2_sound(),
        R.string.bath.mirror4_sound(),
        R.string.bath.mirror5_sound(),
        R.string.bath.mirror6_sound()
    ]
    
    var isFlySoundPlaying: Bool = false
    
    func checkWin() {
        guard winCondition else { return }
        winCallback?()
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

enum FlyState {
    case flying
    case onRazor
    case onWeb
}

enum StickState {
    case reseted
    case readyToReset
    case inLeftEar
    case inRightEar
}
