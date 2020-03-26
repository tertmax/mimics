/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import ARKit
import SceneKit
import UIKit
import Foundation

class ViewController: UIViewController, ARSessionDelegate, BathAnimatable {
    
    // MARK: Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var skView: SKView!
    
    private var animator: BathAnimator!
    private var nodeTouches: [Node: UITouch] = [:]
    private let face = FaceTracker()
    private let physicsUtils = BathPhysicsUtil()
    
    var nodes: BathNodes!
    var state = BathState()
    
    // MARK: Properties
    
    var contentControllers: [VirtualContentType: VirtualContentController] = [:]
    
    var selectedVirtualContent: VirtualContentType! {
        didSet {
            guard oldValue != nil, oldValue != selectedVirtualContent
                else { return }
            // Remove existing content when switching types.
            contentControllers[oldValue]?.contentNode?.removeFromParentNode()
            
            // If there's an anchor already (switching content), get the content controller to place initial content.
            // Otherwise, the content controller will place it in `renderer(_:didAdd:for:)`.
            if let anchor = currentFaceAnchor, let node = sceneView.node(for: anchor),
                let newContent = selectedContentController.renderer(sceneView, nodeFor: anchor) {
                node.addChildNode(newContent)
            }
        }
    }
    var selectedContentController: VirtualContentController {
        if let controller = contentControllers[selectedVirtualContent] {
            return controller
        } else {
            
            let controller = selectedVirtualContent.makeController()
            contentControllers[selectedVirtualContent] = controller
            return controller
        }
    }
    
    var currentFaceAnchor: ARFaceAnchor?
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Set the initial face content.
        tabBar.selectedItem = tabBar.items!.first!
        selectedVirtualContent = VirtualContentType(rawValue: tabBar.selectedItem!.tag)
        
        // Load the SKScene from 'GameScene.sks'
        if let scene = SKScene(fileNamed: "GameScene") {
            scene.scaleMode = .aspectFit
            skView.isMultipleTouchEnabled = true
            skView.presentScene(scene)
            scene.physicsWorld.gravity = .zero
        }
        animator = BathAnimator(animatable: self)
        
        nodes = BathNodes(scene: skView.scene)
        animator.runFlyMovement()
        createGestures()
        
        skView.scene?.physicsWorld.contactDelegate = self
        physicsUtils.createPhyscisBodies(nodes: nodes)
        
        state.currentRightHair = nodes.hairRightInitial
        //        skView.showsPhysics = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }
    
    func updateWaterState() {
        switch state.waterTemprature {
        case .hot:
            animator.runSinkWater()
            animator.runSteam()
            animator.runDefaultCrane()
        case .cold:
            animator.runSinkWater()
            animator.stopSteam()
            animator.runColdCrane()
        case .normal:
            animator.runSinkWater()
            animator.stopSteam()
            animator.runDefaultCrane()
        case .none:
            animator.stopSinkWater()
            animator.stopSteam()
            animator.runDefaultCrane()
            animator.stopSinkWater()
        }
    }
    
    func updateLeftHairState(direction: UISwipeGestureRecognizer.Direction) {
        guard direction == .down else { return }
        animator.swapNodes(oldNode: nodes.hairLeftInitial, newNode: nodes.hairLeftFixed)
    }
    
    func updateRightHairState(direction: UISwipeGestureRecognizer.Direction) {
        var fixedHair = nodes.hairRightFixedDown
        switch direction {
        case .down:
            fixedHair = nodes.hairRightFixedDown
        case .up:
            fixedHair = nodes.hairRightFixedUp
        case .left:
            fixedHair = nodes.hairRightFixedLeft
        case .right:
            fixedHair = nodes.hairRightFixedRight
        default:
            print("No such swipe direction for Right Hair node")
        }
        animator.swapNodes(oldNode: state.currentRightHair, newNode: fixedHair)
        state.currentRightHair = fixedHair
    }
    
