//
//  BathMotion.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 07.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import CoreMotion

class BathMotion {
    
    let motionManager = CMMotionManager()
    
    func start(rotationCallback: @escaping((CMDeviceMotion) -> Void),
               accelerometerCallback: @escaping((CMAccelerometerData) -> Void)) {
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main, withHandler: { data, error in
            guard let data = data else { return }
            rotationCallback(data)
        })
        motionManager.startAccelerometerUpdates(to: .main, withHandler: { data, error in
            guard let data = data else { return }
            accelerometerCallback(data)
        })
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
    }
}
