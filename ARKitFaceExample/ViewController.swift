/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import ARKit
import SceneKit
import UIKit
import Foundation

class ViewController: UIViewController, ARSessionDelegate {
    
    // MARK: Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var skView: SKView!
    
    private var nodes: Nodes!
    private var nodeTouches: [Node: UITouch] = [:]
    let face = FaceTracker()
    
    private var isTakingDamage: Bool = false
    private var isColdWaterOn: Bool = false
    private var isHotWaterOn: Bool = false
    private var currentRightHair: SKSpriteNode!
    
    private var hairMoveStartLocation: CGPoint?
    private let minDistance:CGFloat = 25
    
    private var teethProgress: Int = 4
    
    private var isMouthBusy: Bool = false
    private var isMouthFlushing: Bool = false
    
    private var isMagentaCupFilled: Bool = false
    private var isPurpleCupFilled: Bool = false
      
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
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.scene?.physicsWorld.contactDelegate = self
        nodes = Nodes(scene: skView.scene)
        runWaterAnimation()
        runSteamAnimaition()
        runFlyAnimation()
        createGestures()
        currentRightHair = nodes.hairRightInitial
        
        createPhyscisBodies()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }
    
    func createPhyscisBodies() {
        
        // Hair
        let hairScale = CGAffineTransform(scaleX: 0.4, y: 0.35)
        let leftHairInitial = SKPhysicsBody(rectangleOf: nodes.hairLeftInitial.size.applying(hairScale))
        let leftHairFixed = SKPhysicsBody(rectangleOf: nodes.hairLeftFixed.size.applying(hairScale))
        let rightHairInitial = SKPhysicsBody(rectangleOf: nodes.hairRightInitial.size.applying(hairScale))
        let rightHairFixedRight = SKPhysicsBody(rectangleOf: nodes.hairRightFixedRight.size.applying(hairScale))
        let rightHairFixedLeft = SKPhysicsBody(rectangleOf: nodes.hairRightFixedLeft.size.applying(hairScale))
        let rightHairFixedUp = SKPhysicsBody(rectangleOf: nodes.hairRightFixedUp.size.applying(hairScale))
        let rightHairFixedDown = SKPhysicsBody(rectangleOf: nodes.hairRightFixedDown.size.applying(hairScale))
        
        let hairBodies: [SKPhysicsBody] = [leftHairInitial, leftHairFixed,
                                           rightHairInitial, rightHairFixedRight,
                                           rightHairFixedLeft, rightHairFixedUp, rightHairFixedDown]
        for body in hairBodies {
            body.affectedByGravity = false
            body.contactTestBitMask = Contact.comb.rawValue
            body.categoryBitMask = Contact.hair.rawValue
            body.collisionBitMask = Contact.other.rawValue
        }
        
        nodes.hairLeftInitial.physicsBody = leftHairInitial
        nodes.hairLeftFixed.physicsBody = leftHairFixed
        nodes.hairRightInitial.physicsBody = rightHairInitial
        nodes.hairRightFixedRight.physicsBody = rightHairFixedRight
        nodes.hairRightFixedLeft.physicsBody = rightHairFixedLeft
        nodes.hairRightFixedUp.physicsBody = rightHairFixedUp
        nodes.hairRightFixedDown.physicsBody = rightHairFixedDown
        
        // Comb
        
        let combScale = CGAffineTransform(scaleX: 0.75, y: 0.75)
        let comb = SKPhysicsBody(rectangleOf: nodes.comb.size.applying(combScale))
        comb.affectedByGravity = false
        comb.contactTestBitMask = Contact.hair.rawValue
        comb.categoryBitMask = Contact.comb.rawValue
        comb.collisionBitMask = Contact.other.rawValue
        
        nodes.comb.physicsBody = comb
        
        // Toothbrush
        
        let toothBrush = SKPhysicsBody(circleOfRadius: 30)
        toothBrush.affectedByGravity = false
        toothBrush.contactTestBitMask = Contact.teeth.rawValue
        toothBrush.categoryBitMask = Contact.toothBrush.rawValue
        toothBrush.collisionBitMask = Contact.other.rawValue
        
        nodes.toothBrush.physicsBody = toothBrush
        
        // Teeth
        let teethScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        let jawTop = SKPhysicsBody(rectangleOf: nodes.jawTop.size.applying(teethScale))
        jawTop.affectedByGravity = false
        jawTop.contactTestBitMask = Contact.toothBrush.rawValue
        jawTop.categoryBitMask = Contact.teeth.rawValue
        jawTop.collisionBitMask = Contact.other.rawValue
        
        nodes.jawTop.physicsBody = jawTop
        
        let jawBottom = SKPhysicsBody(rectangleOf: nodes.jawBottom.size.applying(teethScale))
        jawBottom.affectedByGravity = false
        jawBottom.contactTestBitMask = Contact.toothBrush.rawValue
        jawBottom.categoryBitMask = Contact.teeth.rawValue
        jawBottom.collisionBitMask = Contact.other.rawValue
        
        nodes.jawBottom.physicsBody = jawBottom
        
        // Water
        
        let waterScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        let water = SKPhysicsBody(rectangleOf: nodes.water.size.applying(waterScale))
        water.affectedByGravity = false
        water.contactTestBitMask = Contact.cup.rawValue
        water.categoryBitMask = Contact.water.rawValue
        water.collisionBitMask = Contact.other.rawValue
        
        nodes.water.physicsBody = water
        
        // Cups
        
        let cupScale = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        let cupPurple = SKPhysicsBody(rectangleOf: nodes.cupPurple.size.applying(cupScale))
        cupPurple.affectedByGravity = false
        cupPurple.contactTestBitMask = Contact.water.rawValue
        cupPurple.categoryBitMask = Contact.cup.rawValue
        cupPurple.collisionBitMask = Contact.other.rawValue
        
        nodes.cupPurple.physicsBody = cupPurple
        
        let cupMagenta = SKPhysicsBody(rectangleOf: nodes.cupMagenta.size.applying(cupScale))
        cupMagenta.affectedByGravity = false
        cupMagenta.contactTestBitMask = Contact.water.rawValue
        cupMagenta.categoryBitMask = Contact.cup.rawValue
        cupMagenta.collisionBitMask = Contact.other.rawValue
        
        nodes.cupMagenta.physicsBody = cupMagenta
    }
    
    //MARK: Animations
    
    func runDamageAnimation() {
        guard !isTakingDamage else { return }
        isTakingDamage = true
        let changeTexture = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_eyes_damaged.name))
        let changeTextureBack = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_eyes_default.name))
        let pause = SKAction.wait(forDuration: 1)
        let returnToDefaultState = SKAction.customAction(withDuration: 0.0, actionBlock: { _,_ in
            self.nodes.leftEyeBall.isHidden = false
            self.nodes.rightEyeBall.isHidden = false
            self.isTakingDamage = false
        })
        
        let rotateClockwise = SKAction.rotate(byAngle: 0.3, duration: 0)
        let rotateOppositClockwise = SKAction.rotate(byAngle: -0.3, duration: 0)
        
        let leftBrowSequence = SKAction.sequence([rotateOppositClockwise, pause, rotateClockwise])
        let rightBrowSequence = SKAction.sequence([rotateClockwise, pause, rotateOppositClockwise])
        
        nodes.leftBrow.run(leftBrowSequence)
        nodes.rightBrow.run(rightBrowSequence)
        
        nodes.leftEyeBall.isHidden = true
        nodes.rightEyeBall.isHidden = true
        
        let eyesSequence = SKAction.sequence([changeTexture, pause, changeTextureBack, returnToDefaultState])
        nodes.eyes.run(eyesSequence)
    }
    
    func runWaterAnimation() {
        let changeTexture1 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_water2.name))
        let changeTexture2 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_water3.name))
        let changeTexture3 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_water1.name))
        let pause = SKAction.wait(forDuration: 0.15)
        let sequence = SKAction.sequence([changeTexture1, pause, changeTexture2, pause, changeTexture3, pause])
        
        nodes.water.run(SKAction.repeatForever(sequence))
        nodes.water.isHidden = true
    }
    
    func runFlyAnimation() {
        let changeWings1 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_fly_wings_2.name))
        let changeWings2 = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_fly_wings_1.name))
        let pause = SKAction.wait(forDuration: 0.1)
        let wingsSequence = SKAction.sequence([pause, changeWings1, pause, changeWings2])
        
        let noseScale1 = SKAction.scale(to: 1.6, duration: 0.5)
        let noseScale2 = SKAction.scale(to: 1, duration: 0.5)
        let noseSequence = SKAction.sequence([noseScale1, noseScale2])
        
        let leftPointStart = nodes.fly.initPoint
        let leftPointFinish = CGPoint(x: leftPointStart.x, y: leftPointStart.y - 130)
        let rightPointStart = CGPoint(x: -leftPointStart.x, y: leftPointStart.y - 130)
        let rightPointFinish = CGPoint(x: -leftPointStart.x, y: leftPointStart.y)
        
        let moveRight = SKAction.move(to: rightPointFinish, duration: 2)
        let moveDown = SKAction.move(to: rightPointStart, duration: 4)
        let moveLeft = SKAction.move(to: leftPointFinish, duration: 2)
        let moveUp = SKAction.move(to: leftPointStart, duration: 4)
        
        let flip = SKAction.customAction(withDuration: 0, actionBlock: { _,_ in
            self.nodes.fly.xScale *= -1
        })
        
        let changeZPos = SKAction.customAction(withDuration: 0, actionBlock: { _,_  in
            self.nodes.fly.zPosition = self.nodes.fly.zPosition == 0 ? -2 : 0
        })
        
        let flySequence = SKAction.sequence([moveRight, moveDown, changeZPos, flip,
                                             moveLeft, moveUp, flip, changeZPos])
        
        nodes.flyWings.run(SKAction.repeatForever(wingsSequence))
        nodes.flyNose.run(SKAction.repeatForever(noseSequence))
        nodes.fly.run(SKAction.repeatForever(flySequence))
    }
    
    func rotateColdValve(angle: CGFloat) {
        let rotate = SKAction.rotate(byAngle: angle, duration: 0.5)
        nodes.coldValve.run(rotate)
    }
    
    func rotateHotValve(angle: CGFloat) {
        let rotate = SKAction.rotate(byAngle: angle, duration: 0.5)
        nodes.hotValve.run(rotate)
    }
    
    func updateWaterState() {
        nodes.water.isHidden = !(isHotWaterOn || isColdWaterOn)
        let steamCondition = isHotWaterOn && !isColdWaterOn
        nodes.steam1.isHidden = !steamCondition
        nodes.steam2.isHidden = !steamCondition
        nodes.steam3.isHidden = !steamCondition
        let coldCraneAction = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_crane_cold.name))
        let defaultCraneAction = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_tap_crane_default.name))
        if isColdWaterOn && !isHotWaterOn {
            nodes.crane.run(coldCraneAction)
        } else {
            nodes.crane.run(defaultCraneAction)
        }
    }
    
    func animateNodeChange(oldNode: SKSpriteNode?, newNode: SKSpriteNode?, duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration, animations: {
            oldNode?.alpha = 0
            newNode?.alpha = 1
        })
    }
    
    func updateLeftHairState(direction: UISwipeGestureRecognizer.Direction) {
        guard direction == .left else { return }
        animateNodeChange(oldNode: nodes.hairLeftInitial, newNode: nodes.hairLeftFixed)
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
        animateNodeChange(oldNode: currentRightHair, newNode: fixedHair)
        currentRightHair = fixedHair
        
    }
    
    func showBrushedMouth() {
        
    }
    
    func updateCupDraggability() {
        nodes.cupMagenta.draggable = nodes.toothBrush.inUse
        nodes.cupPurple.draggable = nodes.razor.inUse
    }
    
    func updateTeeth() {
//        if teethProgress == 4 {
//            nodes.toothBrush.xScale = nodes.toothBrush.initXScale
//            nodes.toothBrush.yScale = nodes.toothBrush.initYScale
//            let changeBrush = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_toothbrush.name), resize: false)
//            nodes.toothBrush.run(changeBrush)
//            nodes.toothBrush.xScale = nodes.toothBrush.initXScale * 1.5
//            nodes.toothBrush.yScale = nodes.toothBrush.initYScale * 1.5
//        }
        
        if teethProgress == 0 {
            isMouthBusy = true
            updateCheeksAlpha()
            let topAction = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_jaw_top_fixed.name))
            let bottomAction = SKAction.setTexture(SKTexture(imageNamed: R.image.bath_jaw_bottom_fixed.name))
            nodes.jawTop.run(topAction)
            nodes.jawBottom.run(bottomAction)
        } else {
            teethProgress -= 1
            UIDevice.current.vibrate()
        }
    }
    
    func runSteamAnimaition() {
        let scale = SKAction.scale(to: 1.5, duration: 2)
        let appear = SKAction.fadeAlpha(to: 1, duration: 0.8)
        let fade = SKAction.fadeAlpha(to: 0, duration: 0.8)
        let resetScale = SKAction.scale(to: 1, duration: 0)
        let pause = SKAction.wait(forDuration: 2)
        let appearGroup = SKAction.group([scale, appear])
        let sequence = SKAction.sequence([appearGroup,fade, resetScale])
        nodes.steam1.run(SKAction.repeatForever(sequence))
        nodes.steam2.run(SKAction.repeatForever(SKAction.sequence([pause, sequence])))
        nodes.steam3.run(SKAction.repeatForever(SKAction.sequence([pause, pause, sequence])))
        nodes.steam1.isHidden = true
        nodes.steam2.isHidden = true
        nodes.steam3.isHidden = true
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
            UIView.animate(withDuration: 0.5, animations: {
                self.nodes.pimple1Initial.alpha = 0
                self.nodes.pimple1Bleeidng.alpha = 1
            })
            runDamageAnimation()
        } else if firstHitNodes.contains(nodes.pimple2Pinch) && secondHitNodes.contains(nodes.pimple2Pinch) {
            UIDevice.current.vibrate()
            nodes.pimple2Pinch.isHidden = true
            UIView.animate(withDuration: 0.5, animations: {
                self.nodes.pimple2.alpha = 0
            })
        }
    }
    
    @objc
    func handleSwipes(sender: UISwipeGestureRecognizer) {
        let point = skView.convert(sender.location(in: self.skView), to: skView.scene!)
        guard let hitNodes = skView.scene?.nodes(at: point) else { return }
        if hitNodes.contains(nodes.coldValve) {
            switch sender.direction {
            case .down:
                guard !isColdWaterOn else { return }
                isColdWaterOn = true
                rotateColdValve(angle: -1)
                updateWaterState()
            case .up:
                guard isColdWaterOn else { return }
                isColdWaterOn = false
                rotateColdValve(angle: 1)
                updateWaterState()
            default:
                print("no such direction for cold valve")
            }
        }
        
        if hitNodes.contains(nodes.hotValve) {
            switch sender.direction {
            case .down:
                guard !isHotWaterOn else { return }
                isHotWaterOn = true
                rotateHotValve(angle: -1)
                updateWaterState()
            case .up:
                guard isHotWaterOn else { return }
                isHotWaterOn = false
                rotateHotValve(angle: 1)
                updateWaterState()
            default:
                print("no such direction for cold valve")
            }
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
        nodes.leftCheek.alpha = isMouthFlushing ? 1 : 0
        nodes.rightCheek.alpha = isMouthFlushing ? 1 : 0
    }
    
    func putWaterInMouth() {
        UIDevice.current.vibrate()
        isMouthFlushing = true
        updateCheeksAlpha()
    }
    
    func updateMouthAlpha(show: Bool) {
        let mouthItems: [SKNode] = [
            nodes.jawBottom,
            nodes.lipBottom,
            nodes.jawTop,
            nodes.lipTop,
            nodes.mouthInside
        ]
        
        let showTeeth = show && !isMouthBusy
        
        nodes.mouthBrushed.alpha = isMouthBusy ? 1 : 0
        nodes.mouthDefault.alpha = (isMouthBusy || show) ? 0 : 1
        
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
        
        nodes.leftCheek.xScale = nodes.leftCheek.initXScale + cheeks * 0.1
        nodes.leftCheek.yScale = nodes.leftCheek.initYScale + cheeks * 0.1
        nodes.rightCheek.xScale = nodes.rightCheek.initXScale + cheeks * 0.1
        nodes.rightCheek.yScale = nodes.rightCheek.initYScale + cheeks * 0.1
    }
    
    
    //MARK: Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = skView.convert(touch.location(in: self.skView), to: skView.scene!)
            guard let hitNodes = skView.scene?.nodes(at: point) as? [Node] else { return }
            
            if let draggableHitNode = hitNodes.first(where: { $0.draggable }) {
                draggableHitNode.inUse = true
                draggableHitNode.xScale = draggableHitNode.initXScale * 1.5
                draggableHitNode.yScale = draggableHitNode.initYScale * 1.5
                draggableHitNode.position = point
                draggableHitNode.zPosition = 10
                nodeTouches[draggableHitNode] = touch
                
                updateCupDraggability()
            } else if hitNodes.contains(nodes.water) && !(isHotWaterOn && isColdWaterOn) {
                runDamageAnimation()
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
        guard let hitNodes = skView.scene?.nodes(at: point) as? [Node] else { return }
            if hitNodes.contains(nodes.cupPurple) {
                if hitNodes.contains(nodes.mouthBrushed) && isPurpleCupFilled {
                    putWaterInMouth()
                }
            }
            
            if hitNodes.contains(nodes.cupMagenta) {
                if hitNodes.contains(nodes.mouthBrushed) && isMagentaCupFilled {
                    putWaterInMouth()
                }
            }
        }
        
        for (node, touch) in nodeTouches where touches.contains(touch) {
            node.xScale = node.initXScale
            node.yScale = node.initYScale
            node.position = node.initPoint
            node.zPosition = 0
            node.inUse = false
            nodeTouches[node] = nil
        }
        
        updateCupDraggability()
    }
    
    func checkSwipe(touch: UITouch) -> UISwipeGestureRecognizer.Direction? {
        if let startLocation = hairMoveStartLocation {
            let location = touch.location(in: skView.scene!)
            let dx = location.x - startLocation.x
            let dy = location.y - startLocation.y
            let distance = sqrt(dx*dx+dy*dy)
            self.hairMoveStartLocation = nil
            // Check if the user's finger moved a minimum distance
            if distance > minDistance {
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
        guard hairMoveStartLocation == nil else { return }
        hairMoveStartLocation = nodeTouches[nodes.comb]!.location(in: skView.scene!)
    }
    
    func handleBrushTeethContact(contact: SKPhysicsContact) {
        
    }
    
    private func handleCupWaterContact(contact: OrderedContactBodies<Contact>) {
        if let node = contact.other.body.node as? Node, node == nodes.cupMagenta {
            isMagentaCupFilled = true
            UIDevice.current.vibrate()
        } else if let node = contact.other.body.node as? Node, node == nodes.cupPurple {
            isPurpleCupFilled = true
            UIDevice.current.vibrate()
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
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        if let _ = contact.orderedBodies(for: [Contact.comb, .hair]) {
            hairMoveStartLocation = nil
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

private extension ViewController {
    class Nodes {
        let leftBrow: Node
        let rightBrow: Node
        let leftEyeBall: Node
        let rightEyeBall: Node
        let mouthDefault: Node
        let jawTop: Node
        let jawBottom: Node
        let lipTop: Node
        let lipBottom: Node
        let mouthInside: Node
        let water: Node
        let steam1: Node
        let steam2: Node
        let steam3: Node
        let pimple1Initial: Node
        let pimple1Bleeidng: Node
        let pimple1Fixed: Node
        let pimple2: Node
        let pimple1Pinch: Node
        let pimple2Pinch: Node
        let toothBrush: Node
        let razor: Node
        let towel: Node
        let wetTowel: Node
        let bandage: Node
        let toiletWater: Node
        let comb: Node
        let eyes: Node
        let coldValve: Node
        let hotValve: Node
        let crane: Node
        let hairLeftInitial: Node
        let hairLeftFixed: Node
        let hairRightInitial: Node
        let hairRightFixedLeft: Node
        let hairRightFixedRight: Node
        let hairRightFixedUp: Node
        let hairRightFixedDown: Node
        let leftCheek: Node
        let rightCheek: Node
        let mouthBrushed: Node
        let mouthBrushedWater: Node
        let fallingWater1: Node
        let fallingWater2: Node
        let fallingWater3: Node
        let fly: Node
        let flyBody: Node
        let flyNose: Node
        let flyWings: Node
        let cupMagenta: Node
        let cupPurple: Node
        
        init(scene: SKScene?) {
            
            func setupNode(name: String, parentNode: SKSpriteNode? = nil, draggable: Bool = false) -> Node {
                if let child = parentNode?.childNode(withName: name) as? Node {
                    child.setup(draggable: draggable)
                    return child
                } else if let child = scene?.childNode(withName: name) as? Node {
                    child.setup(draggable: draggable)
                    return child
                } else {
                    fatalError("No such node for Bath GameScene: \(name)")
                }
            }
            
            leftBrow = setupNode(name: R.string.bath.left_brow())
            rightBrow = setupNode(name: R.string.bath.right_brow())
            leftEyeBall = setupNode(name: R.string.bath.left_eyeball())
            rightEyeBall = setupNode(name: R.string.bath.right_eyeball())
            jawTop = setupNode(name: R.string.bath.jaw_top())
            jawBottom = setupNode(name: R.string.bath.jaw_bottom())
            lipTop = setupNode(name: R.string.bath.lip_top())
            lipBottom = setupNode(name: R.string.bath.lip_bottom())
            mouthInside = setupNode(name: R.string.bath.mouth_inside())
            mouthDefault = setupNode(name: R.string.bath.mouth_default())
            water = setupNode(name: R.string.bath.water())
            steam1 = setupNode(name: R.string.bath.steam1())
            steam2 = setupNode(name: R.string.bath.steam2())
            steam3 = setupNode(name: R.string.bath.steam3())
            pimple1Initial = setupNode(name: R.string.bath.pimple1_initial())
            pimple1Bleeidng = setupNode(name: R.string.bath.pimple1_bleedning())
            pimple1Fixed = setupNode(name: R.string.bath.pimple1_fixed())
            pimple2 = setupNode(name: R.string.bath.pimple2())
            pimple1Pinch = setupNode(name: R.string.bath.pimple1_pinch_zone())
            pimple2Pinch = setupNode(name: R.string.bath.pimple2_pinch_zone())
            eyes = setupNode(name: R.string.bath.eyes())
            coldValve = setupNode(name: R.string.bath.cold_valve())
            hotValve = setupNode(name: R.string.bath.hot_valve())
            crane = setupNode(name: R.string.bath.crane())
            hairLeftInitial = setupNode(name: R.string.bath.hair_left_initial())
            hairLeftFixed = setupNode(name: R.string.bath.hair_left_fixed())
            hairRightInitial = setupNode(name: R.string.bath.hair_right_initial())
            hairRightFixedLeft = setupNode(name: R.string.bath.hair_right_fixed_left())
            hairRightFixedRight = setupNode(name: R.string.bath.hair_right_fixed_right())
            hairRightFixedUp = setupNode(name: R.string.bath.hair_right_fixed_up())
            hairRightFixedDown = setupNode(name: R.string.bath.hair_right_fixed_down())
            leftCheek = setupNode(name: R.string.bath.left_cheek())
            rightCheek = setupNode(name: R.string.bath.right_cheek())
            mouthBrushed = setupNode(name: R.string.bath.mouth_brushed())
            mouthBrushedWater = setupNode(name: R.string.bath.mouth_brushed_water())
            fallingWater1 = setupNode(name: R.string.bath.water_falling1())
            fallingWater2 = setupNode(name: R.string.bath.water_falling2())
            fallingWater3 = setupNode(name: R.string.bath.water_falling3())
            fly = setupNode(name: R.string.bath.fly())
            flyBody = setupNode(name: R.string.bath.fly_body(), parentNode: fly)
            flyNose = setupNode(name: R.string.bath.fly_nose(), parentNode: fly)
            flyWings = setupNode(name: R.string.bath.fly_wings(), parentNode: fly)
            cupMagenta = setupNode(name: R.string.bath.magenta_cup())
            cupPurple = setupNode(name: R.string.bath.purple_cup())
            
            toothBrush = setupNode(name: R.string.bath.toothbrush(), draggable: true)
            razor = setupNode(name: R.string.bath.razor(), draggable: true)
            towel = setupNode(name: R.string.bath.towel_dry(), draggable: true)
            wetTowel = setupNode(name: R.string.bath.towel_wet(), draggable: true)
            bandage = setupNode(name: R.string.bath.bandage(), draggable: true)
            toiletWater = setupNode(name: R.string.bath.toilet_water(), draggable: true)
            comb = setupNode(name: R.string.bath.comb(), draggable: true)
            
        }
    }
}

private extension ViewController {
    enum Contact: UInt32, PhysicsCategory {
        
        var mask: UInt32 {
            return self.rawValue
        }
        
        static func create(value: UInt32) -> PhysicsCategory? {
            return Contact(rawValue: value)
        }
        
        case other = 0
        case comb = 1
        case hair = 2
        case teeth = 4
        case toothBrush = 8
        case cup = 16
        case water = 32
    }
}


extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
