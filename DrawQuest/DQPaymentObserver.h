//
//  DQPaymentObserver.h
//  DrawQuest
//
//  Created by David Mauro on 8/8/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQController.h"
#import <StoreKit/StoreKit.h>

extern NSString *DQPaymentObserverDidCancelTransaction;
extern NSString *DQPaymentObserverDidUpdateTransaction;
extern NSString *DQPaymentObserverFailedToUpdateTransaction;
extern NSString *DQPaymentObserverDidRestoreTransactions;
extern NSString *DQPaymentObserverFailedToRestoreTransactions;
extern NSString *DQPaymentObserverErrorDomain;
extern NSString *DQPaymentObserverTransactionKeyString;
extern NSString *DQPaymentObserverResponseDictionaryKeyString;
extern NSString *DQPaymentObserverErrorKeyString;
extern NSString *DQPaymentObserverWillRetryKeyString;
extern NSInteger DQPaymentObserverUnknownError;
extern NSInteger DQPaymentObserverProcessReceiptError;
extern NSInteger DQPaymentObserverStoreKitTransactionError;

@interface DQPaymentObserver : DQController <SKPaymentTransactionObserver>

- (void)runPendingTransactions;

@end
