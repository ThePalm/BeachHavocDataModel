//
//  Game.h
//  Beach Havoc
//
//  Created by Lewis W. Johnson on 6/16/14.
//  Copyright (c) 2014 Hamilton Holt Incorporated. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Scene;

@interface Game : NSManagedObject

@property (nonatomic, retain) NSString * gameName;
@property (nonatomic, retain) NSNumber * gameNumber;
@property (nonatomic, retain) NSNumber * gamePurchased;
@property (nonatomic, retain) NSDate * gamePurchsedDate;
@property (nonatomic, retain) NSSet *scenes;
@end

@interface Game (CoreDataGeneratedAccessors)

- (void)addScenesObject:(Scene *)value;
- (void)removeScenesObject:(Scene *)value;
- (void)addScenes:(NSSet *)values;
- (void)removeScenes:(NSSet *)values;

@end
