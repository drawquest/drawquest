//
//  RCSStatechart.m
//  RCSFSM
//
//  Created by Jim Roepcke on 2013-05-29.
//  Copyright (c) 2013 Roepcke Computing Solutions. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "RCSStatechart.h"

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

@implementation RCSBaseStatechart

+ (id)statechart
{
	id<RCSStatechart> result = objc_getAssociatedObject(self, @"sharedInstance");
	if (!result)
    {
		result = [[[self class] alloc] init];
		objc_setAssociatedObject(self, @"sharedInstance", result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return result;
}

- (id<RCSStatechart>)startStatechart
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

- (BOOL)shouldTellContextDidEnterErrorStatechart
{
    return YES;
}

- (id<RCSStatechart>)errorStatechart
{
    return nil;
}

- (void)enter:(id<RCSStatechartContext>)context
{
    if ([self errorStatechart] == self)
    {
        if ([self shouldTellContextDidEnterErrorStatechart])
        {
            [context _statechartContextDidEnterErrorStatechart];
        }
    }
}

- (void)transition:(id<RCSStatechartContext>)context to:(id<RCSStatechart>)statechart
{
    if ([self shouldLogTransitions])
    {
        NSLog(@"transition %@ to %@", context, [statechart displayName]);
    }
    [context setStatechart:statechart];
    [statechart enter:context];
}

- (void)logStateTransitionError:(SEL)sel forContext:(id<RCSStatechartContext>)context
{
    NSLog(@"%@(%@): %@ is not a supported request", context, [self displayName], NSStringFromSelector(sel));
}

- (id<RCSStatechart>)statechartNamed:(NSString *)name
{
    NSString *baseName = NSStringFromClass([self class]);
    NSString *statechartClassName = [baseName stringByAppendingString:name];
    Class statechartClass = NSClassFromString(statechartClassName);
    if (!statechartClass)
    {
        statechartClass = objc_allocateClassPair([self class], [statechartClassName cStringUsingEncoding:NSASCIIStringEncoding], 0);
        objc_registerClassPair(statechartClass);
    }
    return [statechartClass statechart];
}

- (id<RCSStatechart>)declareErrorStatechart:(id<RCSStatechart>)errorStatechart
{
    if (errorStatechart)
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self) {
            return errorStatechart;
        });
        class_addMethod([self class], @selector(errorStatechart), imp, "v@:");
    }
    return errorStatechart;
}

- (id<RCSStatechart>)declareStartStatechart:(id<RCSStatechart>)startStatechart
{
    if (startStatechart)
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self) {
            return startStatechart;
        });
        class_addMethod([self class], @selector(startStatechart), imp, "v@:");
    }
    return startStatechart;
}

- (void)whenEnteringPerform:(SEL)action
{
    if (action && (RCSNumberOfArgumentsInSelector(action) == 0))
    {
        IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context) {
            struct objc_super objcSuper = {_self, [_self superclass]};
            objc_msgSendSuper(&objcSuper, @selector(enter:), context);
            objc_msgSend(context, action);
        });
        class_addMethod([self class], @selector(enter:), imp, "v@:@");
    }
}

