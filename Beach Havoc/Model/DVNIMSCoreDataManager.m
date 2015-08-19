//
//  DVNFDCCoreDataManager.m
//  IncidentManagementSystem
//
//  Created by Lewis Johnson on 10/2/14.
//  Copyright (c) 2014 Devon Energy. All rights reserved.
//

#import "DVNIMSCoreDataManager.h"
#import "DVNIMSConstants.h"
#import "NSDate+DVNStuff.h"

@interface DVNIMSCoreDataManager()

@property (nonatomic, strong) NSManagedObjectContext *mainThreadContext;

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


@implementation DVNIMSCoreDataManager

#pragma mark - Convenience Constructor & Init

+ (DVNIMSCoreDataManager *)sharedManager
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
    return [DVNIMSCoreDataManager sharedManager].mainThreadContext;
}

+ (NSManagedObjectContext *)backgroundContext
{
    return [DVNIMSCoreDataManager sharedManager].backgroundContext;
}

+ (NSManagedObjectContext *)backgroundContextNoUndo
{
    //return [DVNFDCCoreDataManager sharedManager].backgroundContext;
    return [DVNIMSCoreDataManager sharedManager].backgroundContextNoUndo;
}

+ (NSPersistentStoreCoordinator *)dbPersistentStoreCoordinator
{
    return [[DVNIMSCoreDataManager sharedManager] persistentStoreCoordinator];
}

+ (void)saveContext:(NSManagedObjectContext *)context
{
    [[DVNIMSCoreDataManager sharedManager] saveContext:context];
}

+ (void)deleteDatabase
{
    [[DVNIMSCoreDataManager sharedManager] deleteDatabase];
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
#warning "Remove the abort() prior release"
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            //abort();
        }
    }
}

- (void)deleteDatabase
{
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DVNIMSDataBase.db"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path])
    {
        NSError *deleteError;
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&deleteError];
    }
    
    //Reset so that these are created when referring to new SQL DB file.
    
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
    if (![_mainThreadContext save:&error]) {
    	NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }
    
}


#pragma mark Core Data stack

// The main thread context is the primary context used for reading values and making user changes.
// Network updates to data are performed in the background and changes are merged manually.
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


// Background contexts are constructed as needed for long running operations, and are not expected to
// be long lived objects.  Changes made in the main-thread context will not be pushed to existing
// background contexts.
- (NSManagedObjectContext *)backgroundContext
{
    NSManagedObjectContext *backgroundContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [backgroundContext setPersistentStoreCoordinator:coordinator];
    }
    
    return backgroundContext;
}

- (NSManagedObjectContext *)backgroundContextNoUndo {
    NSManagedObjectContext *backgroundContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [backgroundContext setUndoManager:nil];
        [backgroundContext setPersistentStoreCoordinator:coordinator];
    }
    
    return backgroundContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DVNIMSModel" withExtension:@"momd"]; //use mom not momd when you create it yourself
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DVNIMSDataBase.db"];
    
    NSLog(@"%@",storeURL);
    
#warning - Comment or uncomment this line to delete the database - CDN 6/1/2014
    
    //    if([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path])
    //    {
    //        NSError *deleteError;
    //        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&deleteError];
    //    }
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil error:&error])
    {   //also the following code will automatically delete the store file if it cannot create the persistant store coordinator
        //the re run should recreate a new one with the modified schema
        NSLog(@"Error adding persistent store: %@", error);
        
        // JL: Schema may have changed, just delete and try again.
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:storeURL
                                                             options:nil error:&error])
        {
            
            //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
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


- (int ) countPendingIncidents
{
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"submittedStatus ==[c]%@",kIMSPendingIncidentStatus];
    return [self countEntitiesForName:@"IncidentEntries" forPredicateOrNil:(NSPredicate *)filterPredicate];
}

#pragma mark - Pending / History