    func updateCupDraggability() {
        nodes.cupMagenta.draggable = nodes.toothBrush.inUse || state.isToothbrushNotInCup
    }
    
    func updateTeeth() {
        guard state.isMouthOpened else { return }
        if state.teethProgress == 4 {
            let changeBrush = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_toothbrush.name))
            nodes.toothBrush.run(changeBrush)
        }
        
        if state.teethProgress == 0 {
            UIDevice.current.vibrate()
            state.isMouthBusy = true
            updateCheeksAlpha()
            let topAction = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_jaw_top_fixed.name))
            let bottomAction = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_jaw_bottom_fixed.name))
            nodes.jawTop.run(topAction)
            nodes.jawBottom.run(bottomAction)
        } else {
            state.teethProgress -= 1
            UIDevice.current.vibrate()
        }
    }
    
    //MARK: Gestures
    
    func createGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchPimple))
        pinch.cancelsTouchesInView = false
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes))
        swipeDown.cancelsTouchesInView = false
        swipeDown.direction = .down
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes))
        swipeUp.cancelsTouchesInView = false
        swipeUp.direction = .up
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes))
        swipeRight.cancelsTouchesInView = false
        swipeRight.direction = .right
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes))
        swipeLeft.cancelsTouchesInView = false
        swipeLeft.direction = .left
        
        self.skView.addGestureRecognizer(pinch)
        self.skView.addGestureRecognizer(swipeDown)
        self.skView.addGestureRecognizer(swipeUp)
        self.skView.addGestureRecognizer(swipeRight)
        self.skView.addGestureRecognizer(swipeLeft)
    }
    
    @objc
    func pinchPimple(sender: UIPinchGestureRecognizer) {
        
        guard sender.numberOfTouches > 1, nodeTouches.isEmpty else { return }
        let firstPoint = skView.convert(sender.location(ofTouch: 0, in: self.skView), to: skView.scene!)
        let secondPoint = skView.convert(sender.location(ofTouch: 1, in: self.skView), to: skView.scene!)
        guard let firstHitNodes = skView.scene?.nodes(at: firstPoint),
            let secondHitNodes = skView.scene?.nodes(at: secondPoint) else { return }
        if firstHitNodes.contains(nodes.pimple1Pinch) && secondHitNodes.contains(nodes.pimple1Pinch) {
            UIDevice.current.vibrate()
            nodes.pimple1Pinch.isHidden = true
            animator.swapNodes(oldNode: nodes.pimple1Initial, newNode: nodes.pimple1Bleeidng, duration: 0.5)
            animator.runDamage()
        } else if firstHitNodes.contains(nodes.pimple2Pinch) && secondHitNodes.contains(nodes.pimple2Pinch) {
            UIDevice.current.vibrate()
            nodes.pimple2Pinch.isHidden = true
            animator.fadeOut(nodes: [nodes.pimple2], duration: 0.5)
        }
    }
    
    @objc
    func handleSwipes(sender: UISwipeGestureRecognizer) {
        let point = skView.convert(sender.location(in: self.skView), to: skView.scene!)
        guard let hitNodes = skView.scene?.nodes(at: point) else { return }
        if hitNodes.contains(nodes.coldValve) {
            switch sender.direction {
            case .down:
                guard !state.isColdWaterOn else { return }
                state.isColdWaterOn = true
                animator.runRotateColdValve(angle: -1)
            case .up:
                guard state.isColdWaterOn else { return }
                state.isColdWaterOn = false
                animator.runRotateColdValve(angle: 1)
            default:
                print("no such direction for cold valve")
            }
            updateWaterState()
        }
        
        if hitNodes.contains(nodes.hotValve) {
            switch sender.direction {
            case .down:
                guard !state.isHotWaterOn else { return }
                state.isHotWaterOn = true
                animator.runRotateHotValve(angle: -1)
            case .up:
                guard state.isHotWaterOn else { return }
                state.isHotWaterOn = false
                animator.runRotateHotValve(angle: 1)
            default:
                print("no such direction for cold valve")
            }
            updateWaterState()
        }
    }
    
    //MARK: Mimics handling
    
    func handleBrows() {
        let leftDown = face.get(.browDownRight)
        let leftUp = face.get(.browOuterUpRight)
        
        let rightDown = face.get(.browDownLeft)
        let rightUp = face.get(.browOuterUpLeft)
        
        nodes.leftBrow.position.y = nodes.leftBrow.initPoint.y + 10 * (leftUp - leftDown)
        nodes.rightBrow.position.y = nodes.rightBrow.initPoint.y + 10 * (rightUp - rightDown)
    }
    
    func handleEyes() {
        let eyeDown = face.get(.eyeLookDownLeft)
        let eyeUp = face.get(.eyeLookUpLeft)
        let eyeLeft = face.get(.eyeLookInLeft)
        let eyeRight = face.get(.eyeLookOutLeft)
        
        nodes.leftEyeBall.position.x = nodes.leftEyeBall.initPoint.x + 18 * ( eyeLeft - eyeRight)
        nodes.leftEyeBall.position.y = nodes.leftEyeBall.initPoint.y + 10 * (-eyeUp + eyeDown)
        
        nodes.rightEyeBall.position.x = nodes.rightEyeBall.initPoint.x + 18 * ( eyeLeft - eyeRight)
        nodes.rightEyeBall.position.y = nodes.rightEyeBall.initPoint.y + 10 * ( -eyeUp + eyeDown)
    }
    
    func updateCheeksAlpha() {
        nodes.leftCheek.alpha = state.isMouthFlushing ? 1 : 0
        nodes.rightCheek.alpha = state.isMouthFlushing ? 1 : 0
    }
    
    func putWaterInMouth() {
        UIDevice.current.vibrate()
        state.isMouthFlushing = true
        updateCheeksAlpha()
        animator.runPutWaterInMouth()
        nodes.cupMagenta.draggable = false
    }
    
    func fillCupWithWater() {
        guard !state.isMagentaCupFilled else { return }
        UIDevice.current.vibrate()
        state.isMagentaCupFilled = true
        animator.runFillCup()
    }
    
    func fixBleedingPimple() {
        UIDevice.current.vibrate()
        animator.swapNodes(oldNode: nodes.pimple1Bleeidng, newNode: nodes.pimple1Fixed, duration: 0.5)
        nodes.bandage.removeFromParent()
    }
    
    func updateMouthAlpha(show: Bool) {
        let mouthItems: [SKNode] = [
            nodes.jawBottom,
            nodes.lipBottom,
            nodes.jawTop,
            nodes.lipTop,
            nodes.mouthInside
        ]
        
        let showTeeth = show && !state.isMouthBusy
        state.isMouthOpened = showTeeth
        nodes.mouthBrushed.alpha = state.isMouthBusy ? 1 : 0
        nodes.mouthDefault.alpha = (state.isMouthBusy || show) ? 0 : 1
        
        for item in mouthItems {
            item.alpha = showTeeth ? 1 : 0
        }
    }
    
    func handleMouth() {
        
        let jawValue = face.get(.jawOpen)
        let topLipValue = face.get(.mouthShrugUpper)
        
        let showTeeth = topLipValue > 0.11
        
        let lipMultiplier: CGFloat =  40
        let lipCompensator: CGFloat = 3 * jawValue / 0.2
        
        updateMouthAlpha(show: showTeeth)
        
        nodes.lipBottom.position.y = nodes.lipBottom.initPoint.y - topLipValue * (lipMultiplier + lipCompensator)
        nodes.lipTop.position.y = nodes.lipTop.initPoint.y + topLipValue * (lipMultiplier + lipCompensator)
        nodes.jawBottom.position.y = nodes.jawBottom.initPoint.y - jawValue * 20
        nodes.jawTop.position.y = nodes.jawTop.initPoint.y + jawValue * 20
    }
    
    func handleCheeks() {
        let cheeks = face.get(.cheekPuff)
        
        let cheeksUpperThreshold: CGFloat = 0.55
        let cheeksLowerThreshold: CGFloat = 0.3
        
        nodes.leftCheek.xScale = nodes.leftCheek.initXScale + cheeks * 0.1
        nodes.leftCheek.yScale = nodes.leftCheek.initYScale + cheeks * 0.1
        nodes.rightCheek.xScale = nodes.rightCheek.initXScale + cheeks * 0.1
        nodes.rightCheek.yScale = nodes.rightCheek.initYScale + cheeks * 0.1
        
        if state.rinsingProgress > 0 {
            if state.rinsingReachedUpperBound && cheeks < cheeksLowerThreshold {
                state.rinsingReachedUpperBound = false
                state.rinsingProgress -= 1
            } else if !state.rinsingReachedUpperBound && cheeks > cheeksUpperThreshold {
                state.rinsingReachedUpperBound = true
                state.rinsingProgress -= 1
            }
        } else if state.rinsingProgress == 0 {
            state.rinsingProgress -= 1
            animator.runSpitAnimation()
        }
    }
    
    
    //MARK: Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = skView.convert(touch.location(in: self.skView), to: skView.scene!)
            guard let hitNodes = skView.scene?.nodes(at: point) as? [Node] else { return }
            updateNodesBeforeStartTouch(hitNodes)
            if let draggableHitNode = hitNodes.first(where: { $0.draggable }) {
                draggableHitNode.inUse = true
                draggableHitNode.xScale = draggableHitNode.initXScale * 1.5
                draggableHitNode.yScale = draggableHitNode.initYScale * 1.5
                draggableHitNode.position = point
                draggableHitNode.zPosition = 10
                nodeTouches[draggableHitNode] = touch
                updateNodesAfterStartTouch(hitNodes)
            } else if hitNodes.contains(nodes.water) && !(state.isHotWaterOn && state.isColdWaterOn) {
                animator.runDamage()
            } else if hitNodes.contains(nodes.fly) {
                tapOnFly()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in nodeTouches {
            let point = skView.convert(touch.value.location(in: self.skView), to: skView.scene!)
            touch.key.position = point
            if let swipeDirection = checkSwipe(touch: touch.value) {
                updateRightHairState(direction: swipeDirection)
                updateLeftHairState(direction: swipeDirection)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let point = skView.convert(touch.location(in: self.skView), to: skView.scene!)
            if let hitNodes = skView.scene?.nodes(at: point) as? [Node] {
                updateNodesBeforeEndTouch(hitNodes)
            }
        }
        
        for (node, touch) in nodeTouches where touches.contains(touch) {
            node.reset()
            nodeTouches[node] = nil
        }
        
        for touch in touches {
            let point = skView.convert(touch.location(in: self.skView), to: skView.scene!)
            guard let hitNodes = skView.scene?.nodes(at: point) as? [Node] else { return }
            updateNodesAfterEndTouch(hitNodes)
        }
        
    }
    
    func updateNodesBeforeStartTouch(_ hitNodes: [Node] = []) {
        if hitNodes.contains(nodes.razor) {
            let changeTexture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_razor_inuse.name))
            let rotate = SKAction.rotate(toAngle: 0, duration: 0)
            nodes.razor.run(changeTexture)
            nodes.razor.run(rotate)
        }
        
        if hitNodes.contains(nodes.cupMagenta) && nodes.toothBrush.inUse {
            state.isToothbrushNotInCup = true
            nodes.toothBrush.initRotation = -0.9
            nodes.toothBrush.initPoint = nodes.towel.initPoint
            nodes.toothBrush.initPoint.x *= -1
            nodes.toothBrush.initPoint.x += 30
            nodes.cupMagenta.initZPosition = 0
        }
    }
    
    func updateNodesAfterStartTouch(_ hitNodes: [Node] = []) {
        updateCupDraggability()
    }
    
    func updateNodesBeforeEndTouch(_ hitNodes: [Node] = []) {
        
        if hitNodes.contains(nodes.cupMagenta) &&
            nodes.cupMagenta.isContactingWith(nodes.mouthBrushed) &&
            state.isMouthBusy &&
            state.isMagentaCupFilled {
            putWaterInMouth()
        }
        
        if hitNodes.contains(nodes.bandage) && nodes.bandage.isContactingWith(nodes.pimple1Bleeidng) {
            fixBleedingPimple()
        }
    }
    
    func updateNodesAfterEndTouch(_ hitNodes: [Node] = []) {
        updateCupDraggability()
    }
    
    func checkSwipe(touch: UITouch) -> UISwipeGestureRecognizer.Direction? {
        if let startLocation = state.hairMoveStartLocation {
            let location = touch.location(in: skView.scene!)
            let dx = location.x - startLocation.x
            let dy = location.y - startLocation.y
            let distance = sqrt(dx*dx+dy*dy)
            self.state.hairMoveStartLocation = nil
            // Check if the user's finger moved a minimum distance
            if distance > state.minDistance {
                // Determine the direction of the swipe
                let x = abs(dx/distance) > 0.4 ? Int(sign(Float(dx))) : 0
                let y = abs(dy/distance) > 0.4 ? Int(sign(Float(dy))) : 0
                
                switch (x,y) {
                case (0,1):
                    return .up
                case (0,-1):
                    return .down
                case (-1,0), (-1,-1), (-1,1):
                    return .left
                case (1,0), (1,1), (1,-1):
                    return .right
                default:
                    return nil
                }
            }
        }
        return nil
    }
    
    func tapOnFly() {
        print("You tapped on the fly :)")
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: SK Contacts
    
    func handleHairCombContact(contact: SKPhysicsContact) {
        guard state.hairMoveStartLocation == nil else { return }
        state.hairMoveStartLocation = nodeTouches[nodes.comb]!.location(in: skView.scene!)
    }
    
    func handleBrushTeethContact(contact: SKPhysicsContact) {
        
    }
    
    private func handleCupWaterContact(contact: OrderedContactBodies<Contact>) {
        if let node = contact.other.body.node as? Node, node == nodes.cupMagenta {
            fillCupWithWater()
        }
    }
    
    private func handleRazorHairContact(contact: OrderedContactBodies<Contact>) {
        if let node = contact.main.body.node as? Node, nodes.hairPieces.contains(node) {
            animator.runFallHairPiece(node: node)
        }
    }
}

