//
//  NSDate+STAdditions.m
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSDate+STAdditions.h"


static NSCalendar *gregorianCalendar;
static NSDateFormatter *dayOfWeekOnlyFormatter;
static NSDateFormatter *timeOnlyFormatter;
static NSDateFormatter *veryShortDateFormatter;
static NSDateFormatter *shortDateFormatter;
static NSDateFormatter *longDateFormatter;
static NSDateFormatter *veryLongDateFormatter;


@implementation NSDate (STAdditions)

#pragma mark Convenience Date Creation Methods

+ (NSDate *)dateWithCTimeStruct:(time_t)inTimeStruct;
{
    // Convert the time_t to a UTC tm struct
    struct tm* UTCDateStruct = gmtime(&(inTimeStruct));
    
    // Convert the tm struct to date components
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setSecond:UTCDateStruct->tm_sec];
    [dateComponents setMinute:UTCDateStruct->tm_min];
    [dateComponents setHour:UTCDateStruct->tm_hour];
    [dateComponents setDay:UTCDateStruct->tm_mday];
    [dateComponents setMonth:UTCDateStruct->tm_mon + 1];
    [dateComponents setYear:UTCDateStruct->tm_year + 1900];
    
    // Use the date components to create an NSDate object
    NSDate *newDate = [[[NSCalendar currentCalendar] dateFromComponents:dateComponents] dateByAddingTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT]];    
    [dateComponents release];

    return newDate;
}

#pragma mark Accessors

- (NSInteger)century;
{
    NSInteger currentYear = self.year;
    NSString *yearStr = [@(currentYear) stringValue];
    
    // in this case, the year is < 100, such as 0 to 99, making it the "0" century
    if (yearStr.length < 3) {
        return 0;
    }
    
    // strip the year off the date
    return [[[yearStr substringToIndex:(yearStr.length - 2)] stringByAppendingString:@"00"] integerValue];
}

- (NSInteger)decade;
{
    // First, get the century - year
    NSInteger decade = self.year - self.century;
    
    // this will give us 09 in the case of 2009.  Round down the whole number
    return (decade / 10) * 10;
}

- (NSInteger)year;
{
    return [[[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:self] year];
}

- (NSInteger)month;
{
    return [[[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:self] month];
}

#pragma mark Date String Parsing

+ (NSDateFormatter *)ISO8601DateFormatterConfiguredForTimeZone:(NSTimeZone *)inTimeZone supportingFractionalSeconds:(BOOL)inSupportFractionalSeconds;
{
    NSTimeZone *timeZone = inTimeZone;
    if (!timeZone) {
        timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    }

    // Y-MM-dd'T'HH':'MM':'ss'.'SSS'Z
    // Y-MM-dd'T'HH':'MM':'ss'.'SSS'Z'Z
    NSMutableString *formatString = [[NSMutableString alloc] initWithString:@"Y-MM-dd'T'HH':'mm':'ss"];
    if (inSupportFractionalSeconds) {
        [formatString appendString:@"'.'SSS"];
    }

    [formatString appendString:@"'Z'"];
    
    if (inTimeZone && ![timeZone isEqualToTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]]) {
        [formatString appendString:@"Z"];
    }
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:formatString];
    [formatter setTimeZone:timeZone];
    
    [formatString release];
    
    return formatter;
}

+ (NSDate *)dateFromISO8601String:(NSString *)inDateString;
{
    return [NSDate dateFromISO8601String:inDateString timeZone:nil supportingFractionalSeconds:NO];
}

+ (NSDate *)dateFromISO8601String:(NSString *)inDateString timeZone:(NSTimeZone *)inTimeZone supportingFractionalSeconds:(BOOL)inSupportFractionalSeconds;
{
    NSDate *outDate = nil;
    NSString *error = nil;
    [[NSDate ISO8601DateFormatterConfiguredForTimeZone:inTimeZone supportingFractionalSeconds:inSupportFractionalSeconds] getObjectValue:&outDate forString:inDateString errorDescription:&error];
    
    if (error) {
        NSLog(@"ISO 8601 date parsing error: %@", error);
    }
    
    return outDate;
}

#pragma mark Convenience String Formatting Methods

- (NSString *)timeIntervalSince1970String;
{
    return [NSString stringWithFormat:@"%f", [self timeIntervalSince1970]];
}

