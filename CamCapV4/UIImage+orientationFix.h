//
//  UIImage+orientationFix.h
//  CamCapV4
//
//  Created by Yee Choong Chan on 7/13/15.
//  Copyright (c) 2015 Yee Choong Chan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (orientationFix)
//Fixing image orientation code will use it soon.
//Could try changing AVCaptureConnection properties (videoOrientation) to configure the image orientation. Will Try soon
- (UIImage *)fixOrientation;
- (UIImage *)normalizedImage;
@end
