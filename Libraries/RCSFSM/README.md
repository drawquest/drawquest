# RCSFSM

Finite State Machines (FSM) modelled with Objective-C, using the GOF's [State Design pattern](http://en.wikipedia.org/wiki/State_pattern).

Initially developed for a project in a [graduate Distributed Systems course](http://web.uvic.ca/calendar2012/CDs/CSC/562.html), later refined in a [graduate Design Patterns](http://web.uvic.ca/calendar2012/CDs/CSC/578.html) course. Since then I've used this in commercial projects.

Better documentation will be provided as time allows, for now, here is a brief description of the files in this repository.

# Usage Requirements

This code requires ARC and is known to work with iOS 5.x and later in Xcode 4.5 and later.

## &lt;RCSState&gt; protocol

Represents a state in a FSM.

##RCSTask

Respresents a task that uses a FSM to coordinate itself - consider this an alternative to NSOperation that you can use to model a complex multi-state process.

### RCSTaskState

Implementations of the FSM States for a RCSTask.

##RCSTaskQueue

Represents a queue that undestands the semantics of RCSTasks. Consider this a lightweight alternative to NSOperationQueue.

### RCSTaskQueueState

Implementations of the FSM States for a RCSTaskQueue.
