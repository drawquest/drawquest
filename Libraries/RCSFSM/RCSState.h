//
//  RCSState.h
//  Created by Jim Roepcke.
//  See license below.
//

@protocol RCSState;

/*
 * An object that has a FSM.
 */
@protocol RCSStateContext <NSObject>

@property (nonatomic, weak) id<RCSState> state;

- (void)_stateContextDidEnterErrorState;

@end

/*
 * Represents a state in a FSM.
 */
@protocol RCSState <NSObject>

// access singleton instance
+ (id<RCSState>)state;
- (id<RCSState>)startState;

- (NSString *)displayNameExcludedPrefix; // remove this prefix from the class name to derive the default displayName
- (NSString *)displayName; // class name, sans prefix from displayNameExcludedPrefix

- (BOOL)shouldLogTransitions; // returns NO by default

- (BOOL)shouldTellContextDidEnterErrorState; // returns YES by default
- (id<RCSState>)errorState;

// called by transition:to: just after the context's state is set to this state
- (void)enter:(id<RCSStateContext>)context;

// set's the context's state to the specified state, then calls -enter: on the specified state
- (void)transition:(id<RCSStateContext>)context to:(id<RCSState>)state;

// call this before transitioning to your FSM's Error state
- (void)logStateTransitionError:(SEL)sel forContext:(id<RCSStateContext>)context;

- (id<RCSState>)stateNamed:(NSString *)name;
- (id<RCSState>)declareErrorState:(id<RCSState>)errorState;
- (id<RCSState>)declareStartState:(id<RCSState>)startState;

- (SEL)transitionToErrorStateWhen:(SEL)selector;
- (void)whenEnteringPerform:(SEL)action;
- (SEL)doNothingWhen:(SEL)selector;
- (SEL)when:(SEL)selector perform:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSState>)state;
- (SEL)when:(SEL)selector transitionTo:(id<RCSState>)state after:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSState>)state before:(SEL)action;
- (SEL)when:(SEL)selector transitionTo:(id<RCSState>)state before:(SEL)postAction after:(SEL)preAction;

@end

@interface RCSBaseState : NSObject <RCSState>

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
