// Copyright 2015-present 650 Industries. All rights reserved.

#if __has_include(<ABI39_0_0EXFacebook/ABI39_0_0EXFacebook.h>)
#import "ABI39_0_0EXScopedFacebook.h"
#import <FBSDKCoreKit/FBSDKSettings.h>
#import <ABI39_0_0UMCore/ABI39_0_0UMAppLifecycleService.h>
#import <FBSDKCoreKit/FBSDKApplicationDelegate.h>

@interface ABI39_0_0EXFacebook (ExportedMethods)

- (void)initializeAsync:(NSDictionary *)options
               resolver:(ABI39_0_0UMPromiseResolveBlock)resolve
               rejecter:(ABI39_0_0UMPromiseRejectBlock)reject;

- (void)logInWithReadPermissionsWithConfig:(NSDictionary *)config
                                  resolver:(ABI39_0_0UMPromiseResolveBlock)resolve
                                  rejecter:(ABI39_0_0UMPromiseRejectBlock)reject;

- (void)logOutAsync:(ABI39_0_0UMPromiseResolveBlock)resolve
           rejecter:(ABI39_0_0UMPromiseRejectBlock)reject;

- (void)getAuthenticationCredentialAsync:(ABI39_0_0UMPromiseResolveBlock)resolve
                   rejecter:(ABI39_0_0UMPromiseRejectBlock)reject;

- (void)setAutoInitEnabled:(BOOL)enabled
                  resolver:(ABI39_0_0UMPromiseResolveBlock)resolve
                  rejecter:(ABI39_0_0UMPromiseRejectBlock)reject;

@end

static NSString *AUTO_INIT_KEY = @"autoInitEnabled";

@interface ABI39_0_0EXScopedFacebook ()

@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSUserDefaults *settings;

@end

// Expo client-only ABI39_0_0EXFacebook module, which ensures that Facebook SDK configurations
// of different experiences don't collide.

@implementation ABI39_0_0EXScopedFacebook : ABI39_0_0EXFacebook

- (instancetype)initWithExperienceId:(NSString *)experienceId andParams:(NSDictionary *)params
{
  if (self = [super init]) {
    NSString *suiteName = [NSString stringWithFormat:@"%@#%@", NSStringFromClass(self.class), experienceId];
    _settings = [[NSUserDefaults alloc] initWithSuiteName:suiteName];

    BOOL hasPreviouslySetAutoInitEnabled = [_settings boolForKey:AUTO_INIT_KEY];
    BOOL manifestDefinesAutoInitEnabled = [params[@"manifest"][@"facebookAutoInitEnabled"] boolValue];
    
    NSString *scopedFacebookAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
    NSString *manifestFacebookAppId = params[@"manifest"][@"facebookAppId"];

    if (hasPreviouslySetAutoInitEnabled || manifestDefinesAutoInitEnabled) {
      // This happens even before the app foregrounds, which mimics
      // the mechanism behind ABI39_0_0EXFacebookAppDelegate.
      // Check for FacebookAppId in case this is a custom client build
      if (scopedFacebookAppId) {
        [FBSDKApplicationDelegate initializeSDK:nil];
        _isInitialized = YES;
        if (manifestFacebookAppId) {
          ABI39_0_0UMLogInfo(@"Overriding Facebook App ID with Expo Go. To test your own Facebook App ID, you'll need to build a standalone app. Refer to our documentation for more info- https://docs.expo.io/versions/latest/sdk/facebook/");
        }
      } else {
        ABI39_0_0UMLogWarn(@"FacebookAutoInit is enabled, but no FacebookAppId has been provided. Facebook SDK initialization aborted.");
      }
    }
  }
  return self;
}

- (void)initializeAsync:(NSDictionary *)options
               resolver:(ABI39_0_0UMPromiseResolveBlock)resolve
               rejecter:(ABI39_0_0UMPromiseRejectBlock)reject
{
  _isInitialized = YES;
  if (options[@"appId"]) {
    ABI39_0_0UMLogInfo(@"Overriding Facebook App ID with Expo Go. To test your own Facebook App ID, you'll need to build a standalone app. Refer to our documentation for more info- https://docs.expo.io/versions/latest/sdk/facebook/");
  }

  NSString *scopedFacebookAppId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
  
  NSMutableDictionary *nativeOptions = [NSMutableDictionary dictionaryWithDictionary:options];
  // Overwrite the incoming app id with the Expo Facebook SDK app id.
  nativeOptions[@"appId"] = scopedFacebookAppId;
  
  [super initializeAsync:nativeOptions resolver:resolve rejecter:reject];
}

- (void)setAutoInitEnabled:(BOOL)enabled resolver:(ABI39_0_0UMPromiseResolveBlock)resolve rejecter:(ABI39_0_0UMPromiseRejectBlock)reject
{
  if (enabled) {
    [_settings setBool:enabled forKey:AUTO_INIT_KEY];
    // Facebook SDK on iOS is initialized when `setAutoInitEnabled` is called with `YES`.
    _isInitialized = YES;
  }
  [super setAutoInitEnabled:enabled resolver:resolve rejecter:reject];
}

- (void)logInWithReadPermissionsWithConfig:(NSDictionary *)config resolver:(ABI39_0_0UMPromiseResolveBlock)resolve rejecter:(ABI39_0_0UMPromiseRejectBlock)reject
{
  // If the developer didn't initialize the SDK, let them know.
  if (!_isInitialized) {
    reject(@"ERR_FACEBOOK_UNINITIALIZED", @"Facebook SDK has not been initialized yet.", nil);
    return;
  }
  [super logInWithReadPermissionsWithConfig:config resolver:resolve rejecter:reject];
}

- (void)getAuthenticationCredentialAsync:(ABI39_0_0UMPromiseResolveBlock)resolve rejecter:(ABI39_0_0UMPromiseRejectBlock)reject
{
  // If the developer didn't initialize the SDK, let them know.
  if (!_isInitialized) {
    reject(@"ERR_FACEBOOK_UNINITIALIZED", @"Facebook SDK has not been initialized yet.", nil);
    return;
  }
  [super getAuthenticationCredentialAsync:resolve rejecter:reject];
}

- (void)logOutAsync:(ABI39_0_0UMPromiseResolveBlock)resolve rejecter:(ABI39_0_0UMPromiseRejectBlock)reject
{
  // If the developer didn't initialize the SDK, let them know.
  if (!_isInitialized) {
    reject(@"ERR_FACEBOOK_UNINITIALIZED", @"Facebook SDK has not been initialized yet.", nil);
    return;
  }
  [super logOutAsync:resolve rejecter:reject];
}

# pragma mark - ABI39_0_0UMModuleRegistryConsumer

- (void)setModuleRegistry:(ABI39_0_0UMModuleRegistry *)moduleRegistry
{
  id<ABI39_0_0UMAppLifecycleService> appLifecycleService = [moduleRegistry getModuleImplementingProtocol:@protocol(ABI39_0_0UMAppLifecycleService)];
  [appLifecycleService registerAppLifecycleListener:self];
}

# pragma mark - ABI39_0_0UMAppLifecycleListener

- (void)onAppBackgrounded {
  // Save SDK settings state
  _appId = [FBSDKSettings appID];
  _displayName = [FBSDKSettings displayName];
  [FBSDKSettings setAppID:nil];
  [FBSDKSettings setDisplayName:nil];
}

- (void)onAppForegrounded {
  // Restore SDK settings state
  if (_appId) {
    [FBSDKSettings setAppID:_appId];
  }
  if (_displayName) {
    [FBSDKSettings setDisplayName:_displayName];
  }
}

@end
#endif
