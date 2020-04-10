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
import CoreMotion

class ViewController: UIViewController, ARSessionDelegate, BathAnimatable {
    
    // MARK: Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var skView: SKView!
    
    private var animator: BathAnimator!
    private var nodeTouches: [Node: UITouch] = [:]
    private let face = FaceTracker()
    private let physicsUtils = BathPhysicsUtil()
    private let motion = BathMotion()
    private let deodorantMotion = BathMotion()
    
    var nodes: BathNodes!
    var state = BathState()
    
    var blur: Node!
    var mirrorCropNode = SKCropNode()
    var erasePath = CGMutablePath()
    var initialMask: SKShapeNode?
    
    var blurDict: [UITouch: (path: CGMutablePath, node: SKShapeNode?, timer: Timer?)] = [:]
    
    var timer: Timer?
    
    // MARK: Properties
    
    var currentFaceAnchor: ARFaceAnchor?
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        becomeFirstResponder()
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Set the initial face content.
        //        tabBar.selectedItem = tabBar.items!.first!
        //        selectedVirtualContent = VirtualContentType(rawValue: tabBar.selectedItem!.tag)
        
        // Load the SKScene from 'GameScene.sks'
        if let scene = SKScene(fileNamed: "GameScene") {
            scene.scaleMode = .aspectFit
            skView.isMultipleTouchEnabled = true
            skView.presentScene(scene)
            scene.physicsWorld.gravity = .zero
        }
        animator = BathAnimator(animatable: self)
        
        nodes = BathNodes(scene: skView.scene)
        animator.runFlyMovement {
            guard self.state.isSmellFixed else { return }
            self.animator.runFlyMoveToRazor {
                self.state.flyState = .onRazor
                self.motion.start(rotationCallback: self.handleRazorMotion(data:),
                                  accelerometerCallback: self.handleRazorAcceleration(data:))
            }
        }
        createGestures()
        
        skView.scene?.physicsWorld.contactDelegate = self
        physicsUtils.createPhyscisBodies(nodes: nodes)
        
        state.currentRightHair = nodes.hairRightInitial
        let tuple = createBlur()
        mirrorCropNode = tuple.crop
        skView.scene?.addChild(mirrorCropNode)
        
        nodes.stickRightSwipe.isHidden = true
        nodes.stickLeftSwipe.isHidden = true
        
        showFreezeAnimation()
        
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
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
//
//    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
//        if motion == .motionShake && nodeTouches.keys.contains(nodes.toiletWater) {
//            UIDevice.current.vibrate()
//            state.isDeodorantFixed = true
//            if nodes.toiletWater.isContactingWith(nodes.shirtZone) {
//                handleDeodorantShirtContact()
//            }
//        }
//    }
    
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
        
        sprite.alpha = 0
        
