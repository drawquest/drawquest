// CVSMutableBitmap.m
// DrawQuest
// Created by Justin Carlson on 10/15/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import <QuartzCore/QuartzCore.h>
#import "CVSDrawingModel.h"

@interface CVSDMMutableBitmap () <CVSDMReadWriteLockProvider>

@property (nonatomic, readonly) CVSDMAlignedMemory * pixelBuffer;
@property (nonatomic, readonly) CGContextRef bitmapContext;
@property (nonatomic, readonly) CVSDMReadWriteLock * rwlock;

@end

@implementation CVSDMMutableBitmap

@synthesize pixelBuffer = _pixelBuffer;
@synthesize bitmapContext = _bitmapContext;
@synthesize rwlock = _rwlock;

- (instancetype)initWithBitmapDimensions:(CVSDMBitmapDimensions)pBitmapDimensions
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _rwlock = [CVSDMReadWriteLock new];

    /* @todo JC: use the best bitmap representation */
    const size_t NComponents = 4;
    const size_t bitsPerComponent = CHAR_BIT;
    const size_t bytesPerRow = NComponents * pBitmapDimensions.width;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    const uint32_t bitmapInfo = (uint32_t)kCGImageAlphaPremultipliedLast;

    const size_t bufferSize = NComponents * pBitmapDimensions.width * pBitmapDimensions.height;
    _pixelBuffer = [[CVSDMAlignedMemory alloc] initWithLength:bufferSize hot:YES];
    if (!_pixelBuffer) {
        assert(0 && "failed to create pixel buffer");
        return nil;
    }
    _bitmapContext = CGBitmapContextCreate(_pixelBuffer.mutableBytes, pBitmapDimensions.width, pBitmapDimensions.height, bitsPerComponent, bytesPerRow, space, bitmapInfo);
    CGColorSpaceRelease(space), space = NULL;
    if (NULL == _bitmapContext) {
        return nil;
    }
    return self;
}

- (void)dealloc
{
    CGContextRelease(_bitmapContext), _bitmapContext = NULL;
}

- (id<CVSDMReadWriteLocking>)readWriteLock
{
    return self.rwlock;
}

- (CVSDMBitmapDimensions)bitmapDimensions
{
    CGContextRef gtx = self.context;
    assert(gtx);
    return (CVSDMBitmapDimensions){(uint32_t)CGBitmapContextGetWidth(gtx), (uint32_t)CGBitmapContextGetHeight(gtx)};
}

- (CGRect)boundsAsCGRect
{
    const CVSDMBitmapDimensions dim = self.bitmapDimensions;
    return CGRectMake(0, 0, dim.width, dim.height);
}

- (BOOL)areDimensionsEqualTo:(CVSDMMutableBitmap *)pOther
{
    assert(pOther);
    return CVSDMBitmapDimensionsAreEqual(self.bitmapDimensions, pOther.bitmapDimensions);
}

- (void)clear
{
    // -clearRect: will do the write lock
    [self clearRect:self.boundsAsCGRect];
}

- (void)clearRect:(CGRect)pRect
{
    CVSDMReadWriteLocking_ReadWriteLockProvider_Write(self, ^{
        CGContextClearRect(self.context, pRect);
    });
}

- (CGContextRef)context
{
    assert(_bitmapContext);
    return _bitmapContext;
}

- (void)renderUsingContextRenderBlock:(CVSMutableBitmapCGContextRenderBlock)pContextRenderBlock
{
    CVSDMReadWriteLocking_ReadWriteLockProvider_Write(self, ^{
        CGContextRef context = self.context;
        assert(context);
        CGContextSaveGState(context);
        pContextRenderBlock(self.context);
        CGContextRestoreGState(context);
    });
}

- (void)drawImageInRect:(CGRect)pRect context:(CGContextRef)pContext
{
    CVSDMReadWriteLocking_ReadWriteLockProvider_Read(self, ^{
        CGImageRef image = CGBitmapContextCreateImage(self.context);
        assert(image);
        CGContextDrawImage(pContext, pRect, image);
        CGImageRelease(image);
    });
}

- (void)copyBitmapFrom:(CVSDMMutableBitmap *)pBitmap
{
    assert(pBitmap);
    CVSDMReadWriteLocking_ReadWriteLockProvider_Read(pBitmap, ^{
        CVSDMReadWriteLocking_ReadWriteLockProvider_Write(self, ^{
            [self.pixelBuffer copyMemoryFrom:pBitmap.pixelBuffer];
        });
    });
}

- (void)exportRawBitmapDataToDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure
{
    CVSDMReadWriteLocking_ReadWriteLockProvider_Read(self, ^{
        [self.pixelBuffer exportDataToDestination:pFileExportDestination closure:pClosure];
    });
}

- (void)provideDataToExportDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure
{
    assert(pFileExportDestination);
    assert(pClosure);
    [self exportRawBitmapDataToDestination:pFileExportDestination closure:pClosure];
}

- (void)writeBitmapContents:(CVSDMImmutableDataReference *)pImmutableDataReference
{
    assert(pImmutableDataReference);
    CVSDMReadWriteLocking_ReadWriteLockProvider_Write(self, ^{
        [self.pixelBuffer setMemoryContentsToContentOfImmutableData:pImmutableDataReference];
    });
}

@end
