//
//  DQAppDelegate.m
//  DrawQuest
//
//  Created by Buzz Andersen on 9/11/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQAppDelegate.h"
#import "DQPadApplicationController.h"
#import "DQPhoneApplicationController.h"

@interface DQAppDelegate()

// NOTE: This object is intentionally private. Do not expose this object to other
// objects. It may know about other objects but nothing should need to know about
// it directly. It can be the delegate of other objects, adopting their protocols,
// and/or set blocks on other objects, however.
@property (nonatomic, strong) DQApplicationController *applicationController;

@end

@implementation DQAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.applicationController = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [[DQPadApplicationController alloc] init] : [[DQPhoneApplicationController alloc] init];
    return [self.applicationController finishLaunchingWithOptions:launchOptions forApplication:application];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self.applicationController openURL:url sourceApplication:sourceApplication annotation:annotation forApplication:application];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.applicationController resignActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.applicationController background:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.applicationController foreground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.applicationController becomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.applicationController terminate:application];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self.applicationController registerRemoteNotificationsWithDeviceToken:deviceToken forApplication:application];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self.applicationController failedToRegisterForRemoteNotificationsWithError:error forApplication:application];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self.applicationController receiveRemoteNotification:userInfo forApplication:application];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [self.applicationController receiveLocalNotification:notification.userInfo forApplication:application];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return UIInterfaceOrientationMaskLandscape;
    }
    else
    {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}

@end
