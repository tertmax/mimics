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
        
        imageView.isHidden = true
        let colors = image.getColors()
        imageView.contentMode = .scaleToFill
        // Do any additional setup after loading the view.
    }
}
