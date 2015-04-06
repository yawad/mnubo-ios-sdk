//
//  mnubo.m
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "mnubo.h"
#import "NSString+mnubo.h"
#import "MBOBasicHttpClient.h"
#import "MBOUser+Private.h"
#import "MBOError+Private.h"
#import "MBOObject+Private.h"
#import "NSDictionary+mnubo.h"
#import "MBODateHelper.h"
#import "MBOSensorDataQueue.h"
#import "Reachability.h"
#import "PDKeychainBindings.h"
#import "MBOMacros.h"

NSString * const kMnuboClientAccessTokenKey = @"com.mnubo.sdk.client_access_token";
NSString * const kMnuboClientExpiresInKey = @"com.mnubo.sdk.client_expires_in";
NSString * const kMnuboClientTokenTimestampKey = @"com.mnubo.sdk.client_token_timestamp";

NSString * const kMnuboUserAccessTokenKey = @"com.mnubo.sdk.user_access_token";
NSString * const kMnuboUserRefreshTokenKey = @"com.mnubo.sdk.user_refresh_token";
NSString * const kMnuboUserExpiresInKey = @"com.mnubo.sdk.user_expires_in";
NSString * const kMnuboUserTokenTimestampKey = @"com.mnubo.sdk.user_token_timestamp";

/// Tokens
NSString * const kMnuboGetTokenPath = @"/oauth/token";
NSString * const kMnuboResetPasswordPath = @"/api/v2/users/%@/password";
NSString * const kMnuboConfirmEmailPath= @"/api/v2/users/%@/confirmation";

/// Users
NSString * const kMnuboCreateUserPath = @"/api/v2/users";
NSString * const kMnuboUpdateUserPath = @"/api/v2/users/%@";
NSString * const kMnuboDeleteUserPath = @"/api/v2/users/%@";
NSString * const kMnuboGetUserPath = @"/api/v2/users/%@";


/// Objects
NSString * const kMnuboCreateObjectPath = @"/api/v2/objects";
NSString * const kMnuboGetObjectPath = @"/api/v2/objects/%@";
NSString * const kMnuboUpdateObjectPath = @"/api/v2/objects/%@";
NSString * const kMnuboDeleteObjectPath = @"/api/v2/objects/%@";


/// Sensor Data
NSString * const kMnuboPostSensorDataPath = @"/api/v2/objects/%@/samples";
NSString * const kMnuboPostPublicSensorDataPath = @"/api/v2/objects/%@/sensors/%@/samples";
NSString * const kMnuboGetSensorDataPath = @"/api/v2/objects/%@/sensors/%@/samples";



@interface mnubo()
{
    id<MBOHttpClient> _httpClient;
    MBOSensorDataQueue *_sensorDataQueue;

    NSString *_clientId;
    NSString *_baseURL;

    /// Tokens
    NSString *_clientAccessToken;
    NSNumber *_clientExpiresIn;
    NSDate *_clientTokenTimestamp;
    
    NSString *_userAccessToken;
    NSString *_userRefreshToken;
    NSNumber *_userExpiresIn;
    NSDate *_userTokenTimestamp;

    /// Authentication
    NSString *_clientCredentialsTokenBasicAuthentication;


    NSString *_accountName;
}

@end

@implementation mnubo

static mnubo *_sharedInstance = nil;
static BOOL loggingEnabled = NO;

+ (mnubo *)sharedInstanceWithClientId:(NSString *)clientId clientSecret:(NSString *)clientSecret hostname:(NSString *)hostname
{
    
    static dispatch_once_t unique = 0;
    
    dispatch_once(&unique, ^{
        _sharedInstance = [[self alloc] initWithClientId:clientId clientSecret:clientSecret hostname:hostname];
    });
    
    return _sharedInstance;
}

+ (mnubo *)sharedInstance
{
    return _sharedInstance;
}

- (instancetype)initWithClientId:(NSString *)clientId
                       clientSecret:(NSString *)clientSecret
                           hostname:(NSString *)hostname

{
    self = [super init];
    if(self)
    {
        _sensorDataRetryInterval = 30;
        _disableSensorDataInternalRetry = NO;
        
        _sensorDataQueue = [[MBOSensorDataQueue alloc] initWithRetryInterval:_sensorDataRetryInterval mnuboSDK:self];

        _httpClient = [[MBOBasicHttpClient alloc] init];

        _clientId = clientId;

        _clientCredentialsTokenBasicAuthentication = [[NSString stringWithFormat:@"%@:%@", clientId, clientSecret] base64Encode];

        _baseURL = hostname;

        [self loadTokens];
        
        [self getClientAccessTokenCompletion:^(MBOError *error) {
            if (!error)
            {
                MBOLog(@"Client access token successfully fetched during SDK initialization");
            }
            else
            {
                MBOLog(@"ERROR while fetching the client access token during SDK initialization");
            }
        }];
    }

    return self;
}

