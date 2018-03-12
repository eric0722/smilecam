//
//  RealTimeViewController.swift
//  CamCapV3
//
//  Created by Yee Choong Chan on 7/7/15.
//  Copyright (c) 2015 Yee Choong Chan. All rights reserved.
//



import UIKit
import AVFoundation
import GLKit
import AssetsLibrary
import AudioToolbox


func println(object:Any){
    //Swift.println(object)
}


class RealTimeViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session:AVCaptureSession = AVCaptureSession()
    var inputCameraBack:AVCaptureDeviceInput?
    var inputCameraFront:AVCaptureDeviceInput?
    var stillImageOutput:AVCaptureStillImageOutput?
    var sessionQueue: dispatch_queue_t?
    var deviceAuthorized: Bool  = false
    var separateQueue: dispatch_queue_t?
    
    var isUsingFrontFacingCamera:Bool?

    // Take pic check
    var shouldTakePic:Bool = false
    
    // Take pic conditions
    var isEveryoneSmiling:Bool = false
    var noOneIsBlinking:Bool = false
    
    //Face detection
    //var faceDetector:CIDetector?
    
    @IBOutlet weak var glView: cameraView!
    
    var glContext:EAGLContext?
    var context:CIContext?

    //Passing data
    var shouldDetectSmile = true
    var shouldDetectBlink = true
   
    
    //Check for device
    var isDeviceIpad:Bool {
        get{
            if UIDevice.currentDevice().model == "iPhone"{
                return false
            }else{
                return true
            }
        }
    }
    
    // Image Holder to pass to the next View Controller
    var processedImage:UIImage?
    var faceDetector:CIDetector?
    
    // MARK: View Outlets
   
    @IBOutlet weak var faceBookShareButton: UIButton!
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    
    //transform holder
    var transformHolder:CGAffineTransform?
    var buttonTransformHolder:CGAffineTransform?
    
    //MARK: View Controller LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        
        sessionQueue = dispatch_queue_create("session queue",DISPATCH_QUEUE_SERIAL)
        separateQueue = dispatch_queue_create("separate queue", DISPATCH_QUEUE_SERIAL)
        setupSessionWithDevice()
        checkDeviceAuthorizationStatus()
        
        dispatch_async(sessionQueue!, { () -> Void in
            if !self.session.running{
                self.session.startRunning()
            }
        })
 
        ///////////////////////////////////////////////////////////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        ///////////////////////////////////////////////////////////
        
        glContext = EAGLContext(API: .OpenGLES2)
        context = CIContext(EAGLContext: glContext, options: [kCIContextUseSoftwareRenderer: true])
        glView.enableSetNeedsDisplay = false
        glView.context = glContext
        glView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        glView.frame = self.view.bounds// Changed
        glView.bindDrawable()
        glView.viewBounds = CGRectMake(CGFloat(0), CGFloat(0),CGFloat(glView.drawableWidth), CGFloat(glView.drawableHeight))
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
            self.glView.transform = transform
            self.transformHolder = transform
            self.glView.frame =  self.view.bounds
        })
        
        
        ///////////////////////////////////////////////////////////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        ///////////////////////////////////////////////////////////
        
        //Face detector
