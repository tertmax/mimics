//
//  FaceTracker.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 16.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import ARKit

class FaceTracker {
    
    private var anchor: ARFaceAnchor!
    
    func update(_ anchor: ARFaceAnchor) {
        self.anchor = anchor
    }
    
    func get(_ location: ARFaceAnchor.BlendShapeLocation) -> CGFloat {
        let number = anchor.blendShapes[location] ?? 1.0
        return CGFloat(truncating: number)
    }
}
