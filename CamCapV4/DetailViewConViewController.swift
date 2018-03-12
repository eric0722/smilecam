//
//  DetailViewConViewController.swift
//  CamCapV4
//
//  Created by Yee Choong Chan on 7/11/15.
//  Copyright (c) 2015 Yee Choong Chan. All rights reserved.
//

import UIKit
import AssetsLibrary
import Social
import CoreGraphics
import iAd

class DetailViewConViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var image:UIImage?
    let qualityOfService:Int = Int(QOS_CLASS_BACKGROUND.value)
    var savingQueue:dispatch_queue_t?
    var orientationWhenImageWasTaken:UIDeviceOrientation?
    var isUsingFrontCamera:Bool?
    
    
    
    // MARK: View Controller LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        savingQueue = dispatch_get_global_queue(qualityOfService, 0)
        
        #if FREE
        canDisplayBannerAds = true
        #endif
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.navigationBarHidden = false
        imageView.clipsToBounds = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //Temporary Solution to solve image orientation display. Have to solve it in future use
        rotate()
        imageView.image = image
        imageView.clipsToBounds = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBarHidden = true
    }

    
    // MARK: Actions
    @IBAction func saveImageToPhotoAlbum(sender: UIButton) {
        
    dispatch_async(savingQueue!, { () -> Void in
        let libaray:ALAssetsLibrary = ALAssetsLibrary()
        let orientation: ALAssetOrientation = ALAssetOrientation(rawValue: self.image!.imageOrientation.rawValue)!
        libaray.writeImageToSavedPhotosAlbum(self.image?.CGImage, orientation: orientation, completionBlock: nil)
    })
        
        navigationController?.popViewControllerAnimated(true)
        
    }

    @IBAction func shareOnFacebook(sender: UIButton) {
        //Facebook Share Code
        let isServiceAvailable = SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook)
        if isServiceAvailable{
            var socialViewCon = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            socialViewCon.addImage(image)
            presentViewController(socialViewCon, animated: true, completion: nil)
        }else{
            //UIAlertViewController only usable in iOS8 and above. 
            /*

            Have to add code to support iOS 7 for UIAlertViewController. Please check documentation for more details.

            */
           
    
            let alertViewCon = UIAlertController(title: "Facebook sharing not available", message: "Unable to share on Facebook. Please ensure you have configure your facebook acoount in the settings", preferredStyle: .ActionSheet)
            let action = UIAlertAction(title: "OK", style:.Cancel, handler: nil)
            alertViewCon.addAction(action)
            presentViewController(alertViewCon, animated: true, completion: nil)
        }
    }
        
    @IBAction func shareOnTwitter(sender: UIButton) {
        //Twitter Share Code
        let isServiceAvailable = SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)
        if isServiceAvailable{
            var socialViewCon = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            socialViewCon.addImage(image)
            presentViewController(socialViewCon, animated: true, completion: nil)
        }else{
            //UIAlertViewController only usable in iOS8 and above.
            /*
            
            Have to add code to support iOS 7 for UIAlertViewController. Please check documentation for more details.
            
            */
            let alertViewCon = UIAlertController(title: "Twitter sharing not available", message: "Unable to share on Twitter. Please ensure you have configure your twitter acoount in the settings", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style:.Cancel, handler: nil)
            alertViewCon.addAction(action)
            presentViewController(alertViewCon, animated: true, completion: nil)
        }
    }
    
    func rotate(){
        
        func radians(degree:Double)->Double{
            return (degree * M_PI) / 180
        }
        
        if isUsingFrontCamera!{
            switch orientationWhenImageWasTaken!{
            case .LandscapeLeft:
                imageView.transform = CGAffineTransformMakeRotation(CGFloat(radians(90)))
            case .LandscapeRight:
                imageView.transform = CGAffineTransformMakeRotation(CGFloat(radians(-90)))
            case .PortraitUpsideDown:
                imageView.transform = CGAffineTransformMakeRotation(CGFloat(radians(180)))
            default:
                break
            }
        }else{
            
            switch orientationWhenImageWasTaken!{
            case .LandscapeLeft:
                imageView.transform = CGAffineTransformMakeRotation(CGFloat(radians(-90)))
            case .LandscapeRight:
                imageView.transform = CGAffineTransformMakeRotation(CGFloat(radians(90)))
            case .PortraitUpsideDown:
                imageView.transform = CGAffineTransformMakeRotation(CGFloat(radians(180)))
            default:
                break
            }
            
        }
        
        
        imageView.clipsToBounds = true
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
   

}