//        let detectorOptions = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorTracking: true]
//        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: detectorOptions as [NSObject : AnyObject])
        
        let detectorOptions = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorTracking: true]
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: detectorOptions as [NSObject : AnyObject])
        
    
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
                self.navigationController?.navigationBarHidden = true
                let transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
                self.glView.transform = transform
                self.glView.frame =  self.view.bounds
        })
        
    }
    
    override func viewWillAppear(animated: Bool) {
     super.viewWillDisappear(animated)
        buttonTransformHolder = faceBookShareButton.transform
        dispatch_async(sessionQueue!, { () -> Void in
            let notificationCenter = NSNotificationCenter.defaultCenter()
            notificationCenter.addObserver(self, selector: "areaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.inputCameraBack?.device)
            UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
            notificationCenter.addObserver(self, selector: "orientationDidChange:", name: UIDeviceOrientationDidChangeNotification, object: nil)
            if !self.session.running{
                self.session.startRunning()
            }
        })
        
        isEveryoneSmiling = false
        shouldTakePic = false
        noOneIsBlinking = false

    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        dispatch_async(sessionQueue!, { () -> Void in
            let notificationCenter = NSNotificationCenter.defaultCenter()
            notificationCenter.removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.inputCameraBack?.device)
            notificationCenter.removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
            UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
            if self.loadingAnimation.isAnimating(){
                self.loadingAnimation.stopAnimating()
            }
            
            println("Session Stopping")
            if self.session.running{
                self.session.stopRunning()
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
      
        println("RealTimeViewCon View Did Appear")
    }
    
    
    //Mark: Authorization Check
    
    //Check for device Authorization
    func checkDeviceAuthorizationStatus(){
        var mediaType:String = AVMediaTypeVideo;
        
        AVCaptureDevice.requestAccessForMediaType(mediaType, completionHandler: {(granted: Bool) in
            if granted{
                self.deviceAuthorized = true;
            }else{
                
                dispatch_async(dispatch_get_main_queue(), {
                    var alert: UIAlertController = UIAlertController(
                        title: "AVCam",
                        message: "AVCam does not have permission to access camera",
                        preferredStyle: UIAlertControllerStyle.Alert);
                    
                    var action: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                        (action2: UIAlertAction!) in
                        exit(0);
                    } );
                    
                    alert.addAction(action);
                    
                    self.presentViewController(alert, animated: true, completion: nil);
                })
                
                self.deviceAuthorized = false;
            }
        })
        
    }
    
    // MARK: Delegate and Delegate Helper Method
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        

        
        //let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer)
        //let currentVideoDimension = CMVideoFormatDescriptionGetDimensions(formatDesc)
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = CIImage(CVPixelBuffer: pixelBuffer)
        
        ///////////////////////////////////////////////////////////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        ///////////////////////////////////////////////////////////
        
        
        let sourceExtent:CGRect = image.extent()
        
        let sourceAspect:CGFloat = sourceExtent.size.width/sourceExtent.size.height;
        

        var previewAspect:CGFloat = glView.viewBounds.size.width / glView.viewBounds.size.height
        
        var drawRect:CGRect = sourceExtent
        
        
        
        if sourceAspect > previewAspect{
            drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0
            
            drawRect.size.width = drawRect.size.height * previewAspect
            
            
        }else{
            
            drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0
            drawRect.size.height = drawRect.size.width / previewAspect
            
         
        }
        
        glView.bindDrawable()
        
        if self.glContext != EAGLContext.currentContext(){
            EAGLContext.setCurrentContext(self.glContext)
        }
        
        
        glClearColor(0.5, 0.5, 0.5, 1.0)
        glClear(UInt32(GL_COLOR_BUFFER_BIT))
        
        glEnable(UInt32(GL_BLEND));
        glBlendFunc(UInt32(GL_ONE), UInt32(GL_ONE_MINUS_SRC_ALPHA))
        
        if let image = image{
            
            context?.drawImage(image, inRect: glView.viewBounds, fromRect: drawRect)
            
        }
        
    
        glView.display()
        
        ///////////////////////////////////////////////////////////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        //////////OPENGL OPENGL OPENGL OPENGL OPENGL OPENGL ///////
        ///////////////////////////////////////////////////////////
        
        if shouldTakePic{
            var faceFeature = detectFaceWithCIImage(image)
            if let faceFeature = faceFeature{
                analyseFaceFeatureToSnapAndPushViewCon(faceFeature, sampleBuffer: sampleBuffer)
            }
        }else{
            return
        }
        
    }
    
    
     struct DeviceOrientation{
        static let PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1 //   1  =  0th row is at the top, and 0th column is on the left (TDEFAULT).
        static let PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2 //   2  =  0th row is at the top, and 0th column is on the right.
        static  let PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3 //   3  =  0th row is at the bottom, and 0th column is on the right.
        static  let PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4 //   4  =  0th row is at the bottom, and 0th column is on the left.
        static  let PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5 //   5  =  0th row is on the left, and 0th column is the top.
        static  let PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6 //   6  =  0th row is on the right, and 0th column is the top.
        static  let PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7 //   7  =  0th row is on the right, and 0th column is the bottom.
        static  let PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8 //   8  =  0th row is on the left, and 0th column is the bottom.
    }
    
    var orientation:UIDeviceOrientation?
 
    var orientationToDetect:Int{
        get{
            
            var exifOrientation : Int
            var curDeviceOrientation:UIDeviceOrientation
            
            if let tempOrientation = orientation{
                curDeviceOrientation = tempOrientation
            }else{
                curDeviceOrientation = UIDevice.currentDevice().orientation
            }
           
            switch curDeviceOrientation {
            case UIDeviceOrientation.PortraitUpsideDown:
                exifOrientation = DeviceOrientation.PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM
                //println("Portrait Upside down")
            case UIDeviceOrientation.LandscapeLeft:
                if isUsingFrontFacingCamera == true {
                    exifOrientation = DeviceOrientation.PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT
                } else {
                    exifOrientation = DeviceOrientation.PHOTOS_EXIF_0ROW_TOP_0COL_LEFT
                }
                //println("Landscape left")
            case UIDeviceOrientation.LandscapeRight:
                if isUsingFrontFacingCamera == true {
                    exifOrientation = DeviceOrientation.PHOTOS_EXIF_0ROW_TOP_0COL_LEFT
                } else {
                    exifOrientation = DeviceOrientation.PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT
                }
                //println("Landscape Right")
            default:
                exifOrientation = DeviceOrientation.PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP
                //println("Portrait ")
            }
            
            return exifOrientation
        }
    }
    
    
    
    var numberOfTimeToNewCIDetector:Int = 100
    var imageOptions:[String:NSNumber]{
        return [CIDetectorImageOrientation : NSNumber(integer: orientationToDetect), CIDetectorSmile : shouldDetectSmile, CIDetectorEyeBlink : shouldDetectBlink]
    }
    
    let detectorOptions = [CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorTracking: true]
    
    func detectFaceWithCIImage(image:CIImage)->[AnyObject]!{
        
        numberOfTimeToNewCIDetector--
        //println("\(numberOfTimeToNewCIDetector) till new Object")
        if numberOfTimeToNewCIDetector <= 0{
           // println("Restarted CIDectector Object")
                self.faceDetector = nil
            
                self.faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: detectorOptions as [NSObject : AnyObject])
                numberOfTimeToNewCIDetector = 100
        }
        
        //Face Detection
       // print(faceDetector)
        
