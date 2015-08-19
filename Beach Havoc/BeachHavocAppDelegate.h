//
//  BeachHavocAppDelegate.h
//  Beach Havoc
//
//  Created by Lewis Johnson on 10/14/12.
//  Copyright (c) 2012 Hamilton Holt Incorporated. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BeachHavocViewController;
@class HHICoreDataManager;
@class CHHIModel;
@class Target;
@class TargetView;

@interface BeachHavocAppDelegate : UIResponder <UIApplicationDelegate>
{
    @public int worldnumber;
    @public int lastplayedscenenumber;
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BeachHavocViewController *viewController;

@end
