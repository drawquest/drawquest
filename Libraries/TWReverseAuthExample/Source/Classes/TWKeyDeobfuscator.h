//
//  TWKeyDeobfuscator.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 6/13/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

// Keys for dictionary returned from the deobfuscator
extern NSString *const TWKeyDeobfuscatorTypeKey;
extern NSString *const TWKeyDeobfuscatorTypeSecret;

// This class implements the following algorithm:
//  * Swap case of lhs and rhs of the @ symbol in the pair string
//  * Rotate the string to the left by 6 characters
//  * Split on the @ to obtain key and secret

@interface TWKeyDeobfuscator : NSObject

// pairString should be in the form of foo@BAR.
// NOTE: Input string should not contain multibyte characters, and be formatted as
//       UTF-8 text.
+ (NSDictionary *)keysForPairString:(NSString *)pairString;

@end
