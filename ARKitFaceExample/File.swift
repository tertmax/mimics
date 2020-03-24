//
//  File.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 23.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

protocol PhysicsCategory {
    var mask: UInt32 { get }
    
    static func create(value: UInt32) -> PhysicsCategory?
}