+ (void)enableLogging
{
    loggingEnabled = YES;
}

+ (void)disableLogging
{
    loggingEnabled = NO;
}

+ (BOOL)isLoggingEnabled
{
    return loggingEnabled;
}

- (void)setSensorDataRetryInterval:(NSTimeInterval)sensorDataRetryInterval
{
    if(_sensorDataRetryInterval == sensorDataRetryInterval) return;
    
    _sensorDataRetryInterval = sensorDataRetryInterval;
    
    [_sensorDataQueue setRetryInterval:_sensorDataRetryInterval];
}

- (void)loadTokens
{
    _userAccessToken = [[PDKeychainBindings sharedKeychainBindings] stringForKey:kMnuboUserAccessTokenKey];
    _userRefreshToken = [[PDKeychainBindings sharedKeychainBindings] stringForKey:kMnuboUserRefreshTokenKey];
    _userExpiresIn = [[NSUserDefaults standardUserDefaults] objectForKey:kMnuboUserExpiresInKey];
    _userTokenTimestamp = [[NSUserDefaults standardUserDefaults] objectForKey:kMnuboUserTokenTimestampKey];
}

- (void)saveTokens
{
    
    [[PDKeychainBindings sharedKeychainBindings] setString:_userAccessToken forKey:kMnuboUserAccessTokenKey];
    [[PDKeychainBindings sharedKeychainBindings] setString:_userRefreshToken forKey:kMnuboUserRefreshTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:_userExpiresIn forKey:kMnuboUserExpiresInKey];
    [[NSUserDefaults standardUserDefaults] setObject:_userTokenTimestamp forKey:kMnuboUserTokenTimestampKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//------------------------------------------------------------------------------
#pragma mark User management
//------------------------------------------------------------------------------

- (void)createUser:(MBOUser *)user updateIfAlreadyExist:(BOOL)updateIfAlreadyExist completion:(void (^)(MBOError *error))completion
{
    [self createUser:user updateIfAlreadyExist:updateIfAlreadyExist allowRefreshToken:YES completion:completion];
}

- (void)createUser:(MBOUser *)user updateIfAlreadyExist:(BOOL)updateIfAlreadyExist allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOError *error))completion
{
    if (!user)
    {
        if(completion) completion([MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidParameter userInfo:nil]);
        return;
    }
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _clientAccessToken] };
    NSDictionary *parameters = @{@"updateifexists" : updateIfAlreadyExist ? @"1" : @"0"};

    __weak mnubo *weakSelf = self;
    [_httpClient POST:[_baseURL stringByAppendingPathComponent:kMnuboCreateUserPath] headers:headers parameters:parameters data:[user toDictionary] completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
    {
        if(!error)
        {
            if(completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf getClientAccessTokenCompletion:^(MBOError *error)
            {
                if(!error)
                {
                    [weakSelf createUser:user updateIfAlreadyExist:updateIfAlreadyExist allowRefreshToken:NO completion:completion];
                }
                else
                {
                    if(completion) completion(error);
                }
            }];
        }
        else
        {
            if(completion) completion([MBOError errorWithError:error extraInfo:data]);
        }
    }];
}

- (void)updateUser:(MBOUser *)user completion:(void (^)(MBOError *error))completion
{
    [self updateUser:user allowRefreshToken:YES completion:completion];
}

- (void)updateUser:(MBOUser *)user allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOError *error))completion
{
    if(user.username.length == 0)
    {
        if(completion) completion([MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidParameter userInfo:nil]);
        return;
    }

    NSString *getUsernamePath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboUpdateUserPath, [user.username urlEncode]]];
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };

    __weak mnubo *weakSelf = self;
    [_httpClient PUT:getUsernamePath headers:headers parameters:nil data:[user toDictionary] completion:^(id data, NSError *error)
    {
        if(!error)
        {
            if(completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf getClientAccessTokenCompletion:^(MBOError *error)
            {
                if(!error)
                {
                    [weakSelf updateUser:user allowRefreshToken:NO completion:completion];
                }
                else
                {
                    if(completion) completion(error);
                }
            }];
        }
        else
        {
            if(completion) completion([MBOError errorWithError:error extraInfo:data]);
        }
    }];
}

- (void)getUserWithUsername:(NSString *)username completion:(void (^)(MBOUser *user, MBOError *error))completion
{
    [self getUserWithUsername:username allowRefreshToken:YES completion:completion];
}

