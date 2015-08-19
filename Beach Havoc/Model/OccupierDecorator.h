//
//  OccupierDecorator.h
//  Beach Havoc
//
//  Created by Lewis W. Johnson on 6/23/14.
//  Copyright (c) 2014 Hamilton Holt Incorporated. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Scene;

@interface OccupierDecorator : NSManagedObject

@property (nonatomic, retain) NSString * occupierImageFile;
@property (nonatomic, retain) NSString * occupierName;
@property (nonatomic, retain) NSString * occupierOrientation;
@property (nonatomic, retain) NSNumber * occupierSceneNumber;
@property (nonatomic, retain) NSNumber * occupierSize;
@property (nonatomic, retain) NSNumber * occupierX;
@property (nonatomic, retain) NSNumber * occupierY;
@property (nonatomic, retain) Scene *scenes; // plural name but only one

@end