- (NSFetchedResultsController *) pendingIncidents
{
    NSString *sortKeyOne = @"createdDateTime";
    NSString *sortKeyTwo;
    NSString *sortKeyThree;
    NSString *sectionNameKeyPath;
    NSString *incidentStatus = @"Pending"; //add proper string
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"IncidentEntries" inManagedObjectContext:self.mainThreadContext];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"submittedStatus ==[c]%@",incidentStatus];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
	
	NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:3];
    
    if (sortKeyOne!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyOne ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    if (sortKeyTwo!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyTwo ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    if (sortKeyThree!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyThree ascending:YES];
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
    NSError *error;
	if (![aFetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching pendingIncidents");
    }
    
    if ([aFetchedResultsController.fetchedObjects count]>0)
    {
        NSLog(@"Got pendingIncidents Fetched Result Controller");
        return aFetchedResultsController;
    }
    
	return nil;
}

- (int ) countHistoryIncidents
{
    NSString *incidentStatus = @"Posted"; //add proper string
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"submittedStatus ==[c]%@",incidentStatus];
    return [self countEntitiesForName:@"IncidentEntries" forPredicateOrNil:(NSPredicate *)filterPredicate];
}


- (NSFetchedResultsController *) historyIncidents
{
    NSString *sortKeyOne = @"createdDateTime";
    NSString *sortKeyTwo;
    NSString *sortKeyThree;
    NSString *sectionNameKeyPath;
    NSString *incidentStatus = kIMSSubmittedIncidentStatus; //add proper string
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"IncidentEntries" inManagedObjectContext:self.mainThreadContext];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"submittedStatus ==[c]%@",incidentStatus];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
	
	NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:3];
    
    if (sortKeyOne!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyOne ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    if (sortKeyTwo!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyTwo ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    if (sortKeyThree!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyThree ascending:YES];
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
    NSError *error;
	if (![aFetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching pendingIncidents");
    }
    
    if ([aFetchedResultsController.fetchedObjects count]>0)
    {
        NSLog(@"Got pendingIncidents Fetched Result Controller");
        return aFetchedResultsController;
    }
    
	return nil;
}

- (void) deleteThumbnail: (Thumbnails*) thumbnailToDelete;
{
    [self.mainThreadContext deleteObject:thumbnailToDelete];
}

- (NSFetchedResultsController *)thumbNailsForIncidentAttachments:(NSString *)incidentGUID attachmentType:(NSString *)attachmentType;
{
    NSString *sortKeyOne = @"dateAdded";
    NSString *sortKeyTwo;
    NSString *sortKeyThree;
    NSString *sectionNameKeyPath;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [self.mainThreadContext setStalenessInterval:0];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Thumbnails" inManagedObjectContext:self.mainThreadContext];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"incidentUniqueID ==[c]%@ && thumbnailType ==[c]%@",incidentGUID,attachmentType];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
	
	NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:3];
    
    if (sortKeyOne!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyOne ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    if (sortKeyTwo!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyTwo ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    if (sortKeyThree!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyThree ascending:YES];
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
    NSError *error;
	if (![aFetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching thumbnails");
    }
    
    if ([aFetchedResultsController.fetchedObjects count]>0)
    {
        NSLog(@"Got thumbnails Fetched Result Controller");
        return aFetchedResultsController;
    }
    
	return nil;

}


# pragma mark - Incident Entity

- (IncidentEntries *) newIncidentEntry
{
    IncidentEntries * newObj = [NSEntityDescription insertNewObjectForEntityForName:@"IncidentEntries" inManagedObjectContext:self.mainThreadContext];
    return newObj;
}

- (void)addIncidentEntry:(IncidentEntries *)newIncidentEntry
{
    if (newIncidentEntry==nil)
    {
        return;
    }
    
    NSLog(@"Writing an IncidentEntry");
    
    [self saveContext:self.mainThreadContext];
    
}

- (IncidentEntries *)readIncidentEntryForGUID:(NSString *)incidentGUID;
{
    
    if (incidentGUID == nil)
    {
        NSLog(@"Writing Update IncidentEntry was passed a null ID to update");
        return nil;
    }
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"mobileIncidentID ==[c]%@",incidentGUID];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"IncidentEntries" inManagedObjectContext:self.mainThreadContext];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    [fetchRequest setSortDescriptors:nil];
    
    if (filterPredicate != nil)
    {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    NSError * error;
    
    NSArray * result = [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
    
    if (!result)
    {
        [NSException raise:@"updateIncidentEntryForGUID Failed" format:@"Reason: %@", [error localizedDescription]];
        return nil;
    }
    IncidentEntries * objincidententry;
    
    if ([result count] == 1)
    {
        objincidententry = result[0];
    }
    else
    {
        NSLog(@"Error reading and updating specific IncidentEntrie");
        return nil;
    }
    
    return objincidententry;
    
    
}

- (bool)saveAttachmentInBackground:(NSString *)incidentGUID withData:(NSData *) objImage attachmentType:(NSString *)attachmentType thumbnail:(NSData *) objthumbnail attachmentURL:(NSString *)attachmentURL;
{
    // here we are establishing a persistent store coordinator relationship between the incident and the attachment.
    // so we have to make sure that we are using the same background moc or core data will complain
    // the thumbnail data is a much smaller image for quick retrieval later.
    
    if (incidentGUID == nil)
    {
        NSLog(@"Writing Update IncidentEntry was passed a null ID to update");
        return false;
    }

    NSManagedObjectContext * thisbackgroundContext = self.backgroundContext;
    
    [thisbackgroundContext performBlock:^{
        
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"mobileIncidentID ==[c]%@",incidentGUID];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"IncidentEntries" inManagedObjectContext:thisbackgroundContext];
        
        [fetchRequest setEntity:entity];
        
        [fetchRequest setFetchBatchSize:20];
        
        [fetchRequest setSortDescriptors:nil];
        
        if (filterPredicate != nil)
        {
            [fetchRequest setPredicate:filterPredicate];
        }
        
        NSError * error;
        
        NSArray * result = [thisbackgroundContext executeFetchRequest:fetchRequest error:&error];
        
        if (!result)
        {
            [NSException raise:@"updateIncidentEntryForGUID Failed" format:@"Reason: %@", [error localizedDescription]];
        }
        IncidentEntries * objincidententry;
        
        if ([result count] == 1)
        {
            objincidententry = result[0];
        }
        else
        {
            NSLog(@"Error reading and updating specific IncidentEntrie");
        }
        
        Attachments * objAttachment = [NSEntityDescription insertNewObjectForEntityForName:@"Attachments" inManagedObjectContext:thisbackgroundContext];

        objAttachment.mobileIncidentID = objincidententry.mobileIncidentID;
        objAttachment.attachmentID = [DVNUtilities getGUID];
        objAttachment.blob = objImage;
        objAttachment.attachmentType = attachmentType;
        objAttachment.incidents = objincidententry;
        objAttachment.attachmentURL = attachmentURL;
        objAttachment.blobsize = [NSNumber numberWithLong:objImage.length];
        
        Thumbnails * objThumbnail = [NSEntityDescription insertNewObjectForEntityForName:@"Thumbnails" inManagedObjectContext:thisbackgroundContext];
        
        objThumbnail.thumbnail = objthumbnail;
        objThumbnail.thumbnailType = attachmentType;
        objThumbnail.dateAdded = [NSDate date];
        objThumbnail.attachmentID = objAttachment.attachmentID;
        objThumbnail.incidentUniqueID = incidentGUID;
        objThumbnail.attachment = objAttachment;
        objThumbnail.incident = objincidententry;
        
        [self saveContext:thisbackgroundContext];
        
    }];
    
    return true;
    
}

- (bool)saveAttachment:(NSString *)incidentGUID withData:(NSData *) objImage attachmentType:(NSString *)attachmentType thumbnail:(NSData *) objthumbnail attachmentURL:(NSString *)attachmentURL;
{
    // here we are establishing a persistent store coordinator relationship between the incident and the attachment.
    // so we have to make sure that we are using the same moc or core data will complain
    // the thumbnail data is a much smaller image for quick retrieval later.
    
    if (incidentGUID == nil)
    {
        NSLog(@"Writing Update IncidentEntry was passed a null ID to update");
        return false;
    }
    
    NSManagedObjectContext * thisforegroundContext = self.mainThreadContext;
    
    
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"mobileIncidentID ==[c]%@",incidentGUID];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"IncidentEntries" inManagedObjectContext:thisforegroundContext];
        
        [fetchRequest setEntity:entity];
        
        [fetchRequest setFetchBatchSize:20];
        
        [fetchRequest setSortDescriptors:nil];
        
        if (filterPredicate != nil)
        {
            [fetchRequest setPredicate:filterPredicate];
        }
        
        NSError * error;
        
        NSArray * result = [thisforegroundContext executeFetchRequest:fetchRequest error:&error];
        
        if (!result)
        {
            [NSException raise:@"updateIncidentEntryForGUID Failed" format:@"Reason: %@", [error localizedDescription]];
        }
        IncidentEntries * objincidententry;
        
        if ([result count] == 1)
        {
            objincidententry = result[0];
        }
        else
        {
            NSLog(@"Error reading and updating specific IncidentEntrie");
        }
        
        Attachments * objAttachment = [NSEntityDescription insertNewObjectForEntityForName:@"Attachments" inManagedObjectContext:thisforegroundContext];
        
        objAttachment.mobileIncidentID = objincidententry.mobileIncidentID;
        objAttachment.attachmentID = [DVNUtilities getGUID];
        objAttachment.blob = objImage;
        objAttachment.attachmentType = attachmentType;
        objAttachment.incidents = objincidententry;
        objAttachment.attachmentURL = attachmentURL;
        objAttachment.blobsize = [NSNumber numberWithLong:objImage.length];
        
        Thumbnails * objThumbnail = [NSEntityDescription insertNewObjectForEntityForName:@"Thumbnails" inManagedObjectContext:thisforegroundContext];
        
        objThumbnail.thumbnail = objthumbnail;
        objThumbnail.thumbnailType = attachmentType;
        objThumbnail.dateAdded = [NSDate date];
        objThumbnail.attachmentID = objAttachment.attachmentID;
        objThumbnail.incidentUniqueID = incidentGUID;
        objThumbnail.attachment = objAttachment;
        objThumbnail.incident = objincidententry;
        
        [self saveContext:thisforegroundContext];
    
    return true;
    
}

