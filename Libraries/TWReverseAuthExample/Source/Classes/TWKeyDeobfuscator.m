//
//  TWKeyDeobfuscator.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 6/13/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "TWKeyDeobfuscator.h"

NSString *const TWKeyDeobfuscatorTypeKey = @"TWKeyDeobfuscatorTypeKey";
NSString *const TWKeyDeobfuscatorTypeSecret = @"TWKeyDeobfuscatorTypeSecret";

@implementation TWKeyDeobfuscator

+ (NSDictionary *)keysForPairString:(NSString *)pairString
{
    NSArray *pairs = [self _splitPairStringWithString:pairString];
    NSArray *rotatedPairs = [self _rotateLeftString:pairs[0] by:6 addingToRightString:pairs[1]];
    NSArray *resultPairs = [self _swapCaseForPairs:rotatedPairs];
    if ([resultPairs count] != 2)
        return nil;

    return @{ TWKeyDeobfuscatorTypeKey: resultPairs[0], TWKeyDeobfuscatorTypeSecret : resultPairs[1] };
}

+ (NSArray *)_rotateLeftString:(NSString *)leftString by:(NSInteger)amount addingToRightString:(NSString *)rightString
{
    if ([leftString length] < amount || rightString == nil)
        return nil;

    NSString *substring = [leftString substringToIndex:amount];
    if (substring == nil)
        return nil;

    NSString *newLeftString = [leftString substringFromIndex:amount];
    NSString *newRightString = [rightString stringByAppendingString:substring];

    return @[ newLeftString, newRightString ];
}

+ (NSArray *)_splitPairStringWithString:(NSString *)pairString
{
    return [pairString componentsSeparatedByString:@"@"];
}

+ (NSString *)_swapCaseForString:(NSString *)string
{
    if ([string length] == 0)
        return nil;

    const char* s = [string UTF8String];
    NSMutableString* r = [NSMutableString stringWithCapacity:[string length]];

    for(int i = 0; i < [string length]; i++)
    {
        if(isupper(s[i]))
            [r appendFormat:@"%c", tolower(s[i])];
        else if(islower(s[i]))
            [r appendFormat:@"%c", toupper(s[i])];
        else
            [r appendFormat:@"%c", s[i]];
    }
    return r;
}

+ (NSArray *)_swapCaseForPairs:(NSArray *)pairs
{
    if ([pairs count] != 2)
        return nil;
    return @[ [self _swapCaseForString:pairs[0]], [self _swapCaseForString:pairs[1]] ];
}

@end
