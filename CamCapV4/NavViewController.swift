//
//  NavViewController.swift
//  CamCapV4
//
//  Created by Yee Choong Chan on 7/10/15.
//  Copyright (c) 2015 Yee Choong Chan. All rights reserved.
//

import UIKit

class NavViewController: UINavigationController {
    override func shouldAutorotate() -> Bool {
        
        //MUST NO ALLOW ROTATION FOR BOTH IPHONE AND IPAD
        if UIDevice.currentDevice().model == "iPhone"{
            return false
        }else{
            return true
        }
        
        

    }
    
    override func supportedInterfaceOrientations() -> Int {
//        if UIDevice.currentDevice().model == "iPhone"{
//            return Int(UIInterfaceOrientationMask.Portrait.rawValue)
//        }else{
//            return super.supportedInterfaceOrientations()
//        }
       return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    

}
