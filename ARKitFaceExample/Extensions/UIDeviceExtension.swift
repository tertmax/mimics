//
//  UIDeviceExtension.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 23.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import AudioToolbox

extension UIDevice {
    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
