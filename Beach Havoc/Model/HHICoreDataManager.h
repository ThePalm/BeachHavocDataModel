//
//  HHICoreDataManager.h
//
//  Created by Lewis Johnson on 7/12/14.
//  Copyright (c) 2014 Hamilton Holt Incorporated. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Game.h"
#import "Scene.h"
#import "Target.h"
#import "OccupierDecorator.h"

#import "TargetObj.h"
#import "SceneObj.h"
#import "OccupierObj.h"


@interface HHICoreDataManager : NSObject

+ (HHICoreDataManager *)sharedManager;

- (NSManagedObjectContext *)mainThreadContext;

+ (NSManagedObjectContext *)backgroundContext;

+ (NSManagedObjectContext *)backgroundContextNoUndo;

+ (NSPersistentStoreCoordinator *)dbPersistentStoreCoordinator;

- (void)saveContext:(NSManagedObjectContext *)context;

+ (void)deleteDatabase;

- (void) addOrUpdateGame:(NSString *) gameName gameNumber:(int)gameNumber;
- (void) addOrUpdateTarget:(TargetObj *) target;
- (void) addOrUpdateScene:(Scene *) scene;
- (void) addOrUpdateOccupierDecorator:(OccupierDecorator *) occupierdecoratorobj;

- (Game *)getgameByID:(NSNumber *) gameNumber;

- (NSArray *)getScenesByGameID:(NSNumber *) sceneNumber;

- (NSArray *)getTargetsBySceneID:(NSNumber *) targetscene;

- (Target *)getTargetByName:(NSString *) targetname;

- (NSArray *)getOccupersBySceneID:(NSNumber *) occupierscene;

- (Scene *)getSceneByID:(NSNumber *) sceneNumber;

- (Target *)getTargetBySceneIDandIndex:(NSNumber *) targetscene targetindex:(NSNumber *) targetsindex;

- (Scene *) newScene;


//- (NSManagedObject *) objectWithID:(NSManagedObjectID *)objectID;
- (NSFetchedResultsController *)newFetchedResultsControllerForEntity:(NSString *)entityName
													   sortedFirstBy:(NSString *)firstSort
														 thenByOrNil:(NSString *)secondSort
														 thenByOrNil:(NSString *)thirdSort
													 filteredByOrNil:(NSPredicate *)filterPredicate
												  sectionNameKeyPath:(NSString *)sectionNameKeyPath
															delegate:(id <NSFetchedResultsControllerDelegate>) delegate ;



@end
