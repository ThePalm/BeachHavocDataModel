//
//  BeachHavocViewController.h
//  Beach Havoc
//
//  Created by Lewis Johnson on 10/14/12.
//  Copyright (c) 2012 Hamilton Holt Incorporated. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class BeachHavocAppDelegate;

@interface BeachHavocViewController : UIViewController <UIScrollViewDelegate>
{
#define TARGET_HEIGHT 24
#define NUMBEROFSCENES 128 //32
    
    CATransition *transitionin;
    CATransition *transitionout;
    
@public BeachHavocAppDelegate *hhiappDelegate;
    

    
    
    
}
// prototypes



@end
