//
//  BeachHavocViewController.m
//  Beach Havoc
//
//  Created by Lewis Johnson on 8/22/11.
//  Copyright Pending 2012 __Hamilton_Holt_Incorporated_. All rights reserved.//

#import "BeachHavocViewController.h"
#import <UIKit/UIKit.h>
#import "BeachHavocAppDelegate.h"

@implementation BeachHavocViewController


- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    hhiappDelegate = (BeachHavocAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    UIApplication *app = [UIApplication sharedApplication];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:app];
    
  }


- (void)viewDidUnload;
{
    
}


// End of View Controller

@end
