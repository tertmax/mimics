//
//  WarehouseMotion.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 27.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import CoreMotion

class WarehouseMotion {
    
    let motionManager = CMMotionManager()
    
    func start(motionCallback: @escaping((CMDeviceMotion) -> Void)) {
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main, withHandler: { data, error  in
            guard let data = data else { return }
            motionCallback(data)
        })

    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

