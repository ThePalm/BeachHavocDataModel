//
//  SceneObj.h
//  Beach Havoc
//
//  Created by Lewis W. Johnson on 6/19/14.
//  Copyright (c) 2014 Hamilton Holt Incorporated. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SceneObj : NSObject

@property (nonatomic, retain) NSString * sceneChaserName;
@property (nonatomic, retain) NSNumber * sceneChaserX;
@property (nonatomic, retain) NSNumber * sceneChaserY;
@property (nonatomic, retain) NSNumber * sceneGameNumber;
@property (nonatomic, retain) NSNumber * sceneSceneNumber;
@property (nonatomic, retain) NSNumber * sceneTimeInSeconds;
@property (nonatomic, retain) NSNumber * sceneZoom;
@property (nonatomic, retain) NSSet *targets;
@property (nonatomic, retain) NSSet *decorators;

@end

