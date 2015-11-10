// CVSDMFileExportDestination.h
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief a closure which is called when an export is complete. make no assumption about the thread this is performed on.
 */
typedef void (^CVSDMFileExportDestinationExportClosure)(void);

/**
 @protocol defines the interface for a file export destination.
*/
@protocol CVSDMFileExportDestination <NSObject>
@required
/**
 @brief writes the client supplied data to self's destination (file). on completion of the write, your implementation must execute the closure (e.g. using dispatch_async).
 */
- (void)exportDataToDestination:(NSData *)pData closure:(CVSDMFileExportDestinationExportClosure)pClosure;

/**
 @return YES if the export has successfully completed.
 @details an implementation must return NO if -exportDataToDestination:closure: was never called.
 */
- (BOOL)didExportDataToDestination;
@end

/**
 @protocol interface for passing data from the receiver to a CVSDMFileExportDestination via -[<CVSDMFileExportDestination> exportDataToDestination:closure:]
 */
@protocol CVSDMFileExportDestinationDataProvider <NSObject>
@required
/**
 @brief this is the primary entry for a data provider.
 @p pFileExportDestination the export destination. your implementation must provide the requested data to -[<CVSDMFileExportDestination> exportDataToDestination:closure:].
 @p pClosure the closure to pass to the export destination. note that your implementation could wrap this to introduce its own closure, but that a closure will not (necessarily) be executed on any particular thread.
 */
- (void)provideDataToExportDestination:(id<CVSDMFileExportDestination>)pFileExportDestination closure:(CVSDMFileExportDestinationExportClosure)pClosure;
@end
