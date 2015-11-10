//
//  NSDate+STAdditions.h
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "time.h"


@interface NSDate (STAdditions)

@property (nonatomic, readonly) NSInteger century;
@property (nonatomic, readonly) NSInteger decade;
@property (nonatomic, readonly) NSInteger year;
@property (nonatomic, readonly) NSInteger month;

// Convenience Date Creation Methods
+ (NSDate *)dateWithCTimeStruct:(time_t)inTimeStruct;

// Convenience Date Formatter Methods
+ (NSDateFormatter *)ISO8601DateFormatterConfiguredForTimeZone:(NSTimeZone *)inTimeZone supportingFractionalSeconds:(BOOL)inSupportFractionalSeconds;

// Fixed String Parsing
+ (NSDate *)dateFromISO8601String:(NSString *)inDateString;
+ (NSDate *)dateFromISO8601String:(NSString *)inDateString timeZone:(NSTimeZone *)inTimeZone supportingFractionalSeconds:(BOOL)inSupportFractionalSeconds;

// Convenience String Formatting Methods
- (NSString *)timeIntervalSince1970String;
- (NSString *)timeString;
- (NSString *)dayOfWeekString;
- (NSString *)veryShortDateString;
- (NSString *)shortDateString;
- (NSString *)longDateString;
- (NSString *)veryLongDateString;
- (NSString *)relativeDateString;
- (NSString *)phoneRelativeDateString;

// HTTP Dates
- (NSString *)HTTPTimeZoneHeaderString;
- (NSString *)HTTPTimeZoneHeaderStringForTimeZone:(NSTimeZone *)inTimeZone;
- (NSString *)ISO8601String;
- (NSString *)ISO8601StringForLocalTimeZone;
- (NSString *)ISO8601StringForTimeZone:(NSTimeZone *)inTimeZone;
- (NSString *)ISO8601StringForTimeZone:(NSTimeZone *)inTimeZone usingFractionalSeconds:(BOOL)inUseFractionalSeconds;

@end