extension ViewController: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if let _ = contact.orderedBodies(for: [Contact.comb, .hair]) {
            handleHairCombContact(contact: contact)
        }
        
        if let _ = contact.orderedBodies(for: [Contact.toothBrush, .teeth]) {
            updateTeeth()
        }
        
        if let contact = contact.orderedBodies(for: [Contact.cup, .water]) {
            handleCupWaterContact(contact: contact)
        }
        
        if let contact = contact.orderedBodies(for: [Contact.hairPiece, .razor]) {
            handleRazorHairContact(contact: contact)
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        if let _ = contact.orderedBodies(for: [Contact.comb, .hair]) {
            state.hairMoveStartLocation = nil
        }
    }
}

extension ViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let contentType = VirtualContentType(rawValue: item.tag)
            else { fatalError("unexpected virtual content tag") }
        selectedVirtualContent = contentType
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        currentFaceAnchor = faceAnchor
        
        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        if node.childNodes.isEmpty, let contentNode = selectedContentController.renderer(renderer, nodeFor: faceAnchor) {
            node.addChildNode(contentNode)
        }
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor == currentFaceAnchor,
            let contentNode = selectedContentController.contentNode,
            contentNode.parent == node,
            let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
        
        face.update(faceAnchor)
        
        handleBrows()
        handleEyes()
        handleMouth()
        handleCheeks()
    }
}


extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