        return (crop, sprite, path)
    }
    
    func resetBlur(touch: UITouch) {
        guard state.waterTemprature == .hot else { return }
        let node = blurDict[touch]?.node
        let fadeIn = SKAction.fadeIn(withDuration: 0.7)
        let erasePath = SKAction.customAction(withDuration: 0, actionBlock: {_,_ in
            node?.removeFromParent()
            self.blurDict[touch] = nil
        })
        let heatUpCharacter = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            self.heatUpCharacter()
        })
        if state.isBlurInitiallySetUp {
            node?.run(SKAction.sequence([fadeIn, erasePath, heatUpCharacter]))
        } else {
            state.isBlurInitiallySetUp = true
            mirrorCropNode.children.first?.run(SKAction.sequence([fadeIn, heatUpCharacter]))
        }
    }
    
    func updateWaterState() {
        switch state.waterTemprature {
        case .hot:
            animator.runSinkWater()
            animator.runSteam()
            animator.runDefaultCrane()
            runBlurViewTimer2()
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
        UIDevice.current.vibrate()
        state.teethProgress -= 1
        
        if state.teethProgress == 5 {
            animator.runRemovePaste()
        }
        
        if state.teethState == .needsRinsing {
            handleMouth()
            animator.runCleanTeeth()
        }
    }
    
    func wetTowel() {
        guard !state.isTowelWet else { return }
        state.isTowelWet = true
        animator.runWetTowel()
        UIDevice.current.vibrate()
        nodes.towel.initPoint.y += 20
    }
    
    func heatUpCharacter() {
        guard state.isCharacterFreezing else { return }
        animator.runHeatCharacter {
            self.state.isCharacterFreezing = false
        }
    }
    
    func showFreezeAnimation() {
        animator.runFreezeEffects()
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
        if firstHitNodes.contains(nodes.pimple1Pinch) &&
            secondHitNodes.contains(nodes.pimple1Pinch) &&
        sender.velocity < -2 {
            UIDevice.current.vibrate()
            nodes.pimple1Pinch.isHidden = true
            BaseAnimator.swapNodes(oldNode: nodes.pimple1Initial, newNode: nodes.pimple1Bleeidng, duration: 0.5)
            animator.runDamage()
            return
        } else if firstHitNodes.contains(nodes.pimple2Pinch) &&
            secondHitNodes.contains(nodes.pimple2Pinch) &&
        sender.velocity < -2 {
            UIDevice.current.vibrate()
            nodes.pimple2Pinch.isHidden = true
            BaseAnimator.fadeOut(nodes: [nodes.pimple2], duration: 0.5)
            return
        } else if firstHitNodes.contains(nodes.pimple3Pinch) &&
            secondHitNodes.contains(nodes.pimple3Pinch) &&
        sender.velocity < -2  {
            if state.currentRightHair == nodes.hairRightFixedUp || state.currentRightHair == nodes.hairRightFixedLeft {
                UIDevice.current.vibrate()
                nodes.pimple3Pinch.isHidden = true
                BaseAnimator.fadeOut(nodes: [nodes.pimple3], duration: 0.5)
                return
            }
        } else if firstHitNodes.contains(nodes.shirtInitial) &&
            secondHitNodes.contains(nodes.shirtInitial) {
            if !state.isShirtFixed && sender.velocity < -5 {
                animator.runCloseShirt()
                state.isShirtFixed = true
            }
        } else if firstHitNodes.contains(nodes.shirtFixed) &&
            secondHitNodes.contains(nodes.shirtFixed) {
            if state.isShirtFixed && sender.velocity > 5 {
                animator.runOpenShirt()
                state.isShirtFixed = false
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
        
        if hitNodes.contains(nodes.stickLeftSwipe) {
            switch sender.direction {
            case .down, .up:
                UIDevice.current.vibrate()
                animator.runCleanEar(left: true, completion: {
                    if self.state.leftEarProgress == 0 {
                        self.nodes.stick.draggable = true
                        self.nodes.stickLeftSwipe.isHidden = true
                        self.state.stickState = .readyToReset
                    } else {
                        self.state.leftEarProgress -= 1
                    }
                })
            default:
                print("no such direction for left stick")
            }
        }
        
        if hitNodes.contains(nodes.stickRightSwipe) {
            switch sender.direction {
            case .down, .up:
                UIDevice.current.vibrate()
                animator.runCleanEar(left: false, completion: {
                    if self.state.rightEarProgress == 0 {
                        self.nodes.stick.draggable = true
                        self.nodes.stickRightSwipe.isHidden = true
                        self.state.stickState = .readyToReset
                    } else {
                        self.state.rightEarProgress -= 1
                    }
                })
            default:
                print("no such direction for right stick")
            }
        }
    }
    
    func runBlurViewTimer2() {
        if !state.isBlurInitiallySetUp {
            let touch = UITouch()
            blurDict[touch] = (CGMutablePath(), nil, nil)
        }
        for var (k, v) in blurDict where v.timer == nil {
            v.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
                self.resetBlur(touch: k)
                v.timer?.invalidate()
                v.timer = nil
            })
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
        nodes.mouthBrushed.alpha = state.teethState == .needsRinsing ? 1 : 0
        nodes.mouthDefault.alpha = (state.isMouthBusy || show) ? 0 : 1
        nodes.mouthCold.alpha = state.isCharacterFreezing ? 1 : 0
        
        for item in mouthItems {
            item.alpha = showTeeth ? 1 : 0
        }
    }
    
    func handleRazorMotion(data: CMDeviceMotion) {
        let rotation = data.gravity.x
        let razor = nodes.razor
        var newNodeRotation = razor.initRotation - CGFloat(rotation)
        let maxRotation: CGFloat = razor.initRotation
        let minRotation: CGFloat = maxRotation - 0.7
        if newNodeRotation > maxRotation {
            newNodeRotation = maxRotation
        } else if newNodeRotation < minRotation {
            newNodeRotation = minRotation
        }
        razor.zRotation = newNodeRotation
    }
    
    func handleRazorAcceleration(data: CMAccelerometerData) {
        guard data.acceleration.x < -1.3 else { return }
        motion.stop()
        animator.runDropRazor{
            self.nodes.razor.initPoint = self.nodes.razor.position
            self.nodes.razor.draggable = true
        }
        
        let fly = nodes.fly
        
        fly.removeFromParent()
        skView.scene?.addChild(fly)
        fly.xScale = fly.initXScale
        fly.yScale = fly.initYScale
        fly.position = nodes.razor.position
        fly.zRotation = fly.initRotation
        animator.runFlyMoveToSpider {
            self.nodes.flyWings.removeAllActions()
            self.state.flyState = .onWeb
            self.animator.runHeart()
            self.animator.runFallStick {
                self.nodes.stick.draggable = true
                self.nodes.stick.initPoint = self.nodes.stick.position
                self.nodes.stick.reset()
            }
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
            animator.runSpitAnimation {
                self.state.teethProgress -= 1
            }
        }
    }
    
    
    //MARK: Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let point = skView.convert(touch.location(in: self.skView), to: skView.scene!)
            let hitNodes = skView.scene?.nodes(at: point)
            let hitSprites = hitNodes?.filter({ $0 as? Node != nil}) as? [Node]
            if (hitNodes?.contains(mirrorCropNode) ?? false) && state.isBlurInitiallySetUp {
                let path = CGMutablePath()
                path.move(to: point)
                blurDict[touch] = (path, nil, nil)
            }
            if let hitNodes = hitSprites {
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
                } else if hitNodes.contains(nodes.spider) {
                    if state.flyState == .onWeb {
                        animator.runHeart()
                    } else {
                        animator.runAngrySpider()
                        animator.runDamage()
                    }
                }
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
                //                eraseBlur(location: point)
                eraseBlur2(touch: touch, location: point)
                
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let point = skView.convert(touch.location(in: self.skView), to: skView.scene!)
            let hitNodes = skView.scene?.nodes(at: point).filter({ $0 as? Node != nil}) as? [Node]
            updateNodesBeforeEndTouch(hitNodes, touch: touch)
        }
        
        for (node, touch) in nodeTouches where touches.contains(touch) {
            node.reset()
            nodeTouches[node] = nil
        }
        
        for touch in touches {
            let point = skView.convert(touch.location(in: self.skView), to: skView.scene!)
            let hitNodes = skView.scene?.nodes(at: point) as? [Node]
            updateNodesAfterEndTouch(hitNodes)
        }
        
        if !blurDict.isEmpty {
            checkBlurProgress()
        }
    }
    
    func updateNodesBeforeStartTouch(_ hitNodes: [Node]? = nil) {
        if let hitNodes = hitNodes {
            if hitNodes.contains(nodes.cupMagenta) && nodes.toothBrush.inUse {
                state.isToothbrushNotInCup = true
                let brush = nodes.toothBrush
                brush.initPoint = nodes.towel.initPoint
                brush.initPoint.y += 5
                brush.initPoint.x *= -1
                brush.initPoint.x += 20
                brush.initRotation += -0.9
            }
        }
    }
    
    func updateNodesAfterStartTouch(_ hitNodes: [Node] = []) {
        updateCupDraggability()
        if self.nodeTouches.keys.contains(nodes.razor) {
            animator.runRazorInUse()
        }
        if self.nodeTouches.keys.contains(nodes.toiletWater) && !state.isDeodorantFixed {
            deodorantMotion.start(rotationCallback: {_ in},
                                  accelerometerCallback: { data in
                                    self.startDeodorantAccelerationMonitoring(yAcceleration: data.acceleration.y)
            })
        }
    }
    
    func updateNodesBeforeEndTouch(_ hitNodes: [Node]? = nil, touch: UITouch) {
        if let hitNodes = hitNodes {
            if hitNodes.contains(nodes.cupMagenta) &&
                nodes.cupMagenta.isContactingWith(nodes.mouthBrushed) &&
                state.teethState == .needsRinsing &&
                state.isMagentaCupFilled &&
                !state.isMouthFlushing {
                putWaterInMouth()
            }
            
            if hitNodes.contains(nodes.bandage) && nodes.bandage.isContactingWith(nodes.pimple1Bleeidng) && nodes.pimple1Bleeidng.alpha > 0 {
                fixBleedingPimple()
            }
            if hitNodes.contains(nodes.toiletWater) &&
                nodes.toiletWater.isContactingWith(nodes.shirtZone) {
                spray()
            }
            if hitNodes.contains(nodes.stick) {
                if nodes.stickLeft.isContactingWith(nodes.earRight) &&
                    state.rightEarProgress > 0 &&
                    state.stickState == .reseted {
                    cleanEar(left: false)
                } else if nodes.stickRight.isContactingWith(nodes.earLeft) &&
                    state.leftEarProgress > 0 &&
                    state.stickState == .reseted {
                    cleanEar(left: true)
                } else {
                    nodes.stick.needsReset = true
                    state.stickState = .reseted
                }
            }
            if nodeTouches[nodes.toiletWater] == touch {
                if !state.isDeodorantFixed {
                    state.deodorantFixingProgress = 1
                }
                deodorantMotion.stop()
            }
        }
    }
    
    func updateNodesAfterEndTouch(_ hitNodes: [Node]? = nil) {
        updateCupDraggability()
    }
    
    func cleanEar(left: Bool) {
        let stick = nodes.stick
        stick.needsReset = false
        stick.zRotation = -0.25
        stick.xScale *= 0.7
        stick.yScale *= 0.7
        stick.zPosition = 0
        stick.draggable = false
        state.stickState = left ? .inLeftEar : .inRightEar
        if left {
            stick.position.y = nodes.earpieceLeft.position.y
            stick.position.x = nodes.earpieceLeft.position.x - stick.size.width / 2
            nodes.stickLeftSwipe.isHidden = false
        } else {
            stick.position.y = nodes.earpieceRight.position.y
            stick.position.x = nodes.earpieceRight.position.x + stick.size.width / 2
            nodes.stickRightSwipe.isHidden = false
        }
    }
    
    func spray() {
        guard !state.isShirtFixed && !state.isSmellFixed else { return }
        let deodorant = nodes.toiletWater
        deodorant.needsReset = false
        deodorant.position = nodes.shirtZone.position
        deodorant.position.x -= 100
        deodorant.draggable = false
        if !state.isDeodorantFixed {
            animator.runBadSpray {
                deodorant.needsReset = true
                deodorant.draggable = true
                deodorant.reset()
            }
        } else {
            animator.runGoodSpray {
                self.state.isSmellFixed = true
                deodorant.needsReset = true
                deodorant.draggable = true
                deodorant.reset()
                UIDevice.current.vibrate()
            }
        }
    }
    
    func eraseBlur2(touch: UITouch, location: CGPoint) {
        guard let path = blurDict[touch]?.path else { return }
        var line: SKShapeNode
        
        if let node = blurDict[touch]?.node {
            line = node
        } else {
            line = SKShapeNode(rectOf: nodes.mirrorShape.size)
        }
        
        path.addLine(to: location)
        line.path = path
        line.lineWidth = 120
        
        line.fillColor = .clear
        line.strokeColor = .white
        line.blendMode = .replace
        line.alpha = 0.0001
        line.lineCap = .round
        
        if blurDict[touch]?.node == nil {
            mirrorCropNode.maskNode?.addChild(line)
        }
        
        blurDict[touch]?.node = line
    }
    
    func checkBlurProgress() {
        guard state.waterTemprature != .hot  else {
            runBlurViewTimer2()
            return
        }
    }
    
    func startDeodorantAccelerationMonitoring(yAcceleration: Double) {
        
        if self.state.deodorantFixingProgress > 0 {
            if state.deodorantReachedLowerBound &&
                yAcceleration > 1.3 {
                UIDevice.current.vibrate()
                state.deodorantFixingProgress -= 1
                state.deodorantReachedLowerBound.toggle()
            } else if !state.deodorantReachedLowerBound &&
                yAcceleration < -1.3 {
                UIDevice.current.vibrate()
                state.deodorantFixingProgress -= 1
                state.deodorantReachedLowerBound.toggle()
            }
        } else {
            UIDevice.current.vibrate()
            deodorantMotion.stop()
            state.isDeodorantFixed = true
        }
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
    
    private func handleDeodorantShirtContact(contact: OrderedContactBodies<Contact>? = nil) {
        
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

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        currentFaceAnchor = faceAnchor
        
        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor == currentFaceAnchor,
            //            let contentNode = selectedContentController.contentNode,
            //            contentNode.parent == node,
            let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        //        selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
        
        face.update(faceAnchor)
        
        handleBrows()
        handleEyes()
        handleMouth()
        handleCheeks()
    }
}
