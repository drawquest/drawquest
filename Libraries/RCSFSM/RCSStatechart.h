//
//  RCSStatechart.h
//  RCSFSM
//
//  Created by Jim Roepcke on 2013-05-29.
//  Copyright (c) 2013 Roepcke Computing Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RCSStatechart;

@protocol RCSStatechartContext <NSObject>

@property (nonatomic, weak) id<RCSStatechart> statechart;

- (void)_statechartContextDidEnterErrorStatechart;

- (id<RCSStatechart>)pushStatechart;
- (id<RCSStatechart>)popStatechart;

@end

@protocol RCSStatechart <NSObject>

// access singleton instance
+ (id<RCSStatechart>)statechart;
- (id<RCSStatechart>)startStatechart;

- (NSString *)displayNameExcludedPrefix; // remove this prefix from the class name to derive the default displayName
- (NSString *)displayName; // class name, sans prefix from displayNameExcludedPrefix

- (BOOL)shouldLogTransitions; // returns NO by default

- (BOOL)shouldTellContextDidEnterErrorStatechart; // returns YES by default
- (id<RCSStatechart>)errorStatechart;

// called by transition:to: just after the context's state is set to this state
- (void)enter:(id<RCSStatechartContext>)context;

// set's the context's state to the specified state, then calls -enter: on the specified state
- (void)transition:(id<RCSStatechartContext>)context to:(id<RCSStatechart>)statechart;

// call this before transitioning to your FSM's Error state
- (void)logStateTransitionError:(SEL)sel forContext:(id<RCSStatechartContext>)context;

- (id<RCSStatechart>)statechartNamed:(NSString *)name;
- (id<RCSStatechart>)declareErrorStatechart:(id<RCSStatechart>)errorStatechart;
- (id<RCSStatechart>)declareStartStatechart:(id<RCSStatechart>)startStatechart;

- (SEL)transitionToErrorStatechartWhen:(SEL)selector;
- (void)whenEnteringPerform:(SEL)action;
- (SEL)doNothingWhen:(SEL)selector;
- (SEL)when:(SEL)selector perform:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSStatechart>)statechart;
- (SEL)when:(SEL)selector transitionTo:(id<RCSStatechart>)statechart after:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSStatechart>)statechart before:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSStatechart>)statechart before:(SEL)postAction after:(SEL)preAction;

- (void)transition:(id<RCSStatechartContext>)context push:(id<RCSStatechart>)statechart;
- (void)pop:(id<RCSStatechartContext>)context;

- (SEL)when:(SEL)selector push:(id<RCSStatechart>)statechart;
- (SEL)when:(SEL)selector push:(id<RCSStatechart>)statechart after:(SEL)action;
- (SEL)when:(SEL)selector push:(id<RCSStatechart>)statechart before:(SEL)action;
- (SEL)when:(SEL)selector push:(id<RCSStatechart>)statechart before:(SEL)postAction after:(SEL)preAction;

- (SEL)popWhen:(SEL)selector;
- (SEL)popWhen:(SEL)selector after:(SEL)action;
- (SEL)popWhen:(SEL)selector before:(SEL)action;
- (SEL)popWhen:(SEL)selector before:(SEL)postAction after:(SEL)preAction;

@end

@interface RCSBaseStatechart: NSObject <RCSStatechart>

@end