- (void)getUserWithUsername:(NSString *)username allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOUser *user, MBOError *error))completion
{
    NSString *getUsernamePath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboGetUserPath, [username urlEncode]]];
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    
    __weak mnubo *weakSelf = self;
    [_httpClient GET:getUsernamePath headers:headers parameters:nil completion:^(id data, NSError *error)
     {
         if(!error)
         {
             if([data isKindOfClass:[NSDictionary class]])
             {
                 if(completion) completion([[MBOUser alloc] initWithDictionary:data], nil);
             }
             else
             {
                 if(completion) completion(nil, [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidDataReceived userInfo:nil]);
             }
         }
         else if(error.code == 401 && allowRefreshToken)
         {
             [weakSelf getClientAccessTokenCompletion:^(MBOError *error)
              {
                  if(!error)
                  {
                      [weakSelf getUserWithUsername:username allowRefreshToken:NO completion:completion];
                  }
                  else
                  {
                      if(completion) completion(nil, error);
                  }
              }];
         }
         else
         {
             if(completion) completion(nil, [MBOError errorWithError:error extraInfo:data]);
         }
     }];
}

- (void)deleteUserWithUsername:(NSString *)username completion:(void (^)(MBOError *error))completion
{
    [self deleteUserWithUsername:username allowRefreshToken:YES completion:completion];
}

- (void)deleteUserWithUsername:(NSString *)username allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOError *error))completion
{
    NSString *deleteUserPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboDeleteUserPath, [username urlEncode]]];
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };

    __weak mnubo *weakSelf = self;
    [_httpClient DELETE:deleteUserPath headers:headers parameters:nil completion:^(id data, NSError *error)
    {
        if(!error)
        {
            if(completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf getClientAccessTokenCompletion:^(MBOError *error)
            {
                if(!error)
                {
                    [weakSelf deleteUserWithUsername:username allowRefreshToken:NO completion:completion];
                }
                else
                {
                    if(completion) completion(error);
                }
            }];
        }
        else
        {
            if(completion) completion([MBOError errorWithError:error extraInfo:data]);
        }
    }];
}

- (void)getObjectsOfUsername:(NSString *)username completion:(void (^) (NSArray *objects, NSError *error))completion
{
    [self getObjectsOfUsername:username allowRefreshToken:YES completion:completion];
}


- (void)getObjectsOfUsername:(NSString *)username allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^) (NSArray *objects, MBOError *error))completion
{
    
    NSString *getObjectsOfUserPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:@"/api/v2/users/%@/objects", [username urlEncode]]];
    
    MBOLog(@"Get user's objects with path : %@", getObjectsOfUserPath);
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    
    __weak mnubo *weakSelf = self;
    [_httpClient GET:getObjectsOfUserPath headers:headers parameters:nil completion:^(id data, NSError *error) {
        if (!error)
        {
            if ([data isKindOfClass:[NSDictionary class]])
            {
                NSArray *objectData = [data objectForKey:@"objects"];
                NSMutableArray *objects = [[NSMutableArray alloc] init];
                for (int i=0; i<objectData.count; i++) {
                    MBOObject *newObject = [[MBOObject alloc] initWithDictionary:[objectData objectAtIndex:i]];
                    newObject.ownerUsername = username;
                    [objects addObject:newObject];
                }
                if (completion) completion(objects, nil);
                
            }
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf getClientAccessTokenCompletion:^(MBOError *error)
             {
                 if(!error)
                 {
                     [weakSelf getObjectsOfUsername:username allowRefreshToken:NO completion:completion];
                 }
                 else
                 {
                     if(completion) completion(nil, error);
                 }
             }];
        }
        else
        {
            if (completion) completion(nil, [MBOError errorWithError:error extraInfo:data]);
        }
    }];
}

- (void)changePasswordForUsername:(NSString *)username previousPassword:(NSString *)previousPassword newPassword:(NSString *)newPassword completion:(void (^) (MBOError *error))completion
{
    NSString *changePasswordPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:@"/api/v2/users/%@/password", [username urlEncode]]];
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    
    NSDictionary *bodyData = @{@"password": newPassword, @"confirmed_password": newPassword, @"previous_password": previousPassword};
    
    
    [_httpClient PUT:changePasswordPath headers:headers parameters:nil data:bodyData completion:^(id data, NSError *error)
     {
         if(!error)
         {
             if(completion) completion(nil);
         }
         else
         {
             if(completion) completion([MBOError errorWithError:error extraInfo:data]);
         }
     }];
}

//------------------------------------------------------------------------------
#pragma mark Object management
//------------------------------------------------------------------------------

- (void)createObject:(MBOObject *)object updateIfAlreadyExist:(BOOL)updateIfAlreadyExist completion:(void (^)(MBOObject *newlyCreatedObject, MBOError *error))completion
{
    [self createObject:object updateIfAlreadyExist:updateIfAlreadyExist allowRefreshToken:YES completion:completion];
}

