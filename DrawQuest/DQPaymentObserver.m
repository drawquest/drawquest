//
//  DQPaymentObserver.m
//  DrawQuest
//
//  Created by David Mauro on 8/8/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQPaymentObserver.h"
#import "DQPrivateServiceController.h"
#import "DQAnalyticsConstants.h"
#import "DQAlertView.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "RCSAsyncOperation.h"
#import "RCSArrayIteration.h"
#import "RCSArrayIterationContext.h"
#import "DQPapertrailLogger.h"

NSString *DQPaymentObserverDidCancelTransaction = @"DQPaymentObserverDidCancelTransaction";
NSString *DQPaymentObserverDidUpdateTransaction = @"DQPaymentObserverDidUpdateTransaction";
NSString *DQPaymentObserverFailedToUpdateTransaction = @"DQPaymentObserverFailedToUpdateTransaction";
NSString *DQPaymentObserverDidRestoreTransactions = @"DDQPaymentObserverDidRestoreTransactions";
NSString *DQPaymentObserverFailedToRestoreTransactions = @"DQPaymentObserverFailedToRestoreTransactions";

NSString *DQPaymentObserverErrorDomain = @"DQPaymentObserverErrorDomain";
NSString *DQPaymentObserverTransactionKeyString = @"transaction";
NSString *DQPaymentObserverResponseDictionaryKeyString = @"response_dictionary";
NSString *DQPaymentObserverErrorKeyString = @"error";
NSString *DQPaymentObserverWillRetryKeyString = @"will_retry";
NSInteger DQPaymentObserverUnknownError = 1000;
NSInteger DQPaymentObserverProcessReceiptError = 1001;
NSInteger DQPaymentObserverStoreKitTransactionError = 1002;

@interface DQPaymentObserver ()

@property (nonatomic, strong, readonly) dispatch_queue_t workerQueue;
@property (nonatomic, strong) NSOperationQueue *serialOperationQueue;
@property (nonatomic, strong) NSArray *finishedTransactions;

@end

@implementation DQPaymentObserver

- (void)dealloc
{
    if (_workerQueue)
    {
        dispatch_sync(_workerQueue, ^{ });
    }
}

- (id)initWithDelegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _workerQueue = dispatch_queue_create("as.canv.drawquest.paymentobserver", DISPATCH_QUEUE_SERIAL);
        _serialOperationQueue = [[NSOperationQueue alloc] init];
        _serialOperationQueue.maxConcurrentOperationCount = 1;
        _finishedTransactions = @[];
    }
    return self;
}

- (void)runPendingTransactions
{
    NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
    if ([transactions count])
    {
        [self paymentQueue:[SKPaymentQueue defaultQueue] updatedTransactions:transactions];
    }
}

- (BOOL)finishTransaction:(SKPaymentTransaction *)transaction inQueue:(SKPaymentQueue *)queue
{
    BOOL result = NO;
    if ( ! [self.finishedTransactions containsObject:transaction.transactionIdentifier])
    {
        [queue finishTransaction:transaction];
        self.finishedTransactions = [self.finishedTransactions arrayByAddingObject:transaction.transactionIdentifier];
        result = YES;
    }
    return result;
}

- (void)processReceiptInPaymentQueue:(SKPaymentQueue *)queue forTransaction:(SKPaymentTransaction *)transaction successBlock:(void(^)(id JSONObject))successBlock failureBlock:(void(^)(NSError *error))failureBlock receiptInvalidBlock:(void(^)(NSError *error))receiptInvalidBlock
{
    // FIXME: See DQ-865
    [self.privateServiceController requestProcessPurchaseReceiptWithData:transaction.transactionReceipt completionBlock:^(DQHTTPRequest *request, id JSONObject) {
        if (request.error)
        {
            if (request.error.code == DQAPIErrorCodeValidationFailure)
            {
                if (receiptInvalidBlock)
                {
                    receiptInvalidBlock(request.error);
                }
            }
            else
            {
                if (failureBlock)
                {
                    failureBlock(request.error);
                }
            }
        }
        else
        {
            if (JSONObject)
            {
                if (successBlock)
                {
                    successBlock(JSONObject);
                }
            }
            else
            {
                if (failureBlock)
                {
                    NSDictionary *userInfo = @{DQPaymentObserverTransactionKeyString: transaction};
                    NSError *error = [NSError errorWithDomain:DQPaymentObserverErrorDomain code:DQPaymentObserverUnknownError userInfo:userInfo];
                    failureBlock(error);
                }
            }
        }
    }];
}

#pragma mark - SKPaymentTransaction Completion Methods

- (void)postNotificationForSuccessfulTransaction:(SKPaymentTransaction *)transaction responseDictionary:(NSDictionary *)responseDictionary
{
    NSDictionary *userInfo = @{DQPaymentObserverTransactionKeyString: transaction, DQPaymentObserverResponseDictionaryKeyString: responseDictionary};
    [[NSNotificationCenter defaultCenter] postNotificationName:DQPaymentObserverDidUpdateTransaction object:nil userInfo:userInfo];
}

