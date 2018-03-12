//
//  SettingViewController.swift
//  CamCapV4
//
//  Created by Yee Choong Chan on 7/13/15.
//  Copyright (c) 2015 Yee Choong Chan. All rights reserved.
//

import UIKit



class SettingViewController: UIViewController {
    @IBOutlet weak var smileSwitch: UISwitch!
    @IBOutlet weak var blinkSwitch: UISwitch!
    
    var isSmileDetectActivate:Bool? = true
    var isBlinkDetectActivate:Bool? = true
   
    
    @IBOutlet weak var smileLabelDescription: UILabel!
    @IBOutlet weak var blinkLabelDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        #if FREE
            canDisplayBannerAds = true
        #endif

        smileLabelDescription.numberOfLines = 0
        blinkLabelDescription.numberOfLines = 0
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.setNavigationBarHidden(false, animated: true)
        //navigationController?.navigationBarHidden = false
        smileSwitch.on = isSmileDetectActivate!
        blinkSwitch.on = isBlinkDetectActivate!
        
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = "Settings"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
    }

    @IBAction func switchSmile(sender: UISwitch) {
        isSmileDetectActivate = !isSmileDetectActivate!
        
    }

    
    @IBAction func switchBlink(sender: UISwitch) {
        isBlinkDetectActivate = !isBlinkDetectActivate!
    }
}
