//
//  SketchViewController.swift
//  ARKitFaceExample
//
//  Created by Max Tert on 30.03.2020.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import Sketch
import UIImageColors

class SketchViewController: UIViewController {
    
    @IBOutlet weak var sketchView: SketchView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var uiColorswLabel: UILabel!
    
    
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        sketchView.loadImage(image: image!)
        
        //        sketch.
        sketchView.drawTool = .eraser
        sketchView.lineWidth = 60
        sketchView.sketchViewDelegate = self
        imageView.isHidden = true
        let colors = image.getColors()
        imageView.contentMode = .scaleToFill
        // Do any additional setup after loading the view.
    }
}

extension SketchViewController: SketchViewDelegate {
    func drawView(_ view: SketchView, didEndDrawUsingTool tool: AnyObject) {
        let image = view.asImage()
        
        let skettcch = SketchView(frame: view.frame)
        skettcch.backgroundColor = .black
        skettcch.loadImage(image: image)
        
        let image2 = skettcch.asImage()
        let anus = image2.getColors()
        imageView.image = image2
        imageView.isHidden = false
        sketchView.isHidden = true
        
        uiColorswLabel.text = "\(anus!.background)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.imageView.isHidden = true
            self.sketchView.isHidden = false
        })
    }
}