- (int )countAttachmentsforIncident:(NSString *)incidentGUID
{
    //since every attachmnent has a thumbnail we will count these, they should be faster
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"incidentUniqueID ==[c]%@",incidentGUID];
    return [self countEntitiesForName:@"Thumbnails" forPredicateOrNil:(NSPredicate *)filterPredicate];
}


-(void)saveReadIncidentEntry
{
    [self saveContext:self.mainThreadContext];
}

- (void)save;
{
    [self saveContext:self.mainThreadContext];
}

- (void)deleteIncidentEntry:(IncidentEntries *)incidentToDelete
{
    [self.mainThreadContext deleteObject:incidentToDelete];
    [self saveContext:self.mainThreadContext];
}

- (NSArray*) readIncidentEntries
{
    
    NSString *sortKeyOne = @"displayOrder";
    
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:2];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *filterPredicate = nil;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"IncidentEntries" inManagedObjectContext:self.mainThreadContext];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    if (sortKeyOne!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyOne ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    
    [fetchRequest setSortDescriptors:nil];
    
    if (filterPredicate != nil)
    {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    NSError * error;
    
    NSArray * result = [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
    
    if (!result)
    {
        [NSException raise:@"readIncidentEntries Failed" format:@"Reason: %@", [error localizedDescription]];
        return nil;
    }
    
    if ([result count] >> 0)
    {
        return result;
    }
    else
    {
        NSLog(@"Error reading Form Fields");
        return nil;
    }
    
    return nil;
}

- (NSArray*)  readIncidentEntriesWithStatus:(NSString*)incidentStatus {
    
    NSString *sortKeyOne = @"createdDateTime";
    NSString *sortKeyTwo;
    NSString *sortKeyThree;
    NSString *sectionNameKeyPath;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"IncidentEntries" inManagedObjectContext:self.mainThreadContext];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"status ==[c]%@",incidentStatus];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
	
	NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:3];
    
    if (sortKeyOne!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyOne ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    if (sortKeyTwo!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyTwo ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    if (sortKeyThree!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyThree ascending:YES];
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
    NSError *error;
	if (![aFetchedResultsController performFetch:&error])
    {
		NSLog(@"Error Fetching pendingIncidents");
    }
    
    if ([aFetchedResultsController.fetchedObjects count]>0)
    {
        NSLog(@"Got pendingIncidents Fetched Result Controller");
        return aFetchedResultsController.fetchedObjects;
    }
    
	return nil;}


# pragma mark - Attachment  Entity

- (Attachments *) newAttachment
{
    Attachments * newObj = [NSEntityDescription insertNewObjectForEntityForName:@"Attachments" inManagedObjectContext:self.backgroundContext];
    return newObj;
}

- (void)addAttachment:(Attachments *)thenewAttachment
{
    if (thenewAttachment==nil)
    {
        NSLog(@"ERROR Writing an Attachment");
        return;
    }
    
    NSLog(@"Writing an Attachment");
    
    [self saveContext:self.backgroundContext];
}

- (void)deleteAttachment:(Attachments *)attachmentToDelete
{
    [self.backgroundContext deleteObject:attachmentToDelete];
}

- (Attachments *)readAttachmentForAttachmentID:(NSString *)attachmentID;
{
// if you allready have an incident or a thumbnail resident, you can just get the attachment through the relationship
// this method may be usefull for transmitting attachments etc.
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"attachmentID ==[c]%@",attachmentID];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Attachments" inManagedObjectContext:self.mainThreadContext];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    [fetchRequest setSortDescriptors:nil];
    
    if (filterPredicate != nil)
    {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    NSError * error;
    
    NSArray * result = [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
    
    if (!result)
    {
        [NSException raise:@"readIncidentEntries Failed" format:@"Reason: %@", [error localizedDescription]];
        return nil;
    }
    
    if ([result count] == 1)
    {
        Attachments * oneAttachment = result[0];
        return oneAttachment;
    }
    else
    {
        NSLog(@"Error reading specific attachment from thumbnail");
        return nil;
    }

}


# pragma mark - Form Field Entity

- (FormFields *)newFormField
{
    FormFields * newObj = [NSEntityDescription insertNewObjectForEntityForName:@"FormFields" inManagedObjectContext:self.mainThreadContext];
    
    return newObj;
}

- (void)addFormField:(FormFields *)newFormField;
{
    if (newFormField==nil)
    {
        NSLog(@"ERROR Writing a FormField");
        return;
    }
    
    NSLog(@"Writing a FormFields");
    
    [self saveContext:self.mainThreadContext];
    
}

- (NSArray*) readFormFields;
{
    
    NSString *sortKeyOne = @"displayOrder";
    
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:2];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *filterPredicate = nil;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"FormFields" inManagedObjectContext:self.mainThreadContext];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    if (sortKeyOne!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyOne ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    
    [fetchRequest setSortDescriptors:nil];
    
    if (filterPredicate != nil)
    {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    NSError * error;
    
    NSArray * result = [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
    
    if (!result)
    {
        [NSException raise:@"readFormFields Failed" format:@"Reason: %@", [error localizedDescription]];
        return nil;
    }
    
    if ([result count] >> 0)
    {
        return result;
    }
    else
    {
        NSLog(@"Error reading Form Fields");
        return nil;
    }
    
    return nil;
}

-(void)saveFormField
{
    [self saveContext:self.mainThreadContext];
}


- (void) deleteFormField: (FormFields*) fieldToDelete{
    
    [self.mainThreadContext deleteObject:fieldToDelete];
}

- (FormFields *) getFormFieldWithUniqueId: (NSString*) uniqueID {
    
    
    if (uniqueID == nil)
    {
        NSLog(@"Writing Update IncidentEntry was passed a null ID to update");
        return false;
    }
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"uniqueID ==[c]%@",uniqueID];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"FormFields" inManagedObjectContext:self.mainThreadContext];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    [fetchRequest setSortDescriptors:nil];
    
    if (filterPredicate != nil)
    {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    NSError * error;
    
    NSArray * result = [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
    
    if (!result)
    {
        [NSException raise:[NSString stringWithFormat:@"Fetch for Form Field with UniqueID = %@ FAILED", uniqueID] format:@"Reason: %@", [error localizedDescription]];
        return false;
    }
    
    FormFields * objFormField;
    
    if ([result count] == 1)
    {
        objFormField = result[0]; //Since
    }
    else
    {
        NSLog(@"Error reading and updating specific Form Field, Multiple Values returned....");
        return false;
    }
    
    return objFormField;
}

- (NSArray *) getVisibleFormFields {
    
    NSString *sortKeyOne = @"displayOrder";
    
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:2];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"isVisible == 1"];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"FormFields" inManagedObjectContext:self.mainThreadContext];
    
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    if (sortKeyOne!=nil)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKeyOne ascending:YES];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithArray:sortDescriptors]];
    
    if (filterPredicate != nil)
    {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    NSError * error;
    
    NSArray * result = [self.mainThreadContext executeFetchRequest:fetchRequest error:&error];
    
    if (!result)
    {
        [NSException raise:@"Fetch for Form Fields failed" format:@"Reason: %@", [error localizedDescription]];
        return false;
    }
    
    NSMutableArray *finalArray = [[NSMutableArray alloc]init];
    
    for (FormFields *field in result) {
        [finalArray addObject:field];
    }
    
    return finalArray;
}

