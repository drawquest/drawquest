//
//  RCSFSMTests.m
//  RCSFSMTests
//
//  Created by Jim Roepcke on 2013-05-19.
//  Copyright (c) 2013 Roepcke Computing Solutions. All rights reserved.
//

#import "RCSFSMTests.h"
#import "RCSState.h"
#import "RCSStatechart.h"

@class TestContext;

@interface TestState : RCSBaseState

@end

@interface TestStatechart : RCSBaseStatechart

@end

@implementation TestState

@end

@implementation TestStatechart

@end

@interface TestState (Transitions)

- (void)start:(TestContext *)context;
- (void)gotoA:(TestContext *)context;

@end

@interface TestContext : NSObject <RCSStateContext>

@property (nonatomic, weak) TestState *state;
@property (nonatomic, assign) BOOL enteredStateA;

@end


@interface TestChartContext : NSObject <RCSStatechartContext>

@property (nonatomic, weak) TestStatechart *statechart;
@property (nonatomic, strong) NSMutableArray *statechartStack;
@property (nonatomic, assign) BOOL enteredSubA;

@end

@implementation TestContext

- (id)init
{
    self = [super init];
    if (self)
    {
        _state = [[TestState state] startState];
    }
    return self;
}

- (void)_stateContextDidEnterErrorState
{
    [NSException raise:NSInternalInconsistencyException format:@"TestContext did enter error state"];
}

- (void)_enteringStateA
{
    self.enteredStateA = YES;
}

@end

@implementation TestChartContext

- (id)init
{
    self = [super init];
    if (self) {
        _statechart = [[TestStatechart statechart] startStatechart];
        _statechartStack = [NSMutableArray new];
    }
    return self;
}

- (id<RCSStatechart>)pushStatechart
{
    id<RCSStatechart> result = self.statechart;
    if (result) [_statechartStack addObject:result];
    return result;
}

- (id<RCSStatechart>)popStatechart
{
    id<RCSStatechart> result = [_statechartStack lastObject];
    if (result) [_statechartStack removeLastObject];
    return result;
}

- (void)_enteringSubA
{
    self.enteredSubA = YES;
}

- (void)_statechartContextDidEnterErrorStatechart
{
    [NSException raise:NSInternalInconsistencyException format:@"TestChartContext did enter error statechart"];
}

@end

@implementation RCSFSMTests
{
    TestContext *_ctx;
    TestChartContext *_chartCtx;
}

+ (void)initialize
{
    if (self == [RCSFSMTests class])
    {
        id <RCSState> Base = [TestState state];
        id <RCSState> Error = [Base stateNamed:@"Error"];
        id <RCSState> Start = [Base stateNamed:@"Start"];
        id <RCSState> Running = [Base stateNamed:@"Running"];
        id <RCSState> StateA = [Base stateNamed:@"StateA"];
        id <RCSState> StateB = [Base stateNamed:@"StateB"];

        [Base declareErrorState:Error];
        [Base declareStartState:Start];

        SEL start = [Base transitionToErrorStateWhen:@selector(start:)];
        [Start when:start transitionTo:Running];

        SEL gotoA = [Running when:@selector(gotoA:) transitionTo:StateA];

        [StateA whenEnteringPerform:@selector(_enteringStateA)];

        id <RCSStatechart> ChartBase = [TestStatechart statechart];
        id <RCSStatechart> ChartError = [ChartBase statechartNamed:@"Error"];
        id <RCSStatechart> ChartStart = [ChartBase statechartNamed:@"Start"];

        id <RCSStatechart> ChartSubA = [ChartBase statechartNamed:@"SubA"];

        [ChartBase declareErrorStatechart:ChartError];
        [ChartBase declareStartStatechart:ChartStart];

        [ChartSubA whenEnteringPerform:@selector(_enteringSubA)];
    }
}

- (void)setUp
{
    [super setUp];
    _ctx = [[TestContext alloc] init];
    _chartCtx = [[TestChartContext alloc] init];
}

- (void)tearDown
{
    // Tear-down code here.
    _chartCtx = nil;
    _ctx = nil;
    [super tearDown];
}

- (void)testInitialize
{
    STAssertNotNil(NSClassFromString(@"TestStateStart"), @"Start state class not found");
    STAssertEquals([[TestState state] stateNamed:@"Start"], [[TestState state] startState], @"start state not set");
    STAssertEquals([[TestState state] stateNamed:@"Start"], [[[TestState state] stateNamed:@"Start"] startState], @"start state not set");

    STAssertEquals([[TestState state] stateNamed:@"Error"], [[TestState state] errorState], @"error state not set on Base state");
    STAssertEquals([[TestState state] stateNamed:@"Error"], [[[TestState state] stateNamed:@"Start"] errorState], @"error state not set on Start state");
}

- (void)testInit
{
    STAssertNotNil(_ctx, @"context doesn't exist");
    STAssertEquals([_ctx state], [[TestState state] startState], @"context should start in the Start state");
}

- (void)testTransition
{    
    [_ctx.state transition:_ctx to:[[TestState state] stateNamed:@"StateB"]];
    STAssertEquals(_ctx.state, [[TestState state] stateNamed:@"StateB"], nil);
}

- (void)testTransitionStartToRunning
{
    [_ctx.state start:_ctx];
    STAssertEquals([_ctx state], [[TestState state] stateNamed:@"Running"], @"context should start in the Running state");
}

- (void)testStateContextDidEnterErrorState
{
    [_ctx.state start:_ctx];
    // the Running state doesn't implement the start: transition, so it should run the base implementation with transitions to Error
    // the context class implements _stateContextDidEnterErrorState which throws an exception
    STAssertThrows([_ctx.state start:_ctx], @"start from Running should transition to error state, which should throw an exception");
}

- (void)testWhenEnteringPerform
{
    [_ctx.state start:_ctx];
    [_ctx.state gotoA:_ctx];
    STAssertTrue(_ctx.enteredStateA, nil);
}

- (void)testChartPush
{
    [_chartCtx.statechart transition:_chartCtx push:[[TestStatechart statechart] statechartNamed:@"SubA"]];
    STAssertEquals(_chartCtx.statechart, [[TestStatechart statechart] statechartNamed:@"SubA"], nil);
    STAssertEquals([_chartCtx.statechartStack count], (NSUInteger)1, nil);
    STAssertEquals([_chartCtx.statechartStack lastObject], [[TestStatechart statechart] startStatechart], nil);
    STAssertTrue(_chartCtx.enteredSubA, nil);
}

- (void)testChartPop
{
    [_chartCtx.statechart transition:_chartCtx push:[[TestStatechart statechart] statechartNamed:@"SubA"]];
    [_chartCtx.statechart pop:_chartCtx];
    STAssertEquals([_chartCtx.statechartStack count], (NSUInteger)0, nil);
    STAssertEquals(_chartCtx.statechart, [[TestStatechart statechart] startStatechart], nil);
}

@end
