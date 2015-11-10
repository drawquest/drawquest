//
//  DQModelObject+DataStore.m
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQModelObject+DataStore.h"
#import "NSDictionary+DQAPIConveniences.h"

@interface DQModelObject ()

@property (nonatomic, readwrite, copy) NSDate *timestamp;
@property (nonatomic, readwrite, copy) NSString *serverID;
@property (nonatomic, readwrite, copy) NSDictionary *content;

@end

@implementation DQModelObject (DataStore)

+ (NSString *)yapCollectionName
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"yapCollectionName not defined" userInfo:@{@"object": self}];
}

- (NSString *)yapCollectionKey
{
    return [self equalityIdentifier];
}

- (instancetype)initWithServerID:(NSString *)serverID;
{
    self = [super init];
    if (self)
    {
        self.serverID = serverID;
    }
    return self;
}

- (NSString *)serverIDFromJSONDictionary:(NSDictionary *)inDictionary
{
    return inDictionary.dq_serverID;
}

- (BOOL)initializeWithJSONDictionary:(NSDictionary *)inDictionary
{
    BOOL changed = NO;
    DQModelObjectSetProperty(serverID, [self serverIDFromJSONDictionary:inDictionary], changed);
    DQModelObjectSetProperty(timestamp, inDictionary.dq_timestamp, changed);
    DQModelObjectSetProperty(content, inDictionary.dq_content, changed);
    return changed;
}

+ (instancetype)objectForKey:(NSString *)key inTransaction:(YapCollectionsDatabaseReadTransaction *)transaction
{
    DQModelObject *result = nil;
    if ([key length])
    {
        // NSLog(@" <  YAP %@ %@", [[self class] yapCollectionName], key);
        result = [transaction objectForKey:key inCollection:[[self class] yapCollectionName]];
    }
    return result;
}

- (void)saveInTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    // NSLog(@"  > YAP %@ %@", [[self class] yapCollectionName], [self yapCollectionKey]);
    [transaction setObject:self forKey:[self yapCollectionKey] inCollection:[[self class] yapCollectionName]];
}

- (void)deleteInTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction
{
    // NSLog(@"X   YAP %@ %@", [[self class] yapCollectionName], [self yapCollectionKey]);
    [transaction removeObjectForKey:[self yapCollectionKey] inCollection:[[self class] yapCollectionName]];
}

@end