//        let imageOptions = [CIDetectorImageOrientation : NSNumber(integer: orientationToDetect), CIDetectorSmile : shouldDetectSmile, CIDetectorEyeBlink : shouldDetectBlink]
       
//        println("Orientation is \(UIDevice.currentDevice().orientation)")
        
        let faceFeatures = faceDetector!.featuresInImage(image, options: imageOptions)
       
        return faceFeatures

}
    
    
    func analyseFaceFeatureToSnapAndPushViewCon(faceFeatures:[AnyObject]!, sampleBuffer:CMSampleBufferRef){
        if let feature =  faceFeatures as? [CIFaceFeature]{
            //glView.faceFeature = feature
            
            var numberOfFaces = feature.count
            println("Number of Faces is \(numberOfFaces)")
            if feature.count == 0{
                return
            }else{
                println("Should Detect Blink: \(shouldDetectBlink)")
                println("Should Detect Smile: \(shouldDetectSmile)")
                if shouldDetectSmile && shouldDetectBlink{
                    
                    //Detect Smile and Blink Code
                    for eachFeature in feature{
                        if eachFeature.hasSmile && !eachFeature.leftEyeClosed && !eachFeature.rightEyeClosed && (numberOfFaces>0){
                            numberOfFaces--
                            println(numberOfFaces)
                        }else{
                            return
                        }
                    }
                    
                } else if shouldDetectSmile{
                    //Detect Smile
                    
                    
                    for eachFeature in feature{
                        if eachFeature.hasSmile && (numberOfFaces>0){
                            numberOfFaces--
                        }else{
                            return
                        }
                    }
                    
                    
                } else if shouldDetectBlink{
                    //Detect Blink
                    
                    for eachFeature in feature{
                        if !eachFeature.leftEyeClosed && !eachFeature.rightEyeClosed && (numberOfFaces>0){
                            numberOfFaces--
                        }else{
                            return
                        }
                    }
                    
                    
                }else{
                    return
                }
                
                
            }
            
            if numberOfFaces == 0 && shouldTakePic{
                println("Fullfilled condition")
                isEveryoneSmiling = true
            }
            
            if shouldTakePic && isEveryoneSmiling{
                self.processedImage = self.imageFromSampleBuffer(sampleBuffer)
    
                
                if let image = processedImage{
                   
                    if session.running{
                        session.stopRunning()
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        //Code for capture sound
                        
                        
                        
                        if self.snapButton.hidden{
                            //Capture Sound
                            
                            self.snapButton.hidden = false
                            if self.loadingAnimation.isAnimating(){
                                self.loadingAnimation.stopAnimating()
                            }
                        }
                        AudioServicesPlaySystemSound(1108)
                        self.performSegueWithIdentifier("showImageDetail", sender:self)
                        
                    })
                    
                }else{
                    println("No Image")
                }
            }
            
        }
    }

    
    // MARK: Set Up Session
    
    func setupSessionWithDevice(){
        
        //Setting Device with certain type
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        
        
        //Setting Capture Input Device
        for device  in devices{
            let device = device as! AVCaptureDevice
            
            if device.position == .Back{
                inputCameraBack = AVCaptureDeviceInput(device: device as AVCaptureDevice, error: nil)
            }
            
            if device.position == .Front{
                inputCameraFront = AVCaptureDeviceInput(device: device as AVCaptureDevice, error: nil)
            }
        }
        
        //Add input to session created
        if let inputCamera = inputCameraBack{
            if session.canAddInput(inputCamera){
                session.addInput(inputCamera)
                isUsingFrontFacingCamera = false
            }else{
                println("Failed to add Input")
            }
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey:1111970369] // 3 Possible value for kCVPixelBufferPixelFormatTypeKey are [875704438][875704422][1111970369]
        videoOutput.setSampleBufferDelegate(self, queue: separateQueue!)
        if session.canAddOutput(videoOutput){
            session.addOutput(videoOutput)
        }
        
        //Creating Session
        dispatch_async(sessionQueue!, { () -> Void in
            
            let canSetSession = self.session.canSetSessionPreset(AVCaptureSessionPresetPhoto)
            if canSetSession{
                
                self.session.sessionPreset = AVCaptureSessionPresetPhoto

            }else{
                println("Cannot set AVCaptureSessionPresetPhoto")
            }
        })
    }
    

    
    //MARK: Focusing and Exposure Mode modifier at runtime. 
    //Use method uses 1 of the 2 serial queue. 1 of the serial queue is used for AVCaptureVideoDataOutput delegate method that runs everytime. So this queue will only be initiated after a long time due to characteristics of serial queue of starting another work after the previous work is done.
    //2 queues solves this problem
    func focusWithMode(focusMode:AVCaptureFocusMode,exposureMode:AVCaptureExposureMode,point:CGPoint,monitorSubjectAreaChange:Bool){
       
        
        dispatch_async(sessionQueue!, { () -> Void in
            
            var error:NSError?
          
            if let inputCameraBack = self.inputCameraBack{
                let device = inputCameraBack.device
                
                if device.lockForConfiguration(&error){
                    
                    if device.isFocusModeSupported(focusMode) && device.focusPointOfInterestSupported{
                        
                        device.focusPointOfInterest = point
                        device.focusMode = focusMode
                    }
                    
                    if device.isExposureModeSupported(exposureMode) && device.exposurePointOfInterestSupported{
                        
                        //Must have the point of interest before the exposure mode to expose the desired effect changing the position will will not yield the desired result
                        device.exposurePointOfInterest = point
                        device.exposureMode = exposureMode
                        
                    }
                    
                    device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                    
                }
            }
            
            //New code for exposure adjustment for front Camera
            
            if let inputCameraFront = self.inputCameraFront{
                let device = inputCameraFront.device
                
                if device.lockForConfiguration(&error){
                    
                    if device.isFocusModeSupported(focusMode) && device.focusPointOfInterestSupported{
                        
                        device.focusPointOfInterest = point
                        device.focusMode = focusMode
                    }
                    
                    if device.isExposureModeSupported(exposureMode) && device.exposurePointOfInterestSupported{
                        
                        //Must have the point of interest before the exposure mode to expose the desired effect changing the position will will not yield the desired result
                        device.exposurePointOfInterest = point
                        device.exposureMode = exposureMode
                        
                    }
                    
                    device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                    
                }
            }
        })
    }
    
    
    
    
    // MARK: Action
    
    @IBAction func snapTriggered(sender: UIButton) {
        snapImage()
    }
    
    
    @IBAction func didTappedToFocus(sender: UITapGestureRecognizer) {
        
        let origin = sender.locationInView(sender.view);
        let focusPoint = CGPointMake(-(origin.y / glView.bounds.size.height)+1, -(1 - origin.x / glView.bounds.size.width)+1);
        focusWithMode(AVCaptureFocusMode.AutoFocus, exposureMode: AVCaptureExposureMode.AutoExpose, point: focusPoint, monitorSubjectAreaChange: true)

//        let focusPoint = CGPointMake((origin.y / glView.bounds.size.height), (1 - origin.x / glView.bounds.size.width));
//        focusWithMode(AVCaptureFocusMode.AutoFocus, exposureMode: AVCaptureExposureMode.AutoExpose, point: focusPoint, monitorSubjectAreaChange: true)
    }
    
    
    @IBAction func didTappedSwitchCamera(sender:UIButton){
        
        dispatch_async(sessionQueue!, { () -> Void in
            self.session.beginConfiguration()
            
            if self.isUsingFrontFacingCamera!{
                
                self.session.removeInput(self.inputCameraFront)
                self.session.addInput(self.inputCameraBack)
                self.isUsingFrontFacingCamera = false
                
            }else{
                
                self.session.removeInput(self.inputCameraBack)
                self.session.addInput(self.inputCameraFront)
                self.isUsingFrontFacingCamera = true
                
            }
            
            self.session.commitConfiguration()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if self.isUsingFrontFacingCamera!{
                    //For Correct Camera Display
                    self.glView.transform = CGAffineTransformConcat(self.transformHolder!, CGAffineTransformMakeScale(-1.0, 1.0))
                }else{
                    //For Correct Camera Display
                    self.glView.transform = CGAffineTransformConcat(self.transformHolder!, CGAffineTransformMakeScale(1.0, 1.0))
                }
                
            })
        })
        
    }

    @IBAction func didTappedShowSettings(sender: UIButton) {
        performSegueWithIdentifier("showSettings", sender: self)
    }

    // MARK: Selector
    
    func areaDidChange(notification:NSNotification){

        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focusWithMode(AVCaptureFocusMode.ContinuousAutoFocus, exposureMode: AVCaptureExposureMode.ContinuousAutoExposure, point: devicePoint, monitorSubjectAreaChange: false)
        
    }
    
    func orientationDidChange(notification:NSNotification){
        orientation = UIDevice.currentDevice().orientation
        let transformToUse:CGAffineTransform?
        
        if isDeviceIpad{
            
            switch orientation!{
            case .LandscapeLeft:
                transformToUse = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
            case .LandscapeRight:
                transformToUse = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
            default:
                transformToUse = buttonTransformHolder
            }
            
            if let transform = transformToUse{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        self.faceBookShareButton.transform = transform
                        self.snapButton.transform = transform
                        self.settingsButton.transform = transform
                    })
                })
            }
        }
    
    }

    @IBOutlet weak var loadingAnimation: UIActivityIndicatorView!
    func snapImage(){
        loadingAnimation.startAnimating()
        snapButton.hidden = true
        shouldTakePic = true
    }

    // MARK: Image Processing Method
    
    private func imageFromSampleBuffer(sampleBuffer :CMSampleBufferRef) -> UIImage {
        
        let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        let baseAddress: UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent: UInt = 8
        
        var bitmapInfo = CGBitmapInfo((CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue) as UInt32)
        if(bitmapInfo == nil){
            println("bitmapInfo is nil")
        }
        let newContext: CGContextRef = CGBitmapContextCreate(baseAddress, width, height, Int(bitsPerCompornent), bytesPerRow, colorSpace, bitmapInfo) as CGContextRef
       
        let imageRef: CGImageRef = CGBitmapContextCreateImage(newContext)
        let resultImage = UIImage(CGImage: imageRef, scale: 1.0, orientation: UIImageOrientation.Right)!

        CVPixelBufferUnlockBaseAddress(imageBuffer,0)
        return resultImage
    }
    
    // MARK: Segue Method
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        snapButton.hidden = false
        loadingAnimation.stopAnimating()
        
        
        if let identifier = segue.identifier{
            
            switch identifier{
                
            case "showImageDetail":
                
                let destinationViewCon = segue.destinationViewController as! DetailViewConViewController
                destinationViewCon.image = processedImage
                destinationViewCon.orientationWhenImageWasTaken = UIDevice.currentDevice().orientation
                destinationViewCon.isUsingFrontCamera  = isUsingFrontFacingCamera
                
            case "showSettings":
                
               if let destinationViewCon = segue.destinationViewController as? SettingViewController{
                
                    destinationViewCon.isSmileDetectActivate = shouldDetectSmile
                    destinationViewCon.isBlinkDetectActivate = shouldDetectBlink
                
                }
                
            default:
                return
            }
        }
    }
    
    


    
}