- (void)createObject:(MBOObject *)object updateIfAlreadyExist:(BOOL)updateIfAlreadyExist allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOObject *newlyCreatedObject, MBOError *error))completion
{
    
    NSString *createObjectPath = [NSString stringWithFormat:@"%@%@", _baseURL, kMnuboCreateObjectPath];
    
    MBOLog(@"Create object with path : %@", createObjectPath);

    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };

    __weak mnubo *weakSelf = self;
    [_httpClient POST:createObjectPath headers:headers parameters:nil data:[object toDictionary] completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
    {
        if(!error)
        {
            
            [weakSelf getObjectWithDeviceId:object.deviceId locationHeader:responsesHeaderFields[@"Location"] completion:^(MBOObject *object, MBOError *error)
            {
                if(error)
                {
                    MBOLog(@"Get object failed in create object. Error:%@", error);
                    if(completion) completion(nil, [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeGetNewCreatedObjectError userInfo:nil]);
                }
                else
                {
                    if(completion) completion(object, nil);
                }
                
            }];
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
            {
                if(!error)
                {
                    [weakSelf createObject:object updateIfAlreadyExist:updateIfAlreadyExist allowRefreshToken:NO completion:completion];
                }
                else
                {
                    if(completion) completion(nil, error);
                }
            }];
        }
        else
        {
            if(completion) completion(nil, [MBOError errorWithError:error extraInfo:data]);
        }
    }];
}

- (void)getObjectWithDeviceId:(NSString *)deviceId locationHeader:(NSString *)locationHeader completion:(void (^)(MBOObject *object, MBOError *error))completion
{
    if(deviceId.length == 0)
    {
        // No device id, we need to the the objectID from the location header
        NSArray *locationHeaderParts = [locationHeader componentsSeparatedByString:@"/"];
        if(locationHeaderParts.count == 0)
        {
            MBOLog(@"Invalid location header: %@", locationHeader);
            if(completion) completion(nil, [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeGetNewCreatedObjectError userInfo:nil]);
        }

        NSString *objectId = locationHeaderParts[locationHeaderParts.count - 1];
        [self getObjectWithObjectId:objectId completion:completion];
    }
    else
    {
        [self getObjectWithDeviceId:deviceId completion:completion];
    }
}

- (void)updateObject:(MBOObject *)object completion:(void (^)(MBOError *error))completion
{
    [self updateObject:object allowRefreshToken:YES completion:completion];
}

- (void)updateObject:(MBOObject *)object allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOError *error))completion
{
    if(object.deviceId.length == 0 && object.objectId.length == 0)
    {
        if(completion) completion([MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidParameter userInfo:nil]);
        return;
    }

    BOOL byObjectId = object.objectId.length > 0;

    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    NSDictionary *parameters = @{@"id_type" : byObjectId ? @"objectid" : @"deviceid"};

    __weak mnubo *weakSelf = self;
    [_httpClient PUT:[NSString stringWithFormat:@"%@%@", _baseURL, [NSString stringWithFormat:kMnuboUpdateObjectPath, byObjectId ? [object.objectId urlEncode] : [object.deviceId urlEncode]]] headers:headers parameters:parameters data:[object toDictionary] completion:^(id data, NSError *error)
    {
        if(!error)
        {
            if(completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
            {
                if(!error)
                {
                    [weakSelf updateObject:object allowRefreshToken:NO completion:completion];
                }
                else
                {
                    if(completion) completion(error);
                }
            }];
        }
        else
        {
            if(completion) completion([MBOError errorWithError:error extraInfo:data]);
        }
    }];
}

- (void)getObjectWithObjectId:(NSString *)objectId completion:(void (^)(MBOObject *object, MBOError *error))completion
{
    if(objectId.length == 0)
    {
        if(completion) completion(nil, [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidParameter userInfo:nil]);
        return;
    }

    [self getObjectWithObjectId:objectId orDeviceId:nil allowRefreshToken:YES completion:completion];
}

- (void)getObjectWithDeviceId:(NSString *)deviceId completion:(void (^)(MBOObject *object, MBOError *error))completion
{
    if(deviceId.length == 0)
    {
        if(completion) completion(nil, [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidParameter userInfo:nil]);
        return;
    }

    [self getObjectWithObjectId:nil orDeviceId:deviceId allowRefreshToken:YES completion:completion];
}

