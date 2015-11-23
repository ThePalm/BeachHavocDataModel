//
//  HHICoreDataManager.m
//
//  Created by Lewis Johnson on 7/12/14.
//  Copyright (c) 2014 Hamilton Holt Incorporated. All rights reserved.

#import "HHICoreDataManager.h"

#define ENTITY_SCENE @"Scene"
#define ENTITY_TARGET @"Target"
#define ENTITY_GAME @"Game"
#define ENTITY_OCCUPIER @"OccupierDecorator"


@interface HHICoreDataManager ()

@property (nonatomic, strong) NSManagedObjectContext *mainThreadContext;

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator; 

@end


@implementation HHICoreDataManager

#pragma mark - Convenience Constructor & Init

+ (HHICoreDataManager *)sharedManager
{
    static dispatch_once_t onceToken = 0;
    
    __strong static id _sharedObject = nil;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init
{
    if(self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Public Class Methods

+ (NSManagedObjectContext *)mainThreadContext
{
    return [HHICoreDataManager sharedManager].mainThreadContext;
}

+ (NSManagedObjectContext *)backgroundContext
{
    return [HHICoreDataManager sharedManager].backgroundContext;
}

+ (NSManagedObjectContext *)backgroundContextNoUndo
{
    //return [HHICoreDataManager sharedManager].backgroundContext;
    return [HHICoreDataManager sharedManager].backgroundContextNoUndo;
}

+ (NSPersistentStoreCoordinator *)dbPersistentStoreCoordinator
{
    return [[HHICoreDataManager sharedManager] persistentStoreCoordinator];
}

+ (void)saveContext:(NSManagedObjectContext *)context
{
    [[HHICoreDataManager sharedManager] saveContext:context];
}

+ (void)deleteDatabase
{
    [[HHICoreDataManager sharedManager] deleteDatabase];
}

#pragma mark - Private Methods

- (void)managedObjectContextDidSave:(NSNotification *)saveNotification
{
    if(saveNotification.object != self.mainThreadContext) {
        [self.mainThreadContext mergeChangesFromContextDidSaveNotification:saveNotification];
    }
}

- (void)saveContext:(NSManagedObjectContext *)managedObjectContext
{
    NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
//#warning "Remove the abort() prior release"
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            //abort();
        }
    }
}

- (void)deleteDatabase
{
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BeachHavoc.db"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path])
    {
        NSError *deleteError;
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&deleteError];
    }
    
    
    _mainThreadContext = nil;
    _persistentStoreCoordinator = nil;
    _managedObjectModel = nil;
    
}


- (void) deleteAllObjects: (NSString *) entityDescription  {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:_mainThreadContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [_mainThreadContext executeFetchRequest:fetchRequest error:&error];
    
    
    
    for (NSManagedObject *managedObject in items) {
        [_mainThreadContext deleteObject:managedObject];
        NSLog(@"%@ object deleted",entityDescription);
    }
 
    [self saveContext:_mainThreadContext];
}


#pragma mark Core Data stack


