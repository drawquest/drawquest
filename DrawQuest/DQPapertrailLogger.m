//
//  DQPapertrailLogger.m
//  DrawQuest
//
//  Created by Jim Roepcke on 11/25/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPapertrailLogger.h"
#import "GCDAsyncUdpSocket.h"
#import "NSDictionary+STAdditions.h"
//#import <Crashlytics/Crashlytics.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

@interface DQPapertrailLogger () <GCDAsyncUdpSocketDelegate>
@end

@implementation DQPapertrailLogger
{
    NSDateFormatter *_dateFormatter;
    GCDAsyncUdpSocket *_udpSocket;
    NSDictionary *_template;
    BOOL _defaultOn;
}

+ (DQPapertrailLogger *)logger
{
	static DQPapertrailLogger *__sharedInstance = nil;
	if (__sharedInstance == nil)
	{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[DQPapertrailLogger alloc] initPrivateDQPapertrailLogger];
        });
	}
	return __sharedInstance;
}

- (id)initPrivateDQPapertrailLogger
{
    self = [super init];
    if (self)
    {
        NSString *svs = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        ver = [ver isEqualToString:svs] ? ver : [NSString stringWithFormat:@"%@.%@", svs, ver];

        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"MMM dd hh:mm:ss"];
        [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en"]];

        struct utsname systemInfo;
        int unameResult = uname(&systemInfo);
        NSString *model = unameResult == 0 ? [NSString stringWithUTF8String:systemInfo.machine] : [[UIDevice currentDevice] model];

        _template = @{@"app": [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"],
                      @"ver": ver,
                      @"sys": [NSString stringWithFormat:@"%@ %@", model, [[UIDevice currentDevice] systemVersion]],
                      @"ifv": [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: [NSNull null]};
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)setConfiguration:(NSDictionary *)configuration
{
    _configuration = [configuration copy];
    _defaultOn = [_configuration boolForKey:@"on"];
}

+ (void)component:(NSString *)component category:(NSString *)category dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock
{
    [[[self class] logger] component:component category:category error:nil httpURLResponse:nil dataBlock:dataBlock];
}

- (void)component:(NSString *)component category:(NSString *)category dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock
{
    [self component:component category:category error:nil httpURLResponse:nil dataBlock:dataBlock];
}

+ (void)component:(NSString *)component category:(NSString *)category error:(NSError *)error dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock
{
    [[[self class] logger] component:component category:category error:error httpURLResponse:nil dataBlock:dataBlock];
}

- (void)component:(NSString *)component category:(NSString *)category error:(NSError *)error dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock
{
    [self component:component category:category error:error httpURLResponse:nil dataBlock:dataBlock];
}

+ (void)component:(NSString *)component category:(NSString *)category error:(NSError *)error httpURLResponse:(NSHTTPURLResponse *)httpURLResponse dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock
{
    [[[self class] logger] component:component category:category error:error httpURLResponse:httpURLResponse dataBlock:dataBlock];
}

- (void)component:(NSString *)componentKey category:(NSString *)categoryKey error:(NSError *)error httpURLResponse:(NSHTTPURLResponse *)httpURLResponse dataBlock:(NSDictionary *(^)(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict))dataBlock
{
    if ([self.configuration count])
    {
        componentKey = [componentKey stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([componentKey length] && [categoryKey length])
        {
            BOOL categoryIsEnabled = _defaultOn;
            NSDictionary *component = [self.configuration dictionaryForKey:componentKey];
            NSDictionary *category = nil;
            if ([component count])
            {
                id componentCategoriesOnObject = [component safeObjectForKey:@"on"];
                if (componentCategoriesOnObject)
                {
                    categoryIsEnabled = [component boolForKey:@"on"];
                }

                id categoryObject = [component safeObjectForKey:categoryKey];
                if (categoryObject)
                {
                    if ([categoryObject isKindOfClass:[NSDictionary class]])
                    {
                        category = categoryObject;
                        id categoryOnObject = [category safeObjectForKey:@"on"];
                        if (categoryOnObject)
                        {
                            categoryIsEnabled = [category boolForKey:@"on"];
                        }
                    }
                    else
                    {
                        categoryIsEnabled = [component boolForKey:categoryKey];
                    }
                }
            }
            if (categoryIsEnabled)
            {
                BOOL shouldLog = categoryIsEnabled;
                NSDictionary *errorDictionary = nil;
                NSDictionary *responseDictionary = nil;
                if (error)
                {
                    NSError *under = [error userInfo][NSUnderlyingErrorKey];
                    if (under)
                    {
                        errorDictionary = @{@"d": error.domain ?: [NSNull null],
                                            @"c": @(error.code),
                                            @"m": error.localizedDescription ?: [NSNull null],
                                            @"u": @{@"d":under.domain ?: [NSNull null],
                                                    @"c":@(under.code),
                                                    @"m": under.localizedDescription ?: [NSNull null]}};
                    }
                    else
                    {
                        errorDictionary = @{@"d":error.domain ?: [NSNull null],
                                            @"c":@(error.code),
                                            @"m": error.localizedDescription ?: [NSNull null]};
                    }
                    NSDictionary *ignoreTheseCodes = [category dictionaryForKey:@"mute-error-codes"];
                    if (!ignoreTheseCodes)
                    {
                        ignoreTheseCodes = [component dictionaryForKey:@"mute-error-codes"];
                        if (!ignoreTheseCodes)
                        {
                            ignoreTheseCodes = [self.configuration dictionaryForKey:@"mute-error-codes"];
                        }
                    }
                    if ([ignoreTheseCodes count])
                    {
                        BOOL ignore = [ignoreTheseCodes boolForKey:@"default"]; // will be NO if not present, which is what we want
                        NSString *key = [@(error.code) stringValue];
                        id ignoreCodeObject = [ignoreTheseCodes safeObjectForKey:key];
                        if (ignoreCodeObject)
                        {
                            ignore = [ignoreTheseCodes boolForKey:key];
                        }
                        shouldLog = !ignore;
                    }
                }
                if (shouldLog && httpURLResponse)
                {
                    responseDictionary = @{@"c": @(httpURLResponse.statusCode)};
                    NSDictionary *ignoreTheseCodes = [category dictionaryForKey:@"mute-status-codes"];
                    if (!ignoreTheseCodes)
                    {
                        ignoreTheseCodes = [component dictionaryForKey:@"mute-status-codes"];
                        if (!ignoreTheseCodes)
                        {
                            ignoreTheseCodes = [self.configuration dictionaryForKey:@"mute-status-codes"];
                        }
                    }
                    if ([ignoreTheseCodes count])
                    {
                        BOOL ignore = [ignoreTheseCodes boolForKey:@"default"]; // will be NO if not present, which is what we want
                        NSString *key = [@(httpURLResponse.statusCode) stringValue];
                        id ignoreCodeObject = [ignoreTheseCodes safeObjectForKey:key];
                        if (ignoreCodeObject)
                        {
                            ignore = [ignoreTheseCodes boolForKey:key];
                        }
                        shouldLog = !ignore;
                    }
                }
                if (shouldLog)
                {
                    NSDate *now = [NSDate date];
                    NSDictionary *dataDictionary = dataBlock ? dataBlock(self, componentKey, component, categoryKey, category) : nil;
                    if (dataDictionary)
                    {
                        NSString *username = self.username;
                        NSString *host = [self.configuration stringForKey:@"host"] ?: @"logs.papertrailapp.com";
                        NSNumber *port = [self.configuration numberForKey:@"port"] ?: @27889;
                        [self logWithDate:now host:host port:port componentKey:componentKey categoryKey:categoryKey username:username dataDictionary:dataDictionary errorDictionary:errorDictionary responseDictionary:responseDictionary];
                    }
                }
            }
        }
    }
}

- (void)logWithDate:(NSDate *)now host:(NSString *)host port:(NSNumber *)port componentKey:(NSString *)componentKey categoryKey:(NSString *)categoryKey username:(NSString *)username dataDictionary:(NSDictionary *)dataDictionary errorDictionary:(NSDictionary *)errorDictionary responseDictionary:(NSDictionary *)responseDictionary
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if ([host length] && port)
        {
            NSMutableDictionary *md = [_template mutableCopy];
            md[@"data"] = dataDictionary;
            if (errorDictionary)
            {
                md[@"err"] = errorDictionary;
            }
            if (responseDictionary)
            {
                md[@"resp"] = responseDictionary;
            }
            if ([username length])
            {
                md[@"user"] = username;
            }
            md[@"lang"] = [[NSLocale preferredLanguages] firstObject] ?: [NSNull null];
            md[@"as"] = @([[UIApplication sharedApplication] applicationState]);
            NSError *error = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:md options:0 error:&error];
            if (data)
            {
                NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if ([message length])
                {
                    NSString *preamble = [NSString stringWithFormat:@"<22>%@ DrawQuest %@: %@ ", [_dateFormatter stringFromDate:now], componentKey, categoryKey];
                    NSUInteger lengthOfPremable = [preamble length];

                    message = [message stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\\r\\n"];
                    message = [message stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
                    message = [message stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
                    // CLS_LOG(@"%@", [preamble stringByAppendingString:message]);

                    NSMutableString *remaining = [[NSMutableString alloc] initWithString:message];
                    NSUInteger maxChunkLength = 1024 - lengthOfPremable;
                    if (maxChunkLength)
                    {
                        while ([remaining length])
                        {
                            if ([remaining length] > maxChunkLength)
                            {
                                NSString *chunk = [remaining substringToIndex:maxChunkLength];
                                NSString *outputString = [preamble stringByAppendingString:chunk ?: @""];
                                NSData *output = [outputString dataUsingEncoding:NSUTF8StringEncoding];
                                if ([output length])
                                {
                                    [_udpSocket sendData:output toHost:host port:(uint16_t)[port intValue] withTimeout:-1 tag:1];
                                }
                                [remaining deleteCharactersInRange:NSMakeRange(0, maxChunkLength)];
                            }
                            else
                            {
                                NSString *outputString = [preamble stringByAppendingString:remaining ?: @""];
                                NSData *output = [outputString dataUsingEncoding:NSUTF8StringEncoding];
                                if ([output length])
                                {
                                    [_udpSocket sendData:output toHost:host port:(uint16_t)[port intValue] withTimeout:-1 tag:1];
                                }
                                break;
                            }
                        }
                    }
                }
            }
        }
    });
}

#pragma mark -
#pragma mark GCDAsyncUdpSocketDelegate methods

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"DQPapertrailLogger succeeded");
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"DQPapertrailLogger failed: %@", error);
}

@end