- (void)getObjectWithObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOObject *object, MBOError *error))completion
{
    BOOL byObjectId = objectId.length > 0;

    NSString *getObjectPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboGetObjectPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode]]];
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    NSDictionary *parameters = @{@"id_type" : byObjectId ? @"objectid" : @"deviceid"};

    __weak mnubo *weakSelf = self;
    [_httpClient GET:getObjectPath headers:headers parameters:parameters completion:^(id data, NSError *error)
    {
        if(!error)
        {
            if([data isKindOfClass:[NSDictionary class]])
            {
                if(completion) completion([[MBOObject alloc] initWithDictionary:data], nil);
            }
            else
            {
                if(completion) completion(nil, [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidDataReceived userInfo:nil]);
            }
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
            {
                if(!error)
                {
                    [weakSelf getObjectWithObjectId:objectId orDeviceId:deviceId allowRefreshToken:NO completion:completion];
                }
                else
                {
                    if(completion) completion(nil, error);
                }
            }];
        }
        else
        {
            if(completion) completion(nil, [MBOError errorWithError:error extraInfo:data]);
        }
    }];
}

- (void)deleteObjectWithObjectId:(NSString *)objectId completion:(void (^)(MBOError *error))completion
{
    [self deleteObjectWithObjectId:objectId orDeviceId:nil allowRefreshToken:YES completion:completion];
}

- (void)deleteObjectWithDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion
{
    [self deleteObjectWithObjectId:nil orDeviceId:deviceId allowRefreshToken:YES completion:completion];
}

- (void)deleteObjectWithObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOError *error))completion
{
    BOOL byObjectId = objectId.length > 0;

    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    NSDictionary *parameters = @{@"id_type" : byObjectId ? @"objectid" : @"deviceid"};

    __weak mnubo *weakSelf = self;
    [_httpClient DELETE:[NSString stringWithFormat:@"%@%@", _baseURL, [NSString stringWithFormat:kMnuboDeleteObjectPath, byObjectId ? [objectId urlEncode] : [deviceId urlEncode]]] headers:headers parameters:parameters completion:^(id data, NSError *error)
    {
         if(!error)
         {
             if(completion) completion(nil);
         }
         else if(error.code == 401 && allowRefreshToken)
         {
             [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
              {
                  if(!error)
                  {
                      [weakSelf deleteObjectWithObjectId:objectId orDeviceId:deviceId allowRefreshToken:NO completion:completion];
                  }
                  else
                  {
                      if(completion) completion(error);
                  }
              }];
         }
         else
         {
             if(completion) completion([MBOError errorWithError:error extraInfo:data]);
         }
     }];
}

//------------------------------------------------------------------------------
#pragma mark Sample
//------------------------------------------------------------------------------

- (void)sendSample:(MBOSample *)sample toPublicSensorName:(NSString *)sensorName withObjectId:(NSString *)objectId completion:(void (^) (MBOError *error))completion
{
    [self sendSample:sample withSensorName:sensorName withObjectId:objectId orDeviceId:nil allowRefreshToken:YES completion:completion];
}

- (void)sendSample:(MBOSample *)sample toPublicSensorName:(NSString *)sensorName withDeviceId:(NSString *)deviceId completion:(void (^) (MBOError *error))completion
{
    [self sendSample:sample withSensorName:sensorName withObjectId:nil orDeviceId:deviceId allowRefreshToken:YES completion:completion];
}

- (void)sendSample:(MBOSample *)sample forObjectId:(NSString *)objectId completion:(void (^) (MBOError *error))completion
{
    [self sendSample:sample withSensorName:nil withObjectId:objectId orDeviceId:nil allowRefreshToken:YES completion:completion];
}

- (void)sendSample:(MBOSample *)sample forDeviceId:(NSString *)deviceId completion:(void (^) (MBOError *error))completion
{
    [self sendSample:sample withSensorName:nil withObjectId:nil orDeviceId:deviceId allowRefreshToken:YES completion:completion];
}

