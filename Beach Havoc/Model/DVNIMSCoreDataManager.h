//
//  DVNIMSCoreDataManager.h
//  IncidentManagementSystem
//
//  Created by Lewis Johnson on 10/2/14.
//  Copyright (c) 2014 Devon Energy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Attachments.h"
#import "FormFields.h"
#import "IncidentEntries.h"
#import "IncidentTypes.h"
#import "Thumbnails.h"

@interface DVNIMSCoreDataManager : NSObject

+ (DVNIMSCoreDataManager *)sharedManager;

- (NSManagedObjectContext *)mainThreadContext;

+ (NSManagedObjectContext *)backgroundContext;

+ (NSManagedObjectContext *)backgroundContextNoUndo;

+ (NSPersistentStoreCoordinator *)dbPersistentStoreCoordinator;

+ (void)saveContext:(NSManagedObjectContext *)context;

+ (void)deleteDatabase;

/* Incident Entries Methods */

- (IncidentEntries *)newIncidentEntry;

- (void)addIncidentEntry:(IncidentEntries *)newIncidentEntry;

- (void)deleteIncidentEntry:(IncidentEntries *)incidentToDelete;

- (IncidentEntries *)readIncidentEntryForGUID:(NSString *)incidentGUID;

- (void)saveReadIncidentEntry;

- (void)save;

- (IncidentEntries *) createAnIncidentWithUniqueMobileID;

- (NSArray*) readIncidentEntries;

- (NSArray*) readIncidentEntriesWithStatus:(NSString*)incidentStatus;

/* Attachments Methods */

- (Attachments *)newAttachment;

- (void)addAttachment:(Attachments *)newAttachment;

- (void)deleteAttachment:(Attachments *)attachmentToDelete;

- (bool)saveAttachmentInBackground:(NSString *)incidentGUID withData:(NSData *) objImage attachmentType:(NSString *)attachmentType thumbnail:(NSData *) objthumbnail attachmentURL:(NSString *)attachmentURL;

- (bool)saveAttachment:(NSString *)incidentGUID withData:(NSData *) objImage attachmentType:(NSString *)attachmentType thumbnail:(NSData *) objthumbnail attachmentURL:(NSString *)attachmentURL;

- (Attachments *)readAttachmentForAttachmentID:(NSString *)attachmentID;

/* Form Field Methods */

- (FormFields *)newFormField;

- (void)addFormField:(FormFields *)newFormField;

- (NSArray*)readFormFields;

- (void) deleteFormField: (FormFields*) fieldToDelete;

- (FormFields *) getFormFieldWithUniqueId: (NSString*) uniqueID;

- (NSArray *) getVisibleFormFields;

/* Thumbnails */

- (void) deleteThumbnail: (Thumbnails*) thumbnailToDelete;

- (NSFetchedResultsController *)thumbNailsForIncidentAttachments:(NSString *)incidentGUID attachmentType:(NSString *)attachmentType;

/* Incident Fetchers */

- (NSFetchedResultsController *)pendingIncidents;

- (NSFetchedResultsController *)historyIncidents;

- (int )countPendingIncidents;

- (int )countHistoryIncidents;

- (int )countAttachmentsforIncident:(NSString *)incidentGUID;


@end