- (void)postNotificationForCancelledTransaction:(SKPaymentTransaction *)transaction
{
    NSDictionary *userInfo = @{DQPaymentObserverTransactionKeyString: transaction};
    [[NSNotificationCenter defaultCenter] postNotificationName:DQPaymentObserverDidCancelTransaction object:nil userInfo:userInfo];
}

- (void)postNotificationForFailedTransaction:(SKPaymentTransaction *)transaction error:(NSError *)error
{
    NSDictionary *userInfo = nil;
    if (error)
    {
        userInfo = @{DQPaymentObserverTransactionKeyString: transaction, DQPaymentObserverErrorKeyString: error};
    }
    else
    {
        userInfo = @{DQPaymentObserverTransactionKeyString: transaction};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:DQPaymentObserverFailedToUpdateTransaction object:nil userInfo:userInfo];
}

#pragma mark - SKPaymentTransactionObserver Delegate Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    dispatch_async(self.workerQueue, ^{
        __weak typeof(self) weakSelf = self;
        RCSAsyncOperation *op = [[RCSAsyncOperation alloc] initWithExecutionBlock:^(RCSAsyncOperation *operation) {
            RCSArrayIteration *iter = [[RCSArrayIteration alloc] initWithObjects:transactions toQueue:weakSelf.workerQueue];

            __weak typeof(self) weakSelf = self;
            [iter eachObject:^(SKPaymentTransaction *transaction, RCSArrayIterationContext *context) {
                if (transaction.transactionState == SKPaymentTransactionStatePurchased)
                {
                    // The transaction has been paid for
                    [weakSelf processReceiptInPaymentQueue:queue forTransaction:transaction successBlock:^(id JSONObject) {
                        if ([weakSelf finishTransaction:transaction inQueue:queue])
                        {
                            [weakSelf postNotificationForSuccessfulTransaction:transaction responseDictionary:JSONObject];
                        }
                        [context next];
                    } failureBlock:^(NSError *error) {
                        // We took their money, but the server request failed!
                        // Do not finish the transaction so that we'll call it again later
                        NSDictionary *userInfo = error ? @{NSUnderlyingErrorKey: error, NSLocalizedDescriptionKey: error.dq_displayDescription, DQPaymentObserverWillRetryKeyString: @YES} : nil;
                        NSError *wrappedError = [NSError errorWithDomain:DQPaymentObserverErrorDomain code:DQPaymentObserverProcessReceiptError userInfo:userInfo];
                        [weakSelf postNotificationForFailedTransaction:transaction error:wrappedError];
                        [context next];
                    } receiptInvalidBlock:^(NSError *error) {
                        if ([weakSelf finishTransaction:transaction inQueue:queue])
                        {
                            NSDictionary *userInfo = error ? @{NSUnderlyingErrorKey: error, NSLocalizedDescriptionKey: error.dq_displayDescription, DQPaymentObserverWillRetryKeyString: @NO} : nil;
                            NSError *wrappedError = [NSError errorWithDomain:DQPaymentObserverErrorDomain code:DQPaymentObserverProcessReceiptError userInfo:userInfo];
                            [weakSelf postNotificationForFailedTransaction:transaction error:wrappedError];
                        }
                        [context next];
                    }];
                }
                else if (transaction.transactionState == SKPaymentTransactionStateRestored)
                {
                    // The transaction has been restored as already purchased
                    if ([weakSelf finishTransaction:transaction inQueue:queue])
                    {
                        [weakSelf postNotificationForSuccessfulTransaction:transaction responseDictionary:@{}];
                    }
                    [context next];
                }
                else if (transaction.transactionState == SKPaymentTransactionStateFailed)
                {
                    // The transaction failed as SKPaymentTransactionStateFailed
                    if ([weakSelf finishTransaction:transaction inQueue:queue])
                    {
                        if (transaction.error.code == SKErrorPaymentCancelled)
                        {
                            [weakSelf postNotificationForCancelledTransaction:transaction];
                        }
                        else
                        {
                            // Alert the user the app store purchase failed (talking to Apple)
                            NSDictionary *userInfo = transaction.error ? @{NSUnderlyingErrorKey:transaction.error, NSLocalizedDescriptionKey:transaction.error.dq_displayDescription, DQPaymentObserverWillRetryKeyString: @NO} : nil;
                            NSError *error = [NSError errorWithDomain:DQPaymentObserverErrorDomain code:DQPaymentObserverStoreKitTransactionError userInfo:userInfo];
                            [weakSelf postNotificationForFailedTransaction:transaction error:error];
                        }
                    }
                    [context next];
                }
                else
                {
                    [context next];
                }
            } done:^(RCSArrayIterationContext *context) {
                [operation done];
            } failed:^(NSError *error, RCSArrayIterationContext *context) {
                [DQPapertrailLogger component:@"payment-observer" category:@"payment-queue-iteration-fail" error:error dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{};
                }];
                [operation done];
            }];
        } onQueue:weakSelf.workerQueue];
        [self.serialOperationQueue addOperation:op];
    });
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self runPendingTransactions];
    [[NSNotificationCenter defaultCenter] postNotificationName:DQPaymentObserverDidRestoreTransactions object:self userInfo:@{}];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DQPaymentObserverFailedToRestoreTransactions object:self userInfo:@{NSUnderlyingErrorKey: error}];
}

@end
