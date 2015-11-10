// Frameworks
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

// Additions
#import "NSArray+STAdditions.h"
#import "NSData+STAdditions.h"
#import "NSDate+STAdditions.h"
#import "NSDictionary+STAdditions.h"
#import "NSFileHandle+STAdditions.h"
#import "NSFileManager+STAdditions.h"
#import "NSManagedObject+STAdditions.h"
#import "NSMutableString+STAdditions.h"
#import "NSObject+STAdditions.h"
#import "NSOutputStream+STAdditions.h"
#import "NSStream+STAdditions.h"
#import "NSString+STAdditions.h"
#import "NSURL+STAdditions.h"
#import "NSUserDefaults+STAdditions.h"

// Third Party
#import "NSData+STBase64.h"

// Constants
#define STDefaultAnimationDuration 0.3

// Macros
#define KVO_SET(_key_, _value_) [self willChangeValueForKey:@#_key_]; \
self._key_ = (_value_); \
[self didChangeValueForKey:@#_key_];

// --- iOS Only ---

#if TARGET_OS_IPHONE


// UIKit Additions
#import "UIView+STAdditions.h"
#import "UIColor+STAdditions.h"

// Macros
#define STDealloc(x) [x release]; x = nil;
#define STCachedColor(method, r, g, b, a) \
+ (UIColor *)method { \
static volatile UIColor *cached = nil; \
if (!cached) { \
UIColor *color = [[UIColor alloc] initWithRed:(r / 255.0f) green:(g / 255.0f) blue:(b / 255.0f) alpha:a]; \
if (cached) { \
[color release]; \
} else { \
cached = color; \
} \
} \
return (UIColor *)cached; \
}

#define STCachedGrayscaleColor(method, w, a) \
+ (UIColor *)method { \
static volatile UIColor *cached = nil; \
if (!cached) { \
UIColor *color = [[UIColor alloc] initWithWhite:w alpha:a]; \
if (cached) { \
[color release]; \
} else { \
cached = color; \
} \
} \
return (UIColor *)cached; \
}

#define STCachedFont(method, name, insize) \
+ (UIFont *)method { \
static volatile UIFont *cached = nil; \
if (!cached) { \
UIFont *font = [UIFont fontWithName:name size:insize]; \
if (cached) { \
[font release]; \
} else { \
cached = [font retain]; \
} \
} \
return (UIFont *)cached; \
}

#define STCachedSystemFont(method, size, bold) \
+ (UIFont *)method { \
static volatile UIFont *cached = nil; \
if (!cached) { \
UIFont *font; \
if (bold) { \
font = [UIFont boldSystemFontOfSize:size]; \
} else { \
font = [UIFont systemFontOfSize:size]; \
} \
if (cached) { \
[font release]; \
} else { \
cached = [font retain]; \
} \
} \
return (UIFont *)cached; \
}

#define STStringFromPoint(point) [NSString stringWithFormat:@"<CGPoint: (x: %f; y: %f)>", point.x, point.y]

#define STStringFromSize(size) [NSString stringWithFormat:@"<CGSize: (width: %f; height: %f)>", size.width, size.height]

#define STStringFromRect(rect) [NSString stringWithFormat:@"<CGRect: (origin: %f; %f) (size: %f; %f)>", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height]

#define STRectAdjustedByWidth(rect, w) CGRectMake(rect.origin.x, rect.origin.y, rect.size.width + w, rect.size.height)

#define STRectAdjustedByHeight(rect, h) CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height + h)

#endif
