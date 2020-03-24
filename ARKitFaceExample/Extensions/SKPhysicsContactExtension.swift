//
//  SKPhysicsContactExtension.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 23.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import SpriteKit

typealias OrderedContactBodies<T: PhysicsCategory> = (main: (body: SKPhysicsBody, category: T),
  other: (body: SKPhysicsBody, category: T))

extension SKPhysicsContact {
  
    func orderedBodies<T: PhysicsCategory>(for categoryList: [T]) -> OrderedContactBodies<T>? {
    guard let categoryA = T.create(value: bodyA.categoryBitMask),
        let categoryB = T.create(value: bodyB.categoryBitMask) else { return nil }
    let maskA = bodyA.categoryBitMask
    let maskB = bodyB.categoryBitMask
    let categoryBitMaskList = categoryList.map { $0.mask}
    let soughtMask = categoryBitMaskList.reduce(0, |)
    if maskA & soughtMask > 0 {
      return ((bodyA, categoryA as! T), (bodyB, categoryB as! T))
    } else if maskB & soughtMask > 0 {
      return ((bodyB, categoryB as! T), (bodyA, categoryA as! T))
    } else {
      return nil
    }
  }
}
