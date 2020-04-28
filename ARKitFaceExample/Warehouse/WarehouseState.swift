//
//  WarehouseState.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 27.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

struct WarehouseState {
    var initialRotation: (m11: Double, m12: Double, m13: Double)?
    var initHeading: Double?
    var initYGravity: Double?
    var bias: Double = 0
    var yBias: Double = 0

    var maxHeading: Double {
        guard let initHeading = initHeading else { return 0 }
        return initHeading + 80
    }
    
    var minHeading: Double {
        guard let initHeading = initHeading else { return 0 }
        return initHeading - 80
    }
    
    var maxRotation: (Double, Double, Double) {
        guard let initial = initialRotation else { return (0,0,0) }
        
        var newM11 = initial.m11 + 0.4
        var newM12 = initial.m12 + 0.4
        var newM13 = initial.m13 + 0.4
        
        if newM11 > 1 {
            newM11 -= -newM11 + 2
        }
        
        if newM12 > 1 {
            newM12 -= -newM12 + 2
        }
        
        if newM13 > 1 {
            newM13 -= -newM13 + 2
        }
        
        return(newM11, newM12, newM13)
    }
    
    var minRotation: (Double, Double, Double) {
        guard let initial = initialRotation else { return (0,0,0) }

        var newM11 = initial.m11 - 0.4
        var newM12 = initial.m12 - 0.4
        var newM13 = initial.m13 - 0.4
        
        if newM11 < -1 {
            newM11 += -newM11 - 2
        }
        
        if newM12 < -1 {
            newM12 += -newM12 - 2
        }
        
        if newM13 < -1 {
            newM13 += -newM13 - 2
        }
        
        return(newM11, newM12, newM13)
    }
}
