//
//  RCSState.m
//  Created by Jim Roepcke.
//  See license below.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "RCSState.h"

static NSUInteger RCSNumberOfArgumentsInSelector(SEL sel);
static NSUInteger RCSNumberOfArgumentsInSelector(SEL sel)
{
    NSString *selString = NSStringFromSelector(sel);
    CFStringRef selfAsCFStr = (__bridge CFStringRef)selString;

    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength(selfAsCFStr);
    CFStringInitInlineBuffer(selfAsCFStr, &inlineBuffer, CFRangeMake(0, length));

    NSUInteger counter = 0;

    for (CFIndex i = 0; i < length; i++) {
        UniChar c = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, i);
        if (c == (UniChar)':') counter += 1;
    }

    return counter;
}

@implementation RCSBaseState

+ (id) state
{
	id<RCSState> result = objc_getAssociatedObject(self, @"sharedInstance");
	if (!result)
    {
		result = [[[self class] alloc] init];
		objc_setAssociatedObject(self, @"sharedInstance", result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return result;
}

- (id<RCSState>)startState
{
    return nil;
}

- (NSString *)displayNameExcludedPrefix
{
    return nil;
}

- (NSString *)displayName
{
    NSString *className = NSStringFromClass([self class]);
    return [className substringFromIndex:[[self displayNameExcludedPrefix] length]];
}

- (BOOL)shouldLogTransitions
{
    return NO;
}

- (BOOL)shouldTellContextDidEnterErrorState
{
    return YES;
}

- (id<RCSState>)errorState
{
    return nil;
}

- (void)enter:(id<RCSStateContext>)context
{
    if ([self errorState] == self)
    {
        if ([self shouldTellContextDidEnterErrorState])
        {
            [context _stateContextDidEnterErrorState];
        }
    }
}

- (void)transition:(id<RCSStateContext>)context to:(id<RCSState>)state
{
    if ([self shouldLogTransitions])
    {
        NSLog(@"transition %@ to %@", context, [state displayName]);
    }
    [context setState:state];
    [state enter:context];
}

- (void)logStateTransitionError:(SEL)sel forContext:(id<RCSStateContext>)context
{
    NSLog(@"%@(%@): %@ is not a supported request", context, [self displayName], NSStringFromSelector(sel));
}

- (id<RCSState>)stateNamed:(NSString *)name
{
    NSString *baseName = NSStringFromClass([self class]);
    NSString *stateClassName = [baseName stringByAppendingString:name];
    Class stateClass = NSClassFromString(stateClassName);
    if (!stateClass)
    {
        stateClass = objc_allocateClassPair([self class], [stateClassName cStringUsingEncoding:NSASCIIStringEncoding], 0);
        objc_registerClassPair(stateClass);
    }
    return [stateClass state];
}

- (id<RCSState>)declareErrorState:(id<RCSState>)errorState
{
    if (errorState)
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSState> _self) {
            return errorState;
        });
        class_addMethod([self class], @selector(errorState), imp, "v@:");
    }
    return errorState;
}

- (id<RCSState>)declareStartState:(id<RCSState>)startState
{
    if (startState)
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSState> _self) {
            return startState;
        });
        class_addMethod([self class], @selector(startState), imp, "v@:");
    }
    return startState;
}

- (void)whenEnteringPerform:(SEL)action
{
    if (action && (RCSNumberOfArgumentsInSelector(action) == 0))
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSState> _self, id<RCSStateContext> context) {
            struct objc_super objcSuper = {_self, [_self superclass]};
            objc_msgSendSuper(&objcSuper, @selector(enter:), context);
            objc_msgSend(context, action);
        });
        class_addMethod([self class], @selector(enter:), imp, "v@:@");
    }
}

- (SEL)transitionToErrorStateWhen:(SEL)selector
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSState> _self, id<RCSStateContext> context, id _) {
                [_self logStateTransitionError:selector forContext:context];
                id<RCSState> errorState = [_self errorState];
                if (errorState) [_self transition:context to:errorState];
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSState> _self, id<RCSStateContext> context) {
                [_self logStateTransitionError:selector forContext:context];
                id<RCSState> errorState = [_self errorState];
                if (errorState) [_self transition:context to:errorState];
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

- (SEL)doNothingWhen:(SEL)selector
{
    return [self _declareTransition:selector preAction:(SEL)0 transitionTo:nil postAction:(SEL)0];
}

- (SEL)when:(SEL)selector perform:(SEL)action
{
    return [self _declareTransition:selector preAction:action transitionTo:nil postAction:(SEL)0];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSState>)state
{
    return [self _declareTransition:selector preAction:(SEL)0 transitionTo:state postAction:(SEL)0];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSState>)state after:(SEL)action
{
    return [self _declareTransition:selector preAction:action transitionTo:state postAction:(SEL)0];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSState>)state before:(SEL)action
{
    return [self _declareTransition:selector preAction:(SEL)0 transitionTo:state postAction:action];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSState>)state before:(SEL)postAction after:(SEL)preAction
{
    return [self _declareTransition:selector preAction:preAction transitionTo:state postAction:postAction];
}

- (SEL)_declareTransition:(SEL)selector preAction:(SEL)preAction transitionTo:(id<RCSState>)state postAction:(SEL)postAction
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSState> _self, id<RCSStateContext> context, id object) {
                if (preAction) objc_msgSend(context, preAction, object);
                if (state) [_self transition:context to:state];
                if (postAction) objc_msgSend(context, postAction, object);
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSState> _self, id<RCSStateContext> context) {
                if (preAction) objc_msgSend(context, preAction);
                if (state) [_self transition:context to:state];
                if (postAction) objc_msgSend(context, postAction);
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

@end

/*
 * Copyright 2013 Jim Roepcke <jim@roepcke.com>. All rights reserved.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
