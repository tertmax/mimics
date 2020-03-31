/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import ARKit
import SceneKit
import UIKit
import Foundation
import UIImageColors

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
    var blur: Node!
    var blur2: Node!
    var mirrorCropNode = SKCropNode()
    var currentMirrorNode = SKCropNode()
    var state = BathState()
    
    var erasePath = CGMutablePath()
    var erasePath2 = CGMutablePath()
    var currentErasePath = CGMutablePath()
    
    var timer: Timer?
    
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
        let tuple = createBlur()
        mirrorCropNode = tuple.crop
        skView.scene?.addChild(mirrorCropNode)
        resetBlur(initial: true)
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
    
    func createBlur() -> (crop: SKCropNode, sprite: SKSpriteNode, path: CGMutablePath) {
        let crop = SKCropNode()
        let path = CGMutablePath()
        
        let sprite = Node(texture: nodes.mirrorShape.texture)
        sprite.size = nodes.mirrorShape.size
        sprite.position = nodes.mirrorShape.position
        
        crop.position = nodes.mirrorShape.position
        crop.zPosition = 1
        crop.addChild(sprite)
        
        crop.maskNode = SKSpriteNode(color: .white, size: nodes.mirrorShape.size)
        
        return (crop, sprite, path)
    }
    
    func resetBlur(initial: Bool = false) {
                
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let changeBlendMode = SKAction.customAction(withDuration: 0, actionBlock: {_,_ in
            let mask = self.mirrorCropNode.maskNode?.children.first as? SKShapeNode
            mask?.blendMode = .subtract
        })
        let erasePath = SKAction.customAction(withDuration: 0, actionBlock: {_,_ in
            self.erasePath = CGMutablePath()
        })
        mirrorCropNode.maskNode?.children.first?.run(SKAction.sequence([fadeIn, changeBlendMode, erasePath]))
        
    }

    func imageWithImage(image:UIImage, width: CGFloat, height: CGFloat) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func updateWaterState() {
        switch state.waterTemprature {
        case .hot:
            animator.runSinkWater()
            animator.runSteam()
            animator.runDefaultCrane()
            runBlurViewTimer()
        case .cold:
            animator.runSinkWater()
            animator.stopSteam()
            animator.runColdCrane()
            stopBlurViewTimer()
        case .normal:
            animator.runSinkWater()
            animator.stopSteam()
            animator.runDefaultCrane()
            stopBlurViewTimer()
        case .none:
            animator.stopSinkWater()
            animator.stopSteam()
            animator.runDefaultCrane()
            animator.stopSinkWater()
            stopBlurViewTimer()
        }
    }
    
    func updateLeftHairState(direction: UISwipeGestureRecognizer.Direction) {
        BaseAnimator.swapNodes(oldNode: nodes.hairLeftInitial, newNode: nodes.hairLeftFixed)
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
        BaseAnimator.swapNodes(oldNode: state.currentRightHair, newNode: fixedHair)
        state.currentRightHair = fixedHair
    }
    
    func updateDirtState() {
        if !state.isDirtFixed {
            animator.runUpdateDirtAlpha()
            state.dirtProgress -= 1
        } else {
            nodes.dirt.removeFromParent()
        }
        UIDevice.current.vibrate()
    }
    
    func updateCupDraggability() {
        nodes.cupMagenta.draggable = nodes.toothBrush.inUse || state.isToothbrushNotInCup
    }
    
    func updateTeeth() {
        guard state.isMouthOpened, state.teethState != .fixed else { return }
        
        if state.teethProgress == 5 {
            animator.runRemovePaste()
        }
        
        if state.teethState == .needsRinsing {
            state.isMouthBusy = true
            updateCheeksAlpha()
            handleMouth()
            animator.runCleanTeeth()
        }
        
        UIDevice.current.vibrate()
        state.teethProgress -= 1
    }
    
    func wetTowel() {
        guard !state.isTowelWet else { return }
        state.isTowelWet = true
        animator.runWetTowel()
        UIDevice.current.vibrate()
        nodes.towel.initPoint.y += 20
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
            BaseAnimator.swapNodes(oldNode: nodes.pimple1Initial, newNode: nodes.pimple1Bleeidng, duration: 0.5)
            animator.runDamage()
            return
        } else if firstHitNodes.contains(nodes.pimple2Pinch) && secondHitNodes.contains(nodes.pimple2Pinch) {
            UIDevice.current.vibrate()
            nodes.pimple2Pinch.isHidden = true
            BaseAnimator.fadeOut(nodes: [nodes.pimple2], duration: 0.5)
            return
        } else if firstHitNodes.contains(nodes.pimple3Pinch) && secondHitNodes.contains(nodes.pimple3Pinch) {
            if state.currentRightHair == nodes.hairRightFixedUp || state.currentRightHair == nodes.hairRightFixedLeft {
                UIDevice.current.vibrate()
                nodes.pimple3Pinch.isHidden = true
                BaseAnimator.fadeOut(nodes: [nodes.pimple3], duration: 0.5)
                return
            }
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
    
    func runBlurViewTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
            self.showBlur(show: true)
            self.timer?.invalidate()
            self.timer = nil
        })
    }
    
    func stopBlurViewTimer() {
        timer?.invalidate()
        timer = nil
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
        BaseAnimator.swapNodes(oldNode: nodes.pimple1Bleeidng, newNode: nodes.pimple1Fixed, duration: 0.5)
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
        guard state.isMouthFlushing else { return }
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
            guard let hitSprites = skView.scene?.nodes(at: point) else { return }
            if let hitNodes = hitSprites as? [Node] {
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
            } else if hitSprites.contains(mirrorCropNode) {
                erasePath.move(to: point)
                stopBlurViewTimer()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in nodeTouches {
            let point = skView.convert(touch.value.location(in: self.skView), to: skView.scene!)
            touch.key.position = point
            if let hairSwipeDirection = checkSwipe(touch: touch.value, start: state.hairMoveStart) {
                state.hairMoveStart = nil
                updateRightHairState(direction: hairSwipeDirection)
                updateLeftHairState(direction: hairSwipeDirection)
            }
            if let _ = checkSwipe(touch: touch.value, start: state.dirtMoveStart), state.isTowelWet {
                state.dirtMoveStart = nil
                updateDirtState()
            }
        }
        
        for touch in touches where !nodeTouches.values.contains(touch) {
            let point = skView.convert(touch.location(in: self.skView), to: skView.scene!)
            guard let hitSprites = skView.scene?.nodes(at: point) else { return }
            if hitSprites.contains(mirrorCropNode) {
                eraseBlur(location: point, isSecond: false)
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
            if let hitNodes = skView.scene?.nodes(at: point) as? [Node] {
                updateNodesAfterEndTouch(hitNodes)
            }
        }
        
        if mirrorCropNode.children.first?.alpha == 1 {
            checkBlurProgress()
        }
        
        //        let suk = image.getColors()
        //        let suk2 = ColorThief.getColor(from: image)
        //        print("UIColors: \(suk)")
        //        print("ColorTheft: \(suk2)")
        
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
            nodes.toothBrush.initPoint.x += 40
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
        
        if hitNodes.contains(nodes.bandage) && nodes.bandage.isContactingWith(nodes.pimple1Bleeidng) && nodes.pimple1Bleeidng.alpha > 0 {
            fixBleedingPimple()
        }
    }
    
    func updateNodesAfterEndTouch(_ hitNodes: [Node] = []) {
        updateCupDraggability()
    }
    
    func eraseBlur(location: CGPoint, isSecond: Bool) {
        
        let line = SKShapeNode(rectOf: nodes.mirrorShape.size)
        
        erasePath.addLine(to: location)
        line.path = erasePath
        line.lineWidth = 120
        
        line.fillColor = .clear
        line.strokeColor = .white
        line.blendMode = .replace
        line.alpha = 0.0001
        line.lineCap = .round
        
        mirrorCropNode.maskNode?.removeAllChildren()
        mirrorCropNode.maskNode?.addChild(line)
        
    }
    
    func checkBlurProgress() {
        guard state.waterTemprature != .hot  else {
            runBlurViewTimer()
            return
        }
//        guard let cgImage = skView.texture(from: mirrorCropNode)?.cgImage() else { return }
//        let image = UIImage(cgImage: cgImage)
//        if let color = image.getColors() {
//            makePretty(image: image)
//        }
    }
    
    func checkSwipe(touch: UITouch, start: (point: CGPoint, time: TimeInterval)?) -> UISwipeGestureRecognizer.Direction? {
        if let start = start {
            let location = touch.location(in: skView.scene!)
            let dx = location.x - start.point.x
            let dy = location.y - start.point.y
            let distance = sqrt(dx*dx+dy*dy)
            
            let deltaTime = NSDate().timeIntervalSince1970 - start.time
            let speed = distance / CGFloat(deltaTime)
            // Check if the user's finger moved a minimum distance
            if distance > state.minDistance && speed > state.minSpeed {
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
    
    func makePretty(image : UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let smallImage = image.resized(to: CGSize(width: 100, height: 100))
            let kMeans = KMeansClusterer()
            let points = smallImage.getPixels().map({KMeansClusterer.Point(from: $0)})
            let clusters = kMeans.cluster(points: points, into: 3).sorted(by: {$0.points.count > $1.points.count})
            let colors = clusters.map(({$0.center.toUIColor()}))
            guard let mainColor = colors.first else {
                return
            }
            print(mainColor)
        }
    }
    
    func showBlur(show: Bool) {
        if show {
            resetBlur()
            animator.runShowBlur(node: mirrorCropNode)
        } else {
            resetBlur()
            animator.runHideBlur(node: mirrorCropNode)
        }
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
    
    private func handleHairCombContact(contact: OrderedContactBodies<Contact>) {
        guard state.hairMoveStart == nil else { return }
        state.hairMoveStart = (point: nodeTouches[nodes.comb]!.location(in: skView.scene!), time: NSDate().timeIntervalSince1970)
    }
    
    private func handleToothbrushTeethContact(contact: OrderedContactBodies<Contact>) {
        updateTeeth()
    }
    
    private func handleCupWaterContact(contact: OrderedContactBodies<Contact>) {
        
        switch state.waterTemprature {
        case .cold, .hot:
            animator.runDamage()
        case .normal:
            fillCupWithWater()
        case .none:
            return
        }
    }
    
    private func handleRazorHairContact(contact: OrderedContactBodies<Contact>) {
        if let node = contact.main.body.node as? Node, nodes.hairPieces.contains(node) {
            animator.runFallHairPiece(node: node)
        }
    }
    
    private func handleTowelWaterContact(contact: OrderedContactBodies<Contact>) {
        
        switch state.waterTemprature {
        case .cold, .hot:
            animator.runDamage()
        case .normal:
            wetTowel()
        case .none:
            return
        }
    }
    
    private func handleTowelDirtContact(contact: OrderedContactBodies<Contact>) {
        guard state.dirtMoveStart == nil else { return }
        state.dirtMoveStart = (point: nodeTouches[nodes.towel]!.location(in: skView.scene!), time: NSDate().timeIntervalSince1970)
    }
}

// MARK: - SKPhysicsContactDelegate

extension ViewController: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if let contact = contact.orderedBodies(for: [Contact.comb]), contact.other.category == .hair {
            handleHairCombContact(contact: contact)
        }
        
        if let contact = contact.orderedBodies(for: [Contact.toothBrush]), contact.other.category == .teeth {
            handleToothbrushTeethContact(contact: contact)
        }
        
        if let contact = contact.orderedBodies(for: [Contact.cup]), contact.other.category == .water {
            handleCupWaterContact(contact: contact)
        }
        
        if let contact = contact.orderedBodies(for: [Contact.hairPiece]), contact.other.category == .razor {
            handleRazorHairContact(contact: contact)
        }
        
        if let contact = contact.orderedBodies(for: [Contact.towel]), contact.other.category == .water {
            handleTowelWaterContact(contact: contact)
        }
        
        if let contact = contact.orderedBodies(for: [Contact.towel]), contact.other.category == .dirt {
            handleTowelDirtContact(contact: contact)
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        if let contact = contact.orderedBodies(for: [Contact.comb]), contact.other.category == .hair {
            state.hairMoveStart = nil
        }
        
        if let contact = contact.orderedBodies(for: [Contact.towel]), contact.other.category == .dirt {
            state.dirtMoveStart = nil
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

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}


extension SKView {
    func convertNodeRect(node: SKSpriteNode, to view: UIView) -> CGRect {
        guard let scene = self.scene else { return CGRect.zero }
        let topLeft = CGPoint(x: node.position.x - node.size.width / 2, y: node.position.y - node.size.height / 2)
        let topRight = CGPoint(x: node.position.x + node.size.width / 2, y: node.position.y - node.size.height / 2)
        let bottomLeft = CGPoint(x: node.position.x - node.size.width / 2, y: node.position.y + node.size.height / 2)
        
        let convertedTopLeft = convert(topLeft, from: scene)
        let convertedTopRight = convert(topRight, from: scene)
        let convertedBottomLeft = convert(bottomLeft, from: scene)
        
        let width = (convertedTopRight.x - convertedTopLeft.x) * 1.008
        let height = (convertedBottomLeft.y - convertedTopLeft.y) * 1.008
        
        return CGRect(origin: convertedTopLeft, size: CGSize(width: width, height: height))
    }
    
}

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
}
