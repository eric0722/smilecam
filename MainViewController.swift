//
//  MainViewController.swift
//  CamCapV4
//
//  Created by Yee Choong Chan on 7/9/15.
//  Copyright (c) 2015 Yee Choong Chan. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBAction func unwind(segue:UIStoryboardSegue){
        let vc = segue.sourceViewController as? SettingViewController
        let childVC = childViewControllers[0] as? RealTimeViewController
        if let childVC = childVC{
            childVC.shouldDetectSmile = vc!.isSmileDetectActivate!
            childVC.shouldDetectBlink = vc!.isBlinkDetectActivate!
        }
        
    }

}
