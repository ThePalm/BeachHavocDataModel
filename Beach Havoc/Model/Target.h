//
//  Target.h
//  Beach Havoc
//
//  Created by Lewis W. Johnson on 6/27/14.
//  Copyright (c) 2014 Hamilton Holt Incorporated. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Scene;

@interface Target : NSManagedObject

@property (nonatomic, retain) NSNumber * targetDoesBounceOrBlock;
@property (nonatomic, retain) NSNumber * targetDoesRetaliate;
@property (nonatomic, retain) NSString * targetLeftRight;
@property (nonatomic, retain) NSNumber * targetRetaliateRunIterations;
@property (nonatomic, retain) NSString * targetRunDirection;
@property (nonatomic, retain) NSString * targetRunDirection2;
@property (nonatomic, retain) NSString * targetRunDirection3;
@property (nonatomic, retain) NSNumber * targetRunIterations;
@property (nonatomic, retain) NSNumber * targetSceneNumber;
@property (nonatomic, retain) NSString * targetType;
@property (nonatomic, retain) NSNumber * targetX;
@property (nonatomic, retain) NSNumber * targetY;
@property (nonatomic, retain) NSNumber * targtDoesAddLife;
@property (nonatomic, retain) NSString * targetName;
@property (nonatomic, retain) NSNumber * targetIndex;
@property (nonatomic, retain) Scene *scene;

@end