- (NSManagedObjectContext *)mainThreadContext
{
    if (_mainThreadContext) {
        return _mainThreadContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        _mainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainThreadContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _mainThreadContext;
}


- (NSManagedObjectContext *)backgroundContext
{
    NSManagedObjectContext *backgroundContext;
    
    NSPersistentStoreCoordinator *coordinator = nil;
    
    coordinator = [self persistentStoreCoordinator];
    if (coordinator)
    {
        backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [backgroundContext setPersistentStoreCoordinator:coordinator];
        return backgroundContext;
    }
    else
    {
        return nil;
    }
    
    
}

- (NSManagedObjectContext *)backgroundContextNoUndo
{
    NSManagedObjectContext *backgroundContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator)
    {
        backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [backgroundContext setUndoManager:nil];
        [backgroundContext setPersistentStoreCoordinator:coordinator];
        return backgroundContext;
    }
    else
    {
        return nil;
    }
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BeachHavoc" withExtension:@"momd"]; //use mom not momd when you create it yourself
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }

    // persistent store creation below will use our db file that we copy in from the bundle
    
    NSString * DBPathInBundle = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BeachHavoc.data"];
    NSError *error;
  //  NSLog(@"db location from Coredata Manager mainBundle =%@",DBPathInBundle);
    
    NSURL *storeURLinDocFolder = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BeachHavoc.db"];
  //  NSLog(@"db location from Coredata Manager doc folder =%@",storeURLinDocFolder);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURLinDocFolder.path])
    {
  //      NSLog(@"destination DB file allready exists.");
        NSError * error4;
        BOOL success4 = [[NSFileManager defaultManager] removeItemAtPath:storeURLinDocFolder.path error:&error4];
        if (!success4)
        {
  //          NSLog(@"Error removing empty DB file in doc folder at path: %@", error4.localizedDescription);
        }
    }
    else
    {
  //      NSLog(@"destination DB not exist file path OK!");
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:DBPathInBundle])
    {
 //       NSLog(@"populated DB in Bundle found.");
    }
    else
    {
  //      NSLog(@"populated DB in Bundle not found.");
    }
    
    if([[NSFileManager defaultManager] copyItemAtPath:DBPathInBundle toPath:storeURLinDocFolder.path error:&error]) // copy the original to the documents folder
    {
 //       NSLog(@"DB file successfully copied over.");
    }
    else
    {
        NSLog(@"Error description-%@ \n", [error localizedDescription]);
        NSLog(@"Error reason-%@", [error localizedFailureReason]);
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURLinDocFolder
                                                        options:@{@"journal_mode":@"delete"} error:&error])
    {
        NSLog(@"Error adding persistent store: %@", error);
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

#pragma mark Application's Business  UI, Create, Read, Update, and Delete Operations

#pragma mark - Counts

- (int ) countEntitiesForName:(NSString *)entityName forPredicateOrNil:(NSPredicate *)filterPredicate
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:self.mainThreadContext];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setIncludesSubentities:NO];
    
    if (filterPredicate != nil)
    {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    NSError *error = nil;
    NSUInteger count = [self.mainThreadContext countForFetchRequest: fetchRequest error: &error];
    
    int entityCount = 0;
    if(error == nil){
        entityCount = (int)count;
    }
    
    return entityCount;
}

- (NSFetchedResultsController *)newFetchedResultsControllerForEntity:(NSString *)entityName
                                                       sortedFirstBy:(NSString *)firstSort
                                                         thenByOrNil:(NSString *)secondSort
                                                         thenByOrNil:(NSString *)thirdSort
                                                     filteredByOrNil:(NSPredicate *)filterPredicate
                                                  sectionNameKeyPath:(NSString *)sectionNameKeyPath
                                                            delegate:(id <NSFetchedResultsControllerDelegate>) delegate
{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.mainThreadContext];
    
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:3];
    
    if (firstSort!=nil)
    {
        // change it here for sorting specific entity descending
        
    }
    if (secondSort!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:secondSort ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    if (thirdSort!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:thirdSort ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithArray:sortDescriptors]];
    
    if (filterPredicate != nil)
    {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:self.mainThreadContext
                                                                                                  sectionNameKeyPath:sectionNameKeyPath
                                                                                                           cacheName:nil];
    if (delegate != nil)
    {
        aFetchedResultsController.delegate = delegate;
    }
    return aFetchedResultsController;
}


#pragma mark - Custom methods to create new managed objects 
//*********************** S C E N E ***********************************
- (Scene *) newScene
{
    Scene * scene =[NSEntityDescription insertNewObjectForEntityForName:ENTITY_SCENE inManagedObjectContext:self.mainThreadContext];
    return scene;
}



#pragma mark - Custom methods to add or update entities


-(void) addOrUpdateScene:(Scene *) scene
{
    
    if (scene==nil )
    {
        NSLog(@"************** Danger Will Robinson !!! ********************");
        return;
    }
    Scene *localscene = [self newScene];
    
    localscene.sceneChaserName                  =scene.sceneChaserName;
    localscene.sceneChaserX                     =scene.sceneChaserX;
    localscene.sceneChaserY                     =scene.sceneChaserY;
    localscene.sceneGameNumber                  =scene.sceneGameNumber;
    localscene.sceneSceneNumber                 =scene.sceneSceneNumber;
    localscene.sceneTimeInSeconds               =scene.sceneTimeInSeconds;
    localscene.sceneZoom                        =scene.sceneZoom;

    NSLog(@"Writing a Scene");
    [self saveContext:_mainThreadContext];

    
}

