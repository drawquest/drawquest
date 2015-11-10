//
//  DQPapertrailLogger.h
//  DrawQuest
//
//  Created by Jim Roepcke on 11/25/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DQPapertrailLogger : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSDictionary *configuration;

+ (DQPapertrailLogger *)logger;

+ (void)component:(NSString *)component category:(NSString *)category dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock;
- (void)component:(NSString *)component category:(NSString *)category dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock;

+ (void)component:(NSString *)component category:(NSString *)category error:(NSError *)error dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock;
- (void)component:(NSString *)component category:(NSString *)category error:(NSError *)error dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock;

+ (void)component:(NSString *)component category:(NSString *)category error:(NSError *)error httpURLResponse:(NSHTTPURLResponse *)httpURLResponse dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock;
- (void)component:(NSString *)component category:(NSString *)category error:(NSError *)error httpURLResponse:(NSHTTPURLResponse *)httpURLResponse dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock;

@end