- (NSString *)timeString;
{
	if (!timeOnlyFormatter) {
        timeOnlyFormatter = [[NSDateFormatter alloc] init];
        [timeOnlyFormatter setDateStyle:NSDateFormatterNoStyle];
        [timeOnlyFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
	return [timeOnlyFormatter stringFromDate:self];
}

- (NSString *)dayOfWeekString;
{
	if (!dayOfWeekOnlyFormatter) {
        dayOfWeekOnlyFormatter = [[NSDateFormatter alloc] init];
        [dayOfWeekOnlyFormatter setDateFormat:@"EEEE"];
    }
    
    return [dayOfWeekOnlyFormatter stringFromDate:self];
}

- (NSString *)veryShortDateString;
{
    if (!veryShortDateFormatter) {
        veryShortDateFormatter = [[NSDateFormatter alloc] init];
        [veryShortDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [veryShortDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    
    return [veryShortDateFormatter stringFromDate:self];
}

- (NSString *)shortDateString;
{
    if (!shortDateFormatter) {
        shortDateFormatter = [[NSDateFormatter alloc] init];
        [shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [shortDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
    return [shortDateFormatter stringFromDate:self];
}

- (NSString *)longDateString;
{
    if (!longDateFormatter) {
        longDateFormatter = [[NSDateFormatter alloc] init];
        [longDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [longDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
    return [longDateFormatter stringFromDate:self];
}

- (NSString *)veryLongDateString;
{
    if (!veryLongDateFormatter) {
        longDateFormatter = [[NSDateFormatter alloc] init];
        [longDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [longDateFormatter setTimeStyle:NSDateFormatterLongStyle];        
    }
    
    return [veryLongDateFormatter stringFromDate:self];
}

- (NSString *)phoneRelativeDateString;
{
    if (!gregorianCalendar) {
        gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    }

    NSUInteger unitFlags = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *components = [gregorianCalendar components:unitFlags fromDate:self toDate:[NSDate date] options:0];
	NSInteger days = [components day];
	NSInteger hours = [components hour];
	NSInteger minutes = [components minute];
	NSInteger seconds = [components second];

	NSString *timeText;

	if (days >= 1) {
		timeText = [self veryShortDateString];
	}
	else if (hours == 1) {
		timeText = [NSString stringWithFormat:@"%ldh", (long)hours];
	}
	else if (hours >= 1) {
		timeText = [NSString stringWithFormat:@"%ldh", (long)hours];
	}
	else if (minutes == 1) {
		timeText = [NSString stringWithFormat:@"%ldm", (long)minutes];
	}
	else if (minutes > 1) {
		timeText = [NSString stringWithFormat:@"%ldm", (long)minutes];
	}
	else {
		if (seconds < 0) {
			timeText = @"< 1m";
		}
		else {
			timeText = [NSString stringWithFormat:@"%lds", (long)seconds];
		}
	}

	return timeText;
}

- (NSString *)relativeDateString;
{
    if (!gregorianCalendar) {
        gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    }
	
    NSUInteger unitFlags = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *components = [gregorianCalendar components:unitFlags fromDate:self toDate:[NSDate date] options:0];
	NSInteger days = [components day];
	NSInteger hours = [components hour];
	NSInteger minutes = [components minute];
	NSInteger seconds = [components second];
	
	NSString *timeText;
	
	if (days >= 1) {
		timeText = [self veryShortDateString];
	}
	else if (hours == 1) {
		timeText = [NSString stringWithFormat:@"%ld hour", (long)hours];
	}
	else if (hours >= 1) {
		timeText = [NSString stringWithFormat:@"%ld hours", (long)hours];	
	}
	else if (minutes == 1) {
		timeText = [NSString stringWithFormat:@"%ld minute", (long)minutes];
	}
	else if (minutes > 1) {
		timeText = [NSString stringWithFormat:@"%ld minutes", (long)minutes];			
	}
	else {
		if (seconds < 0) {
			timeText = @"< 1 minute";
		}
		else {
			timeText = [NSString stringWithFormat:@"%ld seconds", (long)seconds];
		}
	}
	
	return timeText;    
}

- (NSString *)HTTPTimeZoneHeaderString;
{
    return [self HTTPTimeZoneHeaderStringForTimeZone:nil];
}

- (NSString *)HTTPTimeZoneHeaderStringForTimeZone:(NSTimeZone *)inTimeZone;
{
    NSTimeZone *timeZone = inTimeZone ? inTimeZone : [NSTimeZone localTimeZone];
    NSString *dateString = [self ISO8601StringForTimeZone:timeZone];
    NSString *timeZoneHeader = [NSString stringWithFormat:@"%@;;%@", dateString, [timeZone name]];
    return timeZoneHeader;
}

- (NSString *)ISO8601String;
{
    return [self ISO8601StringForTimeZone:nil];
}

- (NSString *)ISO8601StringForLocalTimeZone;
{
    return [self ISO8601StringForTimeZone:[NSTimeZone localTimeZone]];
}

- (NSString *)ISO8601StringForTimeZone:(NSTimeZone *)inTimeZone;
{
    return [self ISO8601StringForTimeZone:inTimeZone usingFractionalSeconds:NO];
}

- (NSString *)ISO8601StringForTimeZone:(NSTimeZone *)inTimeZone usingFractionalSeconds:(BOOL)inUseFractionalSeconds;
{
    return [[NSDate ISO8601DateFormatterConfiguredForTimeZone:inTimeZone supportingFractionalSeconds:inUseFractionalSeconds] stringFromDate:self];
    
    /*
     struct tm *timeinfo;
     char buffer[80];
     
     time_t rawtime = [self timeIntervalSince1970] - [timeZone secondsFromGMT];
     timeinfo = localtime(&rawtime);
     
     NSString *formatString = nil;
     if (inTimeZone) {
     
     }
     
     strftime(buffer, 80, "%Y-%m-%dT%H:%M:%S%z", timeinfo);
     
     returnString = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
     */ 
}

@end
