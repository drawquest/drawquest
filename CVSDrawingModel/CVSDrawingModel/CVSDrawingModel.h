// CVSDrawingModel.h
// CVSDrawingModel
// Created by justin carlson on 10/17/13.
// Copyright (c) 2013 Canvas. All rights reserved.

// master library import header for libCVSDrawingModel
// library prefix: CVSDM
// notes: this library already needs to be divided

// external dependencies
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

// dependencies from the original app which have not yet been relocated
#import "../../Editor/CVSDrawingTypes.h"

// fwd
#import "CVSDrawingModel.fwd.h"

// library
#import "CVSDMBitmapDimensions.h"

// filesystem/resources
#import "CVSDMImmutableDataReference.h"
#import "CVSDMTemporaryResourceRemovalOption.h"
#import "CVSDMTemporaryFileSystemResource.h"
#import "CVSDMFileExportDestination.h"
#import "CVSDMTemporaryFile.h"
#import "CVSDMTemporaryDirectory.h"
#import "CVSDMFileSystemIOQueue.h"

// snapshotting
#import "CVSDMImageSnapshotQueue.h"

// memory
#import "CVSDMAlignedMemory.h"

// synchronization
#import "CVSDMLockingBlock.h"
#import "CVSDMReadWriteLocking.h"
#import "CVSDMReadWriteLock.h"

// bitmaps
#import "CVSDMMutableBitmap.h"
#import "CVSDMEditorBitmapStore.h"
#import "CVSDMEditorBitmapStoreReference.h"
