//
//  WarehouseViewController.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 27.04.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit
import SceneKit
import CoreMotion

class WarehouseViewController: UIViewController, WarehouseAnimatable {

    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var sceneView: ARSCNView!
    
    var nodes: WarehouseNodes!
    var state: WarehouseState = WarehouseState()
    var animator: WarehouseAnimator!
    
    var maskCircle: SKShapeNode!
    
    private let motion = WarehouseMotion()
    private let physicsUtils = WarehousePhysicsUtil()
    
    @IBAction func resetHeading(_ sender: Any) {
        state.initialRotation = nil
        state.initHeading = nil
        state.initYGravity = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        if let scene = SKScene(fileNamed: "Warehouse") {
            scene.scaleMode = .aspectFit
            skView.isMultipleTouchEnabled = true
            skView.presentScene(scene)
            scene.physicsWorld.gravity = .zero
        }
        
        nodes = WarehouseNodes(scene: skView.scene)
        animator = WarehouseAnimator(animatable: self)
        
        motion.start(motionCallback: { data in
            
            self.handleMotionUpdate(data: data)

        })
        
        maskCircle = nodes.flashlight
        skView.scene?.physicsWorld.contactDelegate = self
        physicsUtils.createPhyscisBodies(nodes: nodes)
        animator.runMouseWalking()
        animator.runCandleFire()
        
        skView.showsPhysics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        resetTracking()
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func handleMotionUpdate(data: CMDeviceMotion) {
        
        func closestBorder(heading: Double, max: Double, min: Double, threshold: Double) -> Double {
            var distanceToMax = max - heading
            if distanceToMax < 0 {
                distanceToMax *= -1
            } else {
                distanceToMax = 360 - distanceToMax
            }
            
            var distanceToMin = min - heading
            if distanceToMin < 0 {
                distanceToMin = 360 + distanceToMin
            }
            
            return distanceToMax >= distanceToMin ? min : max
            
        }

        func distance(angle1: Double, angle2: Double) {
            
        }
        
        let threshold: Double = 80
        if state.initHeading == nil {
            if 360 - data.heading < threshold {
                state.initHeading = 360 - threshold
                state.bias = (360 - data.heading) - threshold
            } else if data.heading - threshold < 0 {
                state.initHeading = threshold
                state.bias = threshold - data.heading
            } else {
                state.initHeading = data.heading
            }
        }
        
        let z = data.gravity.z
        let zThreshold = 0.6
        if state.initYGravity == nil {
            if z - zThreshold < -1 {
                state.initYGravity = -1 + zThreshold
            } else if z + zThreshold > 1 {
                state.initYGravity = 1 - zThreshold
            } else {
                state.initYGravity = z
            }
        }
        var biasedHeading = ((data.heading + state.bias).truncatingRemainder(dividingBy: 360))
        
        if !(state.minHeading...state.maxHeading ~= biasedHeading) {
            biasedHeading = closestBorder(heading: biasedHeading,
                                          max: state.maxHeading,
                                          min: state.minHeading,
                                          threshold: threshold)
        }

        let delta = (state.initHeading ?? 0) - biasedHeading

        animator.runMoveBackground(newX: nodes.background.initPoint.x + CGFloat(delta) * 10)
        animator.runMoveFlashlightX(node: maskCircle, x: nodes.background.initPoint.x - CGFloat(delta) * 5)
        
        let zDelta = z - (state.initYGravity ?? 0)
        
        animator.runMoveFlashlightY(node: maskCircle, y: nodes.background.initPoint.y + CGFloat(zDelta) * 1500)
    }
}

extension WarehouseViewController: ARSCNViewDelegate {
    
}

extension WarehouseViewController: ARSessionDelegate {
    
}

extension WarehouseViewController: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if let contact = contact.orderedBodies(for: [WarehousePhysicsUtil.Contact.lense]), contact.other.category == .flashlight {
            handleLenseFlashlightContact(contact: contact)
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        if let contact = contact.orderedBodies(for: [WarehousePhysicsUtil.Contact.lense]), contact.other.category == .flashlight {
                BaseAnimator.fadeOut(nodes: [nodes.lenseBeam], duration: 0.5)
        }
    }
    
    func handleLenseFlashlightContact(contact: OrderedContactBodies<WarehousePhysicsUtil.Contact>) {
        guard nodes.lenseBeam.alpha == 0 else { return }
        BaseAnimator.fadeIn(nodes: [nodes.lenseBeam], duration: 0.5)
    }
}
