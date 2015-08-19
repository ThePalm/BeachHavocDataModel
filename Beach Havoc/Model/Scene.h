//
//  Scene.h
//  Beach Havoc
//
//  Created by Lewis W. Johnson on 7/23/14.
//  Copyright (c) 2014 Hamilton Holt Incorporated. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game, OccupierDecorator, Target;

@interface Scene : NSManagedObject

@property (nonatomic, retain) NSString * sceneChaserName;
@property (nonatomic, retain) NSNumber * sceneChaserX;
@property (nonatomic, retain) NSNumber * sceneChaserY;
@property (nonatomic, retain) NSNumber * sceneGameNumber;
@property (nonatomic, retain) NSNumber * sceneSceneNumber;
@property (nonatomic, retain) NSNumber * sceneTimeInSeconds;
@property (nonatomic, retain) NSNumber * sceneZoom;
@property (nonatomic, retain) NSSet *decorators;
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) NSSet *targets;
@end

@interface Scene (CoreDataGeneratedAccessors)

- (void)addDecoratorsObject:(OccupierDecorator *)value;
- (void)removeDecoratorsObject:(OccupierDecorator *)value;
- (void)addDecorators:(NSSet *)values;
- (void)removeDecorators:(NSSet *)values;

- (void)addTargetsObject:(Target *)value;
- (void)removeTargetsObject:(Target *)value;
- (void)addTargets:(NSSet *)values;
- (void)removeTargets:(NSSet *)values;

@end