- (void)sendSample:(MBOSample *)sample withSensorName:(NSString *)sensorName withObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOError *error))completion
{
    BOOL byObjectId = objectId.length > 0;
    
    NSString *postSensorPath;
    if (sensorName)
    {
        postSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboPostPublicSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode], sensorName]];
    }
    else
    {
        postSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboPostSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode]]];
    }
    
    
    MBOLog(@"Sample sent with path : %@", postSensorPath);

    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };

    NSDictionary *parameters = @{ @"id_type" : byObjectId ? @"objectid" : @"deviceid"};

    if (sample == nil) {
         if (completion)  completion([[MBOError alloc] initWithDomain:@"com.mnubo.sdk" code:0 userInfo:nil]);
    } else {
    NSDictionary *data = @{@"samples": @[[sample toDictionary]]};

    __weak mnubo *weakSelf = self;
    __weak id<MBOHttpClient> weakHttpClient = _httpClient;
    __weak MBOSensorDataQueue *weakSensorDataQueue = _sensorDataQueue;
    [_sensorDataQueue addSample:sample objectId:objectId deviceId:deviceId publicSensorName:sensorName completion:^(NSString *queueIdentifiyer)
     {
     [weakHttpClient POST:postSensorPath headers:headers parameters:parameters data:data completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
      {
          if(!error)
          {
              [weakSensorDataQueue removeSensorDataWithIdentifier:queueIdentifiyer];
              if(completion) completion(nil);
          }
          else if(error.code == 401 && allowRefreshToken)
          {
              [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
               {
                   [weakSensorDataQueue removeSensorDataWithIdentifier:queueIdentifiyer];
                   if(!error)
                   {
                       [weakSelf sendSample:sample withSensorName:sensorName withObjectId:objectId orDeviceId:deviceId allowRefreshToken:NO completion:completion];
                   }
                   else
                   {
                       if(completion) completion(error);
                   }
               }];
          }
          else
          {
              MBOError *builtError = nil;
              if([mnubo isErrorRetryable:error] && !weakSelf.disableSensorDataInternalRetry)
              {
                  builtError = [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeWillBeRetryLaterAutomatically userInfo:nil];
                  [weakSensorDataQueue moveToRetryQueueSensorDataWithIdentifier:queueIdentifiyer];
              }
              else
              {
                  builtError = [MBOError errorWithError:error extraInfo:data];
                  [weakSensorDataQueue removeSensorDataWithIdentifier:queueIdentifiyer];
              }
              
              if(completion) completion(builtError);
          }
      }];
     }];
    }
}

- (void)fetchLastSampleOfObjectId:(NSString *)objectId sensorName:(NSString *)sensorName completion:(void (^)(MBOSample *sample, MBOError *error))completion
{
    [self fetchLastSampleOfObjectId:objectId orDeviceId:nil sensorName:sensorName allowRefreshToken:YES completion:completion];
}

- (void)fetchLastSampleOfDeviceId:(NSString *)deviceId sensorName:(NSString *)sensorName completion:(void (^)(MBOSample *sample, MBOError *error))completion
{
    [self fetchLastSampleOfObjectId:nil orDeviceId:deviceId sensorName:sensorName allowRefreshToken:YES completion:completion];
}


- (void)fetchLastSampleOfObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId sensorName:(NSString *)sensorName allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOSample *sample, MBOError *error))completion
{
  BOOL byObjectId = objectId.length > 0;
  
  NSString *getSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboGetSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode], sensorName]];
  
  MBOLog(@"Sample fetched with path : %@", getSensorPath);
  
  NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
  NSDictionary *parameters = @{@"id_type" : byObjectId ? @"objectid" : @"deviceid",
                               @"value" : @"last" };
  
  __weak mnubo *weakSelf = self;
  [_httpClient GET:getSensorPath headers:headers parameters:parameters completion:^(id data, NSError *error)
   {
     if(!error)
     {
       BOOL invalidData = YES;
       if([data isKindOfClass:[NSDictionary class]])
       {
         NSDictionary *rawData = data;
         NSArray *samples = [rawData arrayForKey:@"samples"];
         
         if(samples.count > 0 && [samples[0] isKindOfClass:[NSDictionary class]])
         {
             invalidData = NO;
             if(completion) completion([[MBOSample alloc] initWithDictionary:samples[0]], nil);
         }
       }
       
       if(invalidData)
       {
         if(completion) completion(nil, [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidDataReceived userInfo:nil]);
       }
     }
     else if(error.code == 401 && allowRefreshToken)
     {
       [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
        {
          if(!error)
          {
            [weakSelf fetchLastSampleOfObjectId:objectId orDeviceId:deviceId sensorName:sensorName allowRefreshToken:NO completion:completion];
          }
          else
          {
            if(completion) completion(nil, error);
          }
        }];
     }
     else
     {
       if(completion) completion(nil, [MBOError errorWithError:error extraInfo:data]);
     }
   }];
}

//------------------------------------------------------------------------------
#pragma mark Authentication
//------------------------------------------------------------------------------
- (void)getClientAccessTokenCompletion:(void (^)(MBOError *error))completion
{
    NSString *getTokenPath = [NSString stringWithFormat:@"%@%@", _baseURL, kMnuboGetTokenPath];
    
    NSDictionary *headers = @{ @"Content-Type": @"application/json", @"Authorization" : [NSString stringWithFormat:@"Basic %@", _clientCredentialsTokenBasicAuthentication] };
    NSDictionary *parameters = @{ @"grant_type" : @"client_credentials"};
    
    [_httpClient POST:getTokenPath headers:headers parameters:parameters data:nil completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
    {
         if(!error && [data isKindOfClass:[NSDictionary class]])
         {
             NSDictionary *jsonData = data;
             _clientAccessToken = [jsonData objectForKey:@"access_token"];
             _clientExpiresIn = [jsonData objectForKey:@"expires_in"];
             _clientTokenTimestamp = [NSDate date];
             
             [self saveTokens];
             if(completion) completion(nil);
         }
         else
         {
             if(completion) completion([MBOError errorWithError:error extraInfo:data]);
         }
     }];
}