#pragma mark - JSON readers

- (void) loadFormFieldJSONData {
    
    //Firstly delete any of the formFields present
    
    for (FormFields *field in [self readFormFields]) {
        [self deleteFormField:field];
    }
    
    NSData *formFieldData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"formField" ofType:@"json"]];
    
    NSDictionary *formFieldDataDict = [NSJSONSerialization JSONObjectWithData:formFieldData options:0 error:nil];
    
    NSArray *formFieldDictArray = [formFieldDataDict objectForKey:@"FormField"];
    
    for (NSDictionary *fieldDict in formFieldDictArray) {
        
        // NSString to NSNumber
        NSNumber *dispOrder = [NSNumber numberWithInt:((NSString *)[fieldDict objectForKey:@"displayOrder"]).intValue];
        NSNumber *isReq = [NSNumber numberWithBool:[[fieldDict objectForKey:@"isRequired"] boolValue]];
        NSNumber *isVis = [NSNumber numberWithBool:[[fieldDict objectForKey:@"isVisible"] boolValue]];
        NSNumber *dataLen =[NSNumber numberWithInt:((NSString *)[fieldDict objectForKey:@"dataLength"]).intValue];
        NSNumber *control = [NSNumber numberWithInt:((NSString *)[fieldDict objectForKey:@"controlType"]).intValue];
        
        // Create and config the form field Object
        FormFields *objFormField = [[DVNIMSCoreDataManager sharedManager] newFormField];
        objFormField.uniqueID = [fieldDict objectForKey:@"uniqueId"];
        objFormField.displayName = [fieldDict objectForKey:@"displayName"];
        objFormField.displayOrder = dispOrder;
        objFormField.dataType =[fieldDict objectForKey:@"dataType"];
        objFormField.dataLength =dataLen;
        objFormField.controlType = control;
        objFormField.isRequired =isReq;
        objFormField.isVisible =isVis;
        
        //Save the form objects
        [self addFormField:objFormField];
    }
    
}

- (IncidentEntries *) createAnIncidentWithUniqueMobileID
{
    // Clear any "draft" incidents, if there exists any
    NSArray *arrayOfIncidents = [self readIncidentEntriesWithStatus:kIMSDraftIncidentStatus];
    
    for (int i = 0; i < [arrayOfIncidents count]; i++) {
        
        IncidentEntries *entry = arrayOfIncidents [i];
        
        [self deleteIncidentEntry:entry];
    }
    
    // Load form fields freshly
    [self loadFormFieldJSONData];
    
    // Create a new incident and assign a unique
    IncidentEntries *newincident = [[DVNIMSCoreDataManager sharedManager] newIncidentEntry];
    
    newincident.mobileIncidentID = [[NSUUID UUID] UUIDString];
    newincident.createdDateTime = [NSDate stringFromDate:[NSDate date]];
    
    [self addIncidentEntry:newincident];
    
    return newincident;
}

@end