#pragma mark - Custom Counters

- (int) numberOfScenes;
{
    return [self countEntitiesForName:ENTITY_SCENE forPredicateOrNil:nil];}

- (NSArray *)getScenes
{
    
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_SCENE
                                                                                        sortedFirstBy:@"sceneNumber"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:nil
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
		NSLog(@"Error Fetching %@: %@",ENTITY_SCENE,[error localizedDescription]);
    
	return fetchedResultsController.fetchedObjects;
}


- (Scene *)getSceneByID:(NSNumber *) sceneNumber;
{
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_SCENE
                                                                                        sortedFirstBy:@"sceneSceneNumber" // these as needed per business rules
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:[NSPredicate predicateWithFormat:@"sceneSceneNumber ==%d",[sceneNumber intValue]]
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
    
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching %@: %@",ENTITY_SCENE,[error localizedDescription]);
        return nil;
    }
    
    if ([fetchedResultsController.fetchedObjects count]>1)
    {
        NSLog(@"ERROR. There are more than one Scene for the sceneSceneNumber in %@.",sceneNumber);
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    if ([fetchedResultsController.fetchedObjects count]==1)
    {
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    
	return nil;
}

-(NSArray *)getScenesByGameID:(NSNumber *) sceneNumber;
{
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_SCENE
                                                                                        sortedFirstBy:@"sceneSceneNumber" // these as needed per business rules
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:[NSPredicate predicateWithFormat:@"sceneGameNumber ==%d",[sceneNumber intValue]]
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
    
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching %@: %@",ENTITY_SCENE,[error localizedDescription]);
        return nil;
    }
    
    if ([fetchedResultsController.fetchedObjects count]>1)
    {
        NSLog(@"ERROR. There are more than one Scene for the sceneNumber in %@.",sceneNumber);
        return fetchedResultsController.fetchedObjects;
    }
    if ([fetchedResultsController.fetchedObjects count]==1)
    {
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    
	return nil;
}


//*********************** E N D       S C E N E ***********************************

//*********************** G A M E  ***********************************

-(Game *) newGame
{
    Game * game =[NSEntityDescription insertNewObjectForEntityForName:ENTITY_GAME inManagedObjectContext:self.mainThreadContext];
    return game;
}

#pragma mark - Custom methods to add or update entities




-(void) addOrUpdateGame:(NSString *) gameName gameNumber:(int)gameNumber;
{
    
    if (gameName==nil)
    {
        return;
    }
    
    Game *game = [self newGame];
    
    game.gameName = gameName;
    game.gameNumber = [NSNumber numberWithInt:gameNumber];
    
    NSLog(@"Writing an Game");
    [self saveContext:_mainThreadContext];

    
}

#pragma mark - Custom Counters

- (int) numberOfGames;
{
    
    return [self countEntitiesForName:ENTITY_GAME forPredicateOrNil:nil];
}

- (NSArray *)getGames
{
    
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_GAME
                                                                                        sortedFirstBy:@"gameNumber"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:nil
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
		NSLog(@"Error Fetching %@: %@",ENTITY_TARGET,[error localizedDescription]);
    
	return fetchedResultsController.fetchedObjects;
}

- (Game *)getgameByID:(NSNumber *) gameNumber;
{
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_GAME
                                                                                        sortedFirstBy:@"gameNumber"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:[NSPredicate predicateWithFormat:@"gameNumber ==%d",[gameNumber intValue]]
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
    
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching %@: %@",ENTITY_GAME,[error localizedDescription]); 
        return nil;
    }
    
    if ([fetchedResultsController.fetchedObjects count]>1)
    {
        NSLog(@"ERROR. There is more than one Game for the gameNumber in %d.",[gameNumber intValue]);
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    if ([fetchedResultsController.fetchedObjects count]==1)
    {
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    
	return nil;
}

//*********************** E N D       G A M E  ***********************************

//*********************** T A R G E T  ***********************************

- (Target *) newTarget
{
    
    Target * target =[NSEntityDescription insertNewObjectForEntityForName:ENTITY_TARGET inManagedObjectContext:self.mainThreadContext];
    return target;
}


-(void) addOrUpdateTarget:(TargetObj *) target;
{
    
    if (target==nil )
    {
         NSLog(@"************** Danger Will Robinson !!! ********************");
        return;
    }
    Target *localtarget = [self newTarget];
    
    localtarget.targetDoesBounceOrBlock      = target.targetDoesBounceOrBlock;
    localtarget.targetDoesRetaliate          = target.targetDoesRetaliate;
    localtarget.targetLeftRight              = target.targetLeftRight;
    localtarget.targetRetaliateRunIterations = target.targetRetaliateRunIterations;
    localtarget.targetRunDirection           = target.targetRunDirection;
    localtarget.targetRunDirection2          = target.targetRunDirection2;
    localtarget.targetRunDirection3          = target.targetRunDirection3;
    localtarget.targetRunIterations          = target.targetRunIterations;
    localtarget.targetSceneNumber            = target.targetSceneNumber;
    localtarget.targetType                   = target.targetType;
    localtarget.targetX                      = target.targetX;
    localtarget.targetY                      = target.targetY;
    localtarget.targtDoesAddLife             = target.targetDoesAddLife;
    localtarget.targetIndex                  = target.targetIndex;
    
    NSLog(@"Writing a Target X = :%@ Y = :%@ ",[localtarget.targetX stringValue], [localtarget.targetY stringValue]);
    
    [self saveContext:_mainThreadContext];

}

#pragma mark - Custom Counters

- (int) numberOfTargets;
{
    return [self countEntitiesForName:ENTITY_TARGET forPredicateOrNil:nil];
}

- (NSArray *)getTargets
{
    
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_TARGET
                                                                                        sortedFirstBy:@"targetType"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:nil
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
		NSLog(@"Error Fetching %@: %@",ENTITY_TARGET,[error localizedDescription]);
    
	return fetchedResultsController.fetchedObjects;
}

- (Target *)getTargetByName:(NSString *) targetname;
{
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_TARGET
                                                                                        sortedFirstBy:@"targetname"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:[NSPredicate predicateWithFormat:@"targetname ==%@",targetname]
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
    
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching %@: %@",ENTITY_TARGET,[error localizedDescription]);
        return nil;
    }
    
    if ([fetchedResultsController.fetchedObjects count]>1)
    {
        NSLog(@"ERROR. There are more than one Target for the targetName in %@.",targetname);
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    if ([fetchedResultsController.fetchedObjects count]==1)
    {
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    
	return nil;
}


- (NSArray *)getTargetsBySceneID:(NSNumber *) targetscene;
{
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_TARGET
                                                                                        sortedFirstBy:@"targetIndex"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:[NSPredicate predicateWithFormat:@"targetSceneNumber ==%d",[targetscene intValue]]
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
    
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching %@: %@",ENTITY_TARGET,[error localizedDescription]);
        return nil;
    }
    
    if ([fetchedResultsController.fetchedObjects count]>1)
    {
        NSLog(@"ERROR. There are more than one Target for the targetType in %@.",targetscene);
        return fetchedResultsController.fetchedObjects;
    }
    if ([fetchedResultsController.fetchedObjects count]==1)
    {
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    
	return nil;
}


- (Target *)getTargetBySceneIDandIndex:(NSNumber *) targetscene targetindex:(NSNumber *) targetsindex
{
    NSFetchedResultsController *fetchedResultsController =
    [self newFetchedResultsControllerForEntity:ENTITY_TARGET
                                                                        sortedFirstBy:@"targetIndex"
                                                                        thenByOrNil:nil
                                                                        thenByOrNil:nil
                                                                        filteredByOrNil:[NSPredicate predicateWithFormat:@"targetIndex ==%d AND targetSceneNumber == %d",[targetsindex intValue],[targetscene intValue]]
                                                                        sectionNameKeyPath:nil
                                                                        delegate:nil ];
    
    NSLog(@"Target.targetIndex ==%d AND Target.targetSceneNumber == %d",[targetsindex intValue],[targetscene intValue]);
    
    
	NSError *error;
    
	if (![fetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching %@: %@",ENTITY_TARGET,[error localizedDescription]);
        return nil;
    }
    
    if ([fetchedResultsController.fetchedObjects count]>1)
    {
        NSLog(@"ERROR. There are more than one Target for the SceneNumber:%@ and Index: %@.",targetscene,targetsindex);
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    if ([fetchedResultsController.fetchedObjects count]==1)
    {
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    
	return nil;
}

//*********************** E N D     T A R G E T  ***********************************
//*********************** O C C U P I E R  ***********************************

- (OccupierDecorator *) newOccupierDecorator
{
    
    OccupierDecorator * occupierDecorator =[NSEntityDescription insertNewObjectForEntityForName:ENTITY_OCCUPIER inManagedObjectContext:self.mainThreadContext];
    return occupierDecorator;

    
}


-(void) addOrUpdateOccupierDecorator:(OccupierObj *) occupierdecoratorobj;
{
    
    if (occupierdecoratorobj==nil )
    {
        NSLog(@"************** Danger Will Robinson occupierdecorator!!! ********************");
        return;
    }
    
    OccupierDecorator *localoccupierdecorator = [self newOccupierDecorator];
    
    localoccupierdecorator.occupierX                =occupierdecoratorobj.occupierX;
    localoccupierdecorator.occupierY                =occupierdecoratorobj.occupierY;
    localoccupierdecorator.occupierSceneNumber      =occupierdecoratorobj.occupierSceneNumber;
    localoccupierdecorator.occupierSize             =occupierdecoratorobj.occupierSize;
    localoccupierdecorator.occupierSceneNumber      =occupierdecoratorobj.occupierSceneNumber;
    localoccupierdecorator.occupierImageFile        =occupierdecoratorobj.occupierImageFile;
    localoccupierdecorator.occupierOrientation      =occupierdecoratorobj.occupierOrientation;
    
    NSLog(@"Writing a OccupierDecorator");
    
    [self saveContext:_mainThreadContext];

    
}

#pragma mark - Custom Counters

- (int) numberOfOccupierDecorators;
{
    return [self countEntitiesForName:ENTITY_TARGET forPredicateOrNil:[NSPredicate predicateWithFormat:nil]];
}

- (NSArray *)getOccupierDecorators
{
    
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_OCCUPIER
                                                                                        sortedFirstBy:@"occupierName"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:nil
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
		NSLog(@"Error Fetching %@: %@",ENTITY_OCCUPIER,[error localizedDescription]);
    
	return fetchedResultsController.fetchedObjects;
}


- (OccupierDecorator *)getoccupierdecoratorByID:(NSString *) occupierName;
{
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_OCCUPIER
                                                                                        sortedFirstBy:@"occupierName"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:[NSPredicate predicateWithFormat:@"occupierName ==%@",occupierName]
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
    
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching %@: %@",ENTITY_OCCUPIER,[error localizedDescription]);
        return nil;
    }
    
    if ([fetchedResultsController.fetchedObjects count]>1)
    {
        NSLog(@"ERROR. There are more than one OccupierDecorator for the occupierName in %@.",occupierName);
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    if ([fetchedResultsController.fetchedObjects count]==1)
    {
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    
	return nil;
}

- (NSArray *) getOccupersBySceneID:(NSNumber *) occupierscene;
{
    NSFetchedResultsController *fetchedResultsController = [self newFetchedResultsControllerForEntity:ENTITY_OCCUPIER
                                                                                        sortedFirstBy:@"occupierName"
                                                                                          thenByOrNil:nil
                                                                                          thenByOrNil:nil
                                                                                      filteredByOrNil:[NSPredicate predicateWithFormat:@"occupierSceneNumber ==%d",[occupierscene intValue]]
                                                                                   sectionNameKeyPath:nil
                                                                                             delegate:nil ];
	NSError *error;
	if (![fetchedResultsController performFetch:&error])
    { 
		NSLog(@"Error Fetching %@: %@",ENTITY_OCCUPIER,[error localizedDescription]);
        return nil;
    }
    
    if ([fetchedResultsController.fetchedObjects count]>1)
    {
        NSLog(@"ERROR. There are more than one OccupierDecorator for the occupierSceneNumber in %@.",occupierscene);
        return fetchedResultsController.fetchedObjects;
    }
    if ([fetchedResultsController.fetchedObjects count]==1)
    {
        return [fetchedResultsController.fetchedObjects lastObject];
    }
    
	return nil;
}


//*********************** E N D     O C C U P I E R  ***********************************




#pragma mark - Custom Table Data Source Delegates




@end