- (void)getUserAccessTokenWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(MBOError *error))completion
{
    if (!username || !password || [username length] == 0 || [password length] == 0)
    {
        if(completion) completion([MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidParameter userInfo:nil]);
        return;
    }
    
    NSString *getTokenPath = [NSString stringWithFormat:@"%@%@", _baseURL, kMnuboGetTokenPath];
    
    MBOLog(@"Get user access token with path : %@", getTokenPath);
    
    NSDictionary *headers = @{ @"Content-Type": @"application/x-www-form-urlencoded"};
    NSDictionary *parameters = @{ @"grant_type": @"password", @"client_id": _clientId, @"username": username, @"password": password};
    
    [_httpClient POST:getTokenPath headers:headers parameters:parameters data:nil completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
    {
         if(!error && [data isKindOfClass:[NSDictionary class]])
         {
             NSDictionary *jsonData = data;
             _userAccessToken = [jsonData objectForKey:@"access_token"];
             _userRefreshToken = [jsonData objectForKey:@"refresh_token"];
             _userExpiresIn = [jsonData objectForKey:@"expires_in"];
             _userTokenTimestamp = [NSDate date];
             
             [self saveTokens];
             if(completion) completion(nil);
         }
         else
         {
             if(completion) completion([MBOError errorWithError:error extraInfo:data]);
         }
     }];
}


- (void)getUserAccessTokenWithRefreshTokenCompletion:(void (^)(MBOError *error))completion
{
    NSString *getTokenPath = [NSString stringWithFormat:@"%@%@", _baseURL, kMnuboGetTokenPath];
    
    MBOLog(@"Get user access token with refresh token and path : %@", getTokenPath);
    
    NSDictionary *headers = @{ @"Content-Type": @"application/x-www-form-urlencoded"};
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:@"refresh_token" forKey:@"grant_type"];
    [parameters setValue:_clientId forKey:@"client_id"];
    [parameters setValue:_userRefreshToken forKey:@"refresh_token"];
    
    [_httpClient POST:getTokenPath headers:headers parameters:parameters data:nil completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
     {
         if(!error && [data isKindOfClass:[NSDictionary class]])
         {
             NSDictionary *jsonData = data;
             _userAccessToken = [jsonData objectForKey:@"access_token"];
             _userRefreshToken = [jsonData objectForKey:@"refresh_token"];
             _userExpiresIn = [jsonData objectForKey:@"expires_in"];
             _userTokenTimestamp = [NSDate date];
             
             
             [self saveTokens];
             if(completion) completion(nil);
         }
         else
         {
             //Refresh Token expired
             
             if ([self isUserConnected])
             {
                 [self logOut];
                 self.oauthErrorBlock(nil);
                 
             }
             
             if(completion) completion([MBOError errorWithError:error extraInfo:data]);
         }
     }];
}


- (BOOL)isUserConnected
{
    if (_userAccessToken != nil && ![_userAccessToken isEqualToString:@""])
        return YES;
    else
        return NO;
}

- (void)logInWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(MBOError *error))completion oauthErrorCompletion:(void (^) (MBOError *error))oauthErrorCompletion
{
    MBOLog(@"Login called with username : %@", username);
    
    self.oauthErrorBlock = oauthErrorCompletion;
    
    [self getUserAccessTokenWithUsername:username password:password completion:^(MBOError *error) {
        
       if(completion) completion(error);
    }];
}

- (void)logOut
{
    MBOLog(@"User logged out");
    
    _userAccessToken = nil;
    _userExpiresIn = nil;
    _userTokenTimestamp = nil;
    _userRefreshToken = nil;
    [self saveTokens];
}

- (void)resetPasswordForUsername:(NSString *)username completion:(void (^)(MBOError *error))completion
{
    [self resetPasswordForUsername:username allowRefreshClient:YES completion:completion];
}

- (void)resetPasswordForUsername:(NSString *)username allowRefreshClient:(BOOL)allowRefreshClient completion:(void (^)(MBOError *error))completion
{
    NSString *resetPasswordPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboResetPasswordPath, [username urlEncode]]];
    
    MBOLog(@"Reset password with path : %@", resetPasswordPath);
    
    NSDictionary *headers = @{ @"Authorization": [NSString stringWithFormat:@"Bearer %@", _clientAccessToken]};

    __weak mnubo *weakSelf = self;
    [_httpClient DELETE:resetPasswordPath headers:headers parameters:nil completion:^(id data, NSError *error)
    {
        if (!error)
        {
            MBOLog(@"Password has been reset successfully");
            if (completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshClient)
        {
            MBOLog(@"Error with the authentification");
            [weakSelf getClientAccessTokenCompletion:^(MBOError *error)
             {
                 if(!error)
                 {
                     [weakSelf resetPasswordForUsername:username allowRefreshClient:NO completion:completion];
                 }
                 else
                 {
                     if(completion) completion(error);
                 }
             }];
        }
        else
        {
            MBOLog(@"Error while reseting the password");
            if (completion) completion([MBOError errorWithError:error extraInfo:data]);
        }
    }];
    
}