- (SEL)transitionToErrorStatechartWhen:(SEL)selector
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context, id _) {
                [_self logStateTransitionError:selector forContext:context];
                id<RCSStatechart> errorStatechart = [_self errorStatechart];
                if (errorStatechart) [_self transition:context to:errorStatechart];
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context) {
                [_self logStateTransitionError:selector forContext:context];
                id<RCSStatechart> errorStatechart = [_self errorStatechart];
                if (errorStatechart) [_self transition:context to:errorStatechart];
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

- (SEL)when:(SEL)selector transitionTo:(id<RCSStatechart>)statechart
{
    return [self _declareTransition:selector preAction:(SEL)0 transitionTo:statechart postAction:(SEL)0];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSStatechart>)statechart after:(SEL)action
{
    return [self _declareTransition:selector preAction:action transitionTo:statechart postAction:(SEL)0];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSStatechart>)statechart before:(SEL)action
{
    return [self _declareTransition:selector preAction:(SEL)0 transitionTo:statechart postAction:action];
}

- (SEL)when:(SEL)selector transitionTo:(id<RCSStatechart>)statechart before:(SEL)postAction after:(SEL)preAction
{
    return [self _declareTransition:selector preAction:preAction transitionTo:statechart postAction:postAction];
}

- (SEL)_declareTransition:(SEL)selector preAction:(SEL)preAction transitionTo:(id<RCSStatechart>)statechart postAction:(SEL)postAction
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context, id object) {
                if (preAction) objc_msgSend(context, preAction, object);
                if (statechart) [_self transition:context to:statechart];
                if (postAction) objc_msgSend(context, postAction, object);
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context) {
                if (preAction) objc_msgSend(context, preAction);
                if (statechart) [_self transition:context to:statechart];
                if (postAction) objc_msgSend(context, postAction);
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

- (void)transition:(id<RCSStatechartContext>)context push:(id<RCSStatechart>)state
{
    if ([self shouldLogTransitions])
    {
        NSLog(@"transition %@ push %@", context, [state displayName]);
    }
    [context pushStatechart];
    [context setStatechart:state];
    [state enter:context];
}

- (void)pop:(id<RCSStatechartContext>)context
{
    id<RCSStatechart> state = [context popStatechart];
    if ([self shouldLogTransitions])
    {
        NSLog(@"transition %@ pop %@", context, [state displayName]);
    }
    [context setStatechart:state];
    [state enter:context];
}

- (SEL)when:(SEL)selector push:(id<RCSStatechart>)state
{
    return [self _declareTransition:selector preAction:(SEL)0 push:state postAction:(SEL)0];
}

- (SEL)when:(SEL)selector push:(id<RCSStatechart>)state after:(SEL)action
{
    return [self _declareTransition:selector preAction:action push:state postAction:(SEL)0];
}

- (SEL)when:(SEL)selector push:(id<RCSStatechart>)state before:(SEL)action
{
    return [self _declareTransition:selector preAction:(SEL)0 push:state postAction:action];
}

- (SEL)when:(SEL)selector push:(id<RCSStatechart>)state before:(SEL)postAction after:(SEL)preAction
{
    return [self _declareTransition:selector preAction:preAction push:state postAction:postAction];
}

- (SEL)_declareTransition:(SEL)selector preAction:(SEL)preAction push:(id<RCSStatechart>)state postAction:(SEL)postAction
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context, id object) {
                if (preAction) objc_msgSend(context, preAction, object);
                if (state) [_self transition:context push:state];
                if (postAction) objc_msgSend(context, postAction, object);
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context) {
                if (preAction) objc_msgSend(context, preAction);
                if (state) [_self transition:context push:state];
                if (postAction) objc_msgSend(context, postAction);
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

- (SEL)popWhen:(SEL)selector
{
    return [self _declarePop:selector preAction:(SEL)0 postAction:(SEL)0];
}

- (SEL)popWhen:(SEL)selector after:(SEL)action
{
    return [self _declarePop:selector preAction:action postAction:(SEL)0];
}

- (SEL)popWhen:(SEL)selector before:(SEL)action
{
    return [self _declarePop:selector preAction:(SEL)0 postAction:action];
}

- (SEL)popWhen:(SEL)selector before:(SEL)postAction after:(SEL)preAction
{
    return [self _declarePop:selector preAction:preAction postAction:postAction];
}

- (SEL)_declarePop:(SEL)selector preAction:(SEL)preAction postAction:(SEL)postAction
{
    switch (RCSNumberOfArgumentsInSelector(selector))
    {
        case 2:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context, id object) {
                if (preAction) objc_msgSend(context, preAction, object);
                [_self pop:context];
                if (postAction) objc_msgSend(context, postAction, object);
            });
            class_addMethod([self class], selector, imp, "v@:@@");
            break;
        }
        case 1:
        default:
        {
            IMP imp = imp_implementationWithBlock(^(id<RCSStatechart> _self, id<RCSStatechartContext> context) {
                if (preAction) objc_msgSend(context, preAction);
                [_self pop:context];
                if (postAction) objc_msgSend(context, postAction);
            });
            class_addMethod([self class], selector, imp, "v@:@");
            break;
        }
    }
    return selector;
}

@end
