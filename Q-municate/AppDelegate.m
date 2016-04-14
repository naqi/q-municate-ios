//
//  AppDelegate.m
//  Q-municate
//
//  Created by Igor Alefirenko on 13/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "REAlertView+QMSuccess.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "QMChatVC.h"
#import "QMCore.h"
#import "QMProfile.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <DigitsKit/DigitsKit.h>
#import <Flurry.h>


#define DEVELOPMENT 1

#if DEVELOPMENT == 0

// Production
const NSUInteger kQMApplicationID = 13318;
NSString *const kQMAuthorizationKey = @"WzrAY7vrGmbgFfP";
NSString *const kQMAuthorizationSecret = @"xS2uerEveGHmEun";
NSString *const kQMAccountKey = @"6Qyiz3pZfNsex1Enqnp7";

#else

// Development
const NSUInteger kQMApplicationID = 39101;
NSString *const kQMAuthorizationKey = @"G2Pkf6Wt5yPrBKj";
NSString *const kQMAuthorizationSecret = @"RGvyjRBm2EYWJbf";
NSString *const kQMAccountKey = @"p5yc9gsgyw99i5ExXxZ3";

#endif

@interface AppDelegate () <QMNotificationHandlerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIApplication.sharedApplication.applicationIconBadgeNumber = 0;
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    // QB Settings
    [QBSettings setApplicationID:kQMApplicationID];
    [QBSettings setAuthKey:kQMAuthorizationKey];
    [QBSettings setAuthSecret:kQMAuthorizationSecret];
    [QBSettings setAccountKey:kQMAccountKey];
    [QBSettings setChatDNSLookupCacheEnabled:YES];
    [QBSettings setAutoReconnectEnabled:YES];
    
#if DEVELOPMENT == 0
    [QBSettings setLogLevel:QBLogLevelNothing];
    [QBSettings disableXMPPLogging];
#else
    [QBSettings setLogLevel:QBLogLevelDebug];
    [QBSettings enableXMPPLogging];
#endif
    
    //QuickbloxWebRTC preferences
    [QBRTCClient initializeRTC];
    [QBRTCConfig setICEServers:[self quickbloxICE]];
    [QBRTCConfig mediaStreamConfiguration].audioCodec = QBRTCAudioCodecISAC;
    [QBRTCConfig setStatsReportTimeInterval:0.0f]; // set to 1.0f to enable stats report
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
    
    /*Configure app appearance*/
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:13.0f/255.0f green:112.0f/255.0f blue:179.0f/255.0f alpha:1.0f]];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil] setTitleTextAttributes:nil forState:UIControlStateNormal];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil] setTitleTextAttributes:nil forState:UIControlStateDisabled];
    
    /** extra frameworks */
    [Fabric with:@[CrashlyticsKit, DigitsKit]];
    [Flurry startSession:@"P8NWM9PBFCK2CWC8KZ59"];
    
    if (launchOptions != nil) {
        NSDictionary *notification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
//        [[QMApi instance] setPushNotification:notification];
    }

    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    if ([application applicationState] == UIApplicationStateInactive) {
//        NSString *dialogID = userInfo[kPushNotificationDialogIDKey];
//        if (dialogID != nil) {
//            NSString *dialogWithIDWasEntered = [QMApi instance].settingsManager.dialogWithIDisActive;
//            if ([dialogWithIDWasEntered isEqualToString:dialogID]) return;
//            
//            [[QMApi instance] setPushNotification:userInfo];
//            
//            // calling dispatch async for push notification handling to have priority in main queue
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[QMApi instance] handlePushNotificationWithDelegate:self];
//            });
//        }
//        ILog(@"Push was received. User info: %@", userInfo);
//    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    UIApplication.sharedApplication.applicationIconBadgeNumber = 0;
    [[QMCore instance] disconnectFromChatIfNeeded];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    if ([QMCore instance].currentProfile.userData) {
        
#warning TODO: login to chat and fetch dialogs
        [[QMCore instance].chatService connect];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    [FBSDKAppEvents activateApp];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    BOOL urlWasIntendedForFacebook = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                                    openURL:url
                                                                          sourceApplication:sourceApplication
                                                                                 annotation:annotation
                                      ];
    return urlWasIntendedForFacebook;
}


#pragma mark - PUSH NOTIFICATIONS REGISTRATION

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
//    if (deviceToken) {
//        [[QMApi instance] setDeviceToken:deviceToken];
//    }
}

#pragma mark - QMNotificationHandlerDelegate protocol

- (void)notificationHandlerDidSucceedFetchingDialog:(QBChatDialog *)chatDialog {
//    UITabBarController *rootController = [(UITabBarController *)self.window.rootViewController selectedViewController];
//    UINavigationController *navigationController = (UINavigationController *)rootController;
//    
//    UIViewController *chatVC = [QMChatVC chatViewControllerWithChatDialog:chatDialog];
//    
//    NSString *dialogWithIDWasEntered = [QMApi instance].settingsManager.dialogWithIDisActive;
//    if (dialogWithIDWasEntered != nil) {
//        // some chat already opened, return to dialogs view controller first
//        [navigationController popViewControllerAnimated:NO];
//    }
//    
//    [navigationController pushViewController:chatVC animated:YES];
}

#pragma mark - ICE servers

- (NSArray *)quickbloxICE {
    
    NSString *password = @"baccb97ba2d92d71e26eb9886da5f1e0";
    NSString *userName = @"quickblox";
    
    NSArray *urls = @[
                      @"turn.quickblox.com",            //USA
                      @"turnsingapore.quickblox.com",   //Singapore
                      @"turnireland.quickblox.com"      //Ireland
                      ];
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:urls.count];
    
    for (NSString *url in urls) {
        
        QBRTCICEServer *stunServer = [QBRTCICEServer serverWithURL:[NSString stringWithFormat:@"stun:%@", url]
                                                          username:@""
                                                          password:@""];
        
        
        QBRTCICEServer *turnUDPServer = [QBRTCICEServer serverWithURL:[NSString stringWithFormat:@"turn:%@:3478?transport=udp", url]
                                                             username:userName
                                                             password:password];
        
        QBRTCICEServer *turnTCPServer = [QBRTCICEServer serverWithURL:[NSString stringWithFormat:@"turn:%@:3478?transport=tcp", url]
                                                             username:userName
                                                             password:password];
        
        [result addObjectsFromArray:@[stunServer, turnTCPServer, turnUDPServer]];
    }
    
    return result;
}

@end