- (void)confirmResetPasswordForUsername:(NSString *)username newPassword:(NSString *)newPassword confirmedNewPassword:(NSString *)confirmedNewPassword token:(NSString *)token completion:(void (^)(MBOError *error))completion
{
    [self confirmResetPasswordForUsername:username newPassword:newPassword confirmedNewPassword:confirmedNewPassword token:token allowRefreshClient:YES completion:completion];
}

- (void)confirmResetPasswordForUsername:(NSString *)username newPassword:(NSString *)newPassword confirmedNewPassword:(NSString *)confirmedNewPassword token:(NSString *)token allowRefreshClient:(BOOL)allowRefreshClient completion:(void (^)(MBOError *error))completion
{
    NSString *resetPasswordPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboResetPasswordPath, [username urlEncode]]];
    
    MBOLog(@"Confirm reset password with path : %@", resetPasswordPath);
    
    NSDictionary *headers = @{ @"Authorization": [NSString stringWithFormat:@"Bearer %@", _clientAccessToken]};
    NSDictionary *data = @{ @"token": token, @"password": newPassword, @"confirmed_password": confirmedNewPassword };
    
    __weak mnubo *weakSelf = self;
    [_httpClient POST:resetPasswordPath headers:headers parameters:nil data:data completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
     {
         if (!error)
         {
             MBOLog(@"Password reset has been confirmed successfully");
             if (completion) completion(nil);
         }
         else if(error.code == 401 && allowRefreshClient)
         {
             MBOLog(@"Error with the authentification");
             [weakSelf getClientAccessTokenCompletion:^(MBOError *error)
              {
                  if(!error)
                  {
                      [weakSelf confirmResetPasswordForUsername:username newPassword:newPassword confirmedNewPassword:confirmedNewPassword token:token allowRefreshClient:NO completion:completion];
                  }
                  else
                  {
                      if(completion) completion(error);
                  }
              }];
         }
         else
         {
             MBOLog(@"Error while confirming the reset password");
             if (completion) completion([MBOError errorWithError:error extraInfo:data]);
         }
     }];
    
}

- (void)confirmEmailForUsername:(NSString *)username password:(NSString *)password token:(NSString *)token completion:(void (^) (MBOError *error))completion
{
    [self confirmEmailForUsername:username password:password token:token allowRefreshClient:YES completion:completion];
}

- (void)confirmEmailForUsername:(NSString *)username password:(NSString *)password token:(NSString *)token allowRefreshClient:(BOOL)allowRefreshClient completion:(void (^) (MBOError *error))completion
{

    NSString *confirmEmailPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboConfirmEmailPath, [username urlEncode]]];
    
    MBOLog(@"Confirm email with path : %@", confirmEmailPath);
    
    NSDictionary *headers = @{ @"Authorization": [NSString stringWithFormat:@"Bearer %@", _clientAccessToken]};
    NSDictionary *data = @{ @"token": token, @"password": password};

    __weak mnubo *weakSelf = self;
    [_httpClient POST:confirmEmailPath headers:headers parameters:nil data:data completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
     {
         if (!error)
         {
             MBOLog(@"Email has been confirmed successfully");
             if (completion) completion(nil);
         }
         else if(error.code == 401 && allowRefreshClient)
         {
             MBOLog(@"Error with the authentification");
             [weakSelf getClientAccessTokenCompletion:^(MBOError *error)
              {
                  if(!error)
                  {
                      [weakSelf confirmEmailForUsername:username password:password token:token allowRefreshClient:NO completion:completion];
                  }
                  else
                  {
                      if(completion) completion(error);
                  }
              }];
         }
         else
         {
             MBOLog(@"Error while confirming the email");
             if (completion) completion([MBOError errorWithError:error extraInfo:data]);
         }
     }];
    
}


//------------------------------------------------------------------------------
#pragma mark  Helper methods
//------------------------------------------------------------------------------
+ (BOOL)isErrorRetryable:(NSError *)error
{
    if([Reachability reachabilityForInternetConnection] == NO)
    {
        return YES;
    }

    // Request timeout
    if(error.code == -1001)
    {
        return YES;
    }

    return NO;
}



@end
