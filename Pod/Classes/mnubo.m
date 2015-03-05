//
//  mnubo.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "mnubo.h"
#import "NSString+mnubo.h"
#import "MBOBasicHttpClient.h"
#import "MBOUser+Private.h"
#import "MBOError+Private.h"
#import "MBOObject+Private.h"
#import "MBOSensorData+Private.h"
#import "NSDictionary+mnubo.h"
#import "MBOSensorDefinition.h"
#import "MBODateHelper.h"
#import "MBOSensorDataQueue.h"
#import "Reachability.h"
#import "PDKeychainBindings.h"


NSString * const kMnuboClientAccessTokenKey = @"com.mnubo.sdk.client_access_token";
NSString * const kMnuboClientExpiresInKey = @"com.mnubo.sdk.client_expires_in";
NSString * const kMnuboClientTokenTimestampKey = @"com.mnubo.sdk.client_token_timestamp";

NSString * const kMnuboUserAccessTokenKey = @"com.mnubo.sdk.user_access_token";
NSString * const kMnuboUserRefreshTokenKey = @"com.mnubo.sdk.user_refresh_token";
NSString * const kMnuboUserExpiresInKey = @"com.mnubo.sdk.user_expires_in";
NSString * const kMnuboUserTokenTimestampKey = @"com.mnubo.sdk.user_token_timestamp";

NSString * const kMnuboRestApiBaseURL = @"https://rest.sandbox.mnubo.com:443/api/v3";

/// Tokens
NSString * const kMnuboGetTokenPath = @"/oauth/token";
NSString * const kMnuboResetPasswordPath = @"/users/%@/password";
NSString * const kMnuboConfirmEmailPath= @"/users/%@/confirmation";

/// Users
NSString * const kMnuboCreateUserPath = @"/users";
NSString * const kMnuboUpdateUserPath = @"/users/%@";
NSString * const kMnuboDeleteUserPath = @"/users/%@";
NSString * const kMnuboGetUserPath = @"/users/%@";


/// Objects
NSString * const kMnuboCreateObjectPath = @"/objects";
NSString * const kMnuboGetObjectPath = @"/objects/%@";
NSString * const kMnuboUpdateObjectPath = @"/objects/%@";
NSString * const kMnuboDeleteObjectPath = @"/objects/%@";


/// Sensor Data
NSString * const kMnuboPostSensorDataPath = @"/objects/%@/samples";
NSString * const kMnuboPostPublicSensorDataPath = @"/objects/%@/sensors/%@/samples";
NSString * const kMnuboGetSensorDataPath = @"/objects/%@/sensors/%@/samples";


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

+ (mnubo *)sharedInstanceWithClientId:(NSString *)clientId clientSecret:(NSString *)clientSecret hostname:(NSString *)hostname
{
    
    static dispatch_once_t unique = 0;
    
    dispatch_once(&unique, ^{
        _sharedInstance = [[self alloc] initWithAccountName:@"" namespace:@"" clientId:clientId clientSecret:clientSecret hostname:hostname];
    });
    
    return _sharedInstance;
}

+ (mnubo *)sharedInstance
{
    return _sharedInstance;
}

- (instancetype)initWithAccountName:(NSString *)accountName
                          namespace:(NSString *)namespace
                           clientId:(NSString *)clientId
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

        _accountName = accountName;
        _clientId = clientId;

        _clientCredentialsTokenBasicAuthentication = [[NSString stringWithFormat:@"%@:%@", clientId, clientSecret] base64Encode];


        _baseURL = hostname;

        [self loadTokens];
        
        if (!_clientAccessToken || !_clientExpiresIn)
        {
            [self getClientAccessTokenCompletion:^(MBOError *error) {
                if (!error)
                    NSLog(@"Client access token successfully fetched during SDK initialization");
                else
                    NSLog(@"ERROR while fetching the client access token during SDK initialization");
            }];
        }
        else
        {
            NSLog(@"Client access token found in the user defaults : %@", [_clientAccessToken substringToIndex:10]);
            NSLog(@"It expires in %@ seconds from its generation", _clientExpiresIn);
        }
    }

    return self;
}

- (void)setSensorDataRetryInterval:(NSTimeInterval)sensorDataRetryInterval
{
    if(_sensorDataRetryInterval == sensorDataRetryInterval) return;
    
    _sensorDataRetryInterval = sensorDataRetryInterval;
    
    [_sensorDataQueue setRetryInterval:_sensorDataRetryInterval];
}

- (void)loadTokens
{
    
    _clientAccessToken = [[PDKeychainBindings sharedKeychainBindings] stringForKey:kMnuboClientAccessTokenKey];
    _clientExpiresIn = [[NSUserDefaults standardUserDefaults] objectForKey:kMnuboClientExpiresInKey];
    _clientTokenTimestamp = [[NSUserDefaults standardUserDefaults] objectForKey:kMnuboClientTokenTimestampKey];
    
    
    _userAccessToken = [[PDKeychainBindings sharedKeychainBindings] stringForKey:kMnuboUserAccessTokenKey];
    _userRefreshToken = [[PDKeychainBindings sharedKeychainBindings] stringForKey:kMnuboUserRefreshTokenKey];
    _userExpiresIn = [[NSUserDefaults standardUserDefaults] objectForKey:kMnuboUserExpiresInKey];
    _userTokenTimestamp = [[NSUserDefaults standardUserDefaults] objectForKey:kMnuboUserTokenTimestampKey];
}

- (void)saveTokens
{
    [[PDKeychainBindings sharedKeychainBindings] setString:_clientAccessToken forKey:kMnuboClientAccessTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:_clientExpiresIn forKey:kMnuboClientExpiresInKey];
    [[NSUserDefaults standardUserDefaults] setObject:_clientTokenTimestamp forKey:kMnuboClientTokenTimestampKey];
    
    [[PDKeychainBindings sharedKeychainBindings] setString:_userAccessToken forKey:kMnuboUserAccessTokenKey];
    [[PDKeychainBindings sharedKeychainBindings] setString:_userRefreshToken forKey:kMnuboUserRefreshTokenKey];
    [[NSUserDefaults standardUserDefaults] setObject:_userExpiresIn forKey:kMnuboUserExpiresInKey];
    [[NSUserDefaults standardUserDefaults] setObject:_userTokenTimestamp forKey:kMnuboUserTokenTimestampKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setUseSandbox:(BOOL)useSandbox
{
    if(_useSandbox == useSandbox) return;

    _useSandbox = useSandbox;

    if(_useSandbox)
    {
        _baseURL = [NSString stringWithFormat:@"https://sandbox.%@:4443", kMnuboRestApiBaseURL];
    }
    else
    {
        _baseURL = [NSString stringWithFormat:@"https://%@.%@", _accountName, kMnuboRestApiBaseURL];
    }
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
    NSDictionary *parameters = @{};

    __weak mnubo *weakSelf = self;
    [_httpClient PUT:getUsernamePath headers:headers parameters:parameters data:[user toDictionary] completion:^(id data, NSError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _clientAccessToken] };
    NSDictionary *parameters = @{};
    
    __weak mnubo *weakSelf = self;
    [_httpClient GET:getUsernamePath headers:headers parameters:parameters completion:^(id data, NSError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _clientAccessToken] };
    NSDictionary *parameters = @{};

    __weak mnubo *weakSelf = self;
    [_httpClient DELETE:deleteUserPath headers:headers parameters:parameters completion:^(id data, NSError *error)
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


- (void)getObjectsOfUsername:(NSString *)username completion:(void (^) (NSArray *objects, NSError *error))completion {
    NSString *path = [NSString stringWithFormat:@"%@/users/%@/objects", _baseURL, username];
    
    NSLog(@"Get user's objects with path : %@", path);
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    
    [_httpClient GET:path headers:headers parameters:nil completion:^(id data, NSError *error) {
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
        else
        {
            if (completion) completion(nil, error);
        }
    }];
}

- (void)changePasswordForUsername:(NSString *)username oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completion:(void (^) (NSError *error))completion
{
    NSString *path = [NSString stringWithFormat:@"%@/users/%@/password", _baseURL, username];
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _clientAccessToken] };
    
    NSDictionary *bodyData = @{@"password": newPassword, @"confirmed_password": newPassword, @"previous_password": oldPassword};
    
    
    [_httpClient PUT:path headers:headers parameters:nil data:bodyData completion:^(id data, NSError *error)
     {
         if(!error)
         {
             if(completion) completion(nil);
         }
         else
         {
             if(completion) completion(error);
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
    
    NSLog(@"Create object with path : %@", createObjectPath);
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    
    NSDictionary *parameters = @{};
    //NSDictionary *parameters = @{ @"clientid" : _clientId, @"updateifexists" : updateIfAlreadyExist ? @"1" : @"0"};

    __weak mnubo *weakSelf = self;
    [_httpClient POST:createObjectPath headers:headers parameters:parameters data:[object toDictionary] completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
    {
        if(!error)
        {
            
            [weakSelf getObjectWithDeviceId:object.deviceId locationHeader:responsesHeaderFields[@"Location"] completion:^(MBOObject *object, MBOError *error)
            {
                if(error)
                {
                    NSLog(@"Get object failed in create object. Error:%@", error);
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
        // No device id, we need to the the objectID from the location header // Location	https://sandbox.api.mnubo.com:4443//rest/objects/5c81fe00-064c-4876-bfce-907b4d10a193
        NSArray *locationHeaderParts = [locationHeader componentsSeparatedByString:@"/"];
        if(locationHeaderParts.count == 0)
        {
            NSLog(@"Invalid location header: %@", locationHeader);
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
#pragma mark Sensor data
//------------------------------------------------------------------------------

- (void)sendSensorData:(NSArray *)sensorDatas forObjectId:(NSString *)objectId completion:(void (^)(MBOError *error))completion
{
    [self sendSensorData:sensorDatas commonData:nil forObjectId:objectId completion:completion];
}

- (void)sendSensorData:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData forObjectId:(NSString *)objectId completion:(void (^)(MBOError *error))completion
{
    [self sendSensorData:sensorDatas commonData:commonData withObjectId:objectId orDeviceId:nil allowRefreshToken:YES completion:completion];
}

- (void)sendSensorData:(NSArray *)sensorDatas forDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion
{
    [self sendSensorData:sensorDatas commonData:nil forDeviceId:deviceId completion:completion];
}

- (void)sendSensorData:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData forDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion
{
    [self sendSensorData:sensorDatas commonData:commonData withObjectId:nil orDeviceId:deviceId allowRefreshToken:YES completion:completion];
}

- (void)sendSensorData:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData withObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOError *error))completion
{
    NSAssert(sensorDatas.count > 0, @"sensorDatas can't be empty");
    NSAssert([sensorDatas[0] isKindOfClass:[MBOSensorData class]], @"sensorDatas has to be an array of instance of MBOSensorData");

    BOOL byObjectId = objectId.length > 0;

    NSString *postSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboPostSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode]]];
    
    NSLog(@"Sample sent with path : %@", postSensorPath);
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    NSDictionary *parameters = @{ @"id_type" : byObjectId ? @"objectid" : @"deviceid"};

    __weak mnubo *weakSelf = self;
    __weak id<MBOHttpClient> weakHttpClient = _httpClient;
    __weak MBOSensorDataQueue *weakSensorDataQueue = _sensorDataQueue;
    [_sensorDataQueue addSensorData:sensorDatas commonData:commonData objectId:objectId deviceId:deviceId completion:^(NSString *queueIdentifiyer)
    {
        [weakHttpClient POST:postSensorPath headers:headers parameters:parameters data:[MBOSensorData dictionaryFromSensorDatas:sensorDatas commonData:commonData] completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
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
                        [weakSelf sendSensorData:sensorDatas commonData:commonData withObjectId:objectId orDeviceId:deviceId allowRefreshToken:NO completion:completion];
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

- (void)fetchLastSensorDataOfObjectId:(NSString *)objectId sensorDefinition:(MBOSensorDefinition *)sensorDefinition completion:(void (^)(MBOSensorData *sensorData, MBOError *error))completion
{
    [self fetchLastSensorDataObjectId:objectId orDeviceId:nil sensorDefinition:sensorDefinition allowRefreshToken:YES completion:completion];
}

- (void)fetchLastSensorDataOfDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition completion:(void (^)(MBOSensorData *sensorData, MBOError *error))completion
{
    [self fetchLastSensorDataObjectId:nil orDeviceId:deviceId sensorDefinition:sensorDefinition allowRefreshToken:YES completion:completion];
}

- (void)fetchLastSensorDataObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOSensorData *sensorData, MBOError *error))completion
{
    BOOL byObjectId = objectId.length > 0;
    
    NSString *getSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboGetSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode], [sensorDefinition.name urlEncode]]];
    
    NSLog(@"Sample fetched with path : %@", getSensorPath);
    
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
                    if(completion) completion([[MBOSensorData alloc] initWithSensorDefinition:sensorDefinition andDictionary:samples[0]], nil);
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
                     [weakSelf fetchLastSensorDataObjectId:objectId orDeviceId:deviceId sensorDefinition:sensorDefinition allowRefreshToken:NO completion:completion];
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

- (void)fetchSensorDatasOfObjectId:(NSString *)objectId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate completion:(void (^)(NSArray *sensorDatas, MBOError *error))completion
{
    [self fetchSensorDatasOfObjectId:objectId orDeviceId:nil sensorDefinition:sensorDefinition fromStartDate:startDate toEndDate:endDate allowRefreshToken:YES completion:completion];
}

- (void)fetchSensorDatasOfDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate completion:(void (^)(NSArray *sensorDatas, MBOError *error))completion
{
    [self fetchSensorDatasOfObjectId:nil orDeviceId:deviceId sensorDefinition:sensorDefinition fromStartDate:startDate toEndDate:endDate allowRefreshToken:YES completion:completion];
}

- (void)fetchSensorDatasOfObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(NSArray *sensorDatas, MBOError *error))completion
{
    BOOL byObjectId = objectId.length > 0;
    
    NSString *getSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboGetSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode], [sensorDefinition.name urlEncode]]];
    
    NSLog(@"Sample fetched with path : %@", getSensorPath);
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"id_type" : byObjectId ? @"objectid" : @"deviceid",
                                  @"value" : @"samples",
                                  @"startdate" : [MBODateHelper mnuboStringFromDate:startDate],
                                  @"enddate" : [MBODateHelper mnuboStringFromDate:endDate] };

    __weak mnubo *weakSelf = self;
    [_httpClient GET:getSensorPath headers:headers parameters:parameters completion:^(id data, NSError *error)
    {
        if(!error)
        {
            if([data isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *rawData = data;

                NSArray *samples = [rawData arrayForKey:@"samples"];
                __block NSMutableArray *sensorDatas = [NSMutableArray arrayWithCapacity:samples.count];
                [samples enumerateObjectsUsingBlock:^(NSDictionary *sampleData, NSUInteger idx, BOOL *stop)
                {
                    if([sampleData isKindOfClass:[NSDictionary class]])
                    {
                        [sensorDatas addObject:[[MBOSensorData alloc] initWithSensorDefinition:sensorDefinition andDictionary:sampleData]];
                    }
                }];

                if(completion) completion(sensorDatas, nil);
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
                    [weakSelf fetchSensorDatasOfObjectId:objectId orDeviceId:deviceId sensorDefinition:sensorDefinition fromStartDate:startDate toEndDate:endDate allowRefreshToken:NO completion:completion];
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

- (void)fetchSensorDataCountOfObjectId:(NSString *)objectId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate completion:(void (^)(NSUInteger count, MBOError *error))completion
{
    [self fetchSensorDataCountOfObjectId:objectId orDeviceId:nil sensorDefinition:sensorDefinition fromStartDate:startDate toEndDate:endDate allowRefreshToken:YES completion:completion];
}

- (void)fetchSensorDataCountOfDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate completion:(void (^)(NSUInteger count, MBOError *error))completion
{
    [self fetchSensorDataCountOfObjectId:nil orDeviceId:deviceId sensorDefinition:sensorDefinition fromStartDate:startDate toEndDate:endDate allowRefreshToken:YES completion:completion];
}

- (void)fetchSensorDataCountOfObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(NSUInteger count, MBOError *error))completion
{
    BOOL byObjectId = objectId.length > 0;

    NSString *getSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboGetSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode], [sensorDefinition.name urlEncode]]];
    
    NSLog(@"Sample fetched with path : %@", getSensorPath);
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"id_type" : byObjectId ? @"objectid" : @"deviceid",
                                  @"value" : @"count",
                                  @"startdate" : [MBODateHelper mnuboStringFromDate:startDate],
                                  @"enddate" : [MBODateHelper mnuboStringFromDate:endDate] };

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
                    NSDictionary *values = (NSDictionary *)samples[0];
                    NSDictionary *value = [values dictionaryForKey:@"values"];
                    if(value)
                    {
                        NSNumber *count = [value numberForKey:@"count"];
                        if(completion) completion(count.unsignedIntegerValue, nil);
                        invalidData = NO;
                    }
                }
            }

            if(invalidData)
            {
                if(completion) completion(0, [MBOError errorWithDomain:@"com.mnubo.sdk" code:MBOErrorCodeInvalidDataReceived userInfo:nil]);
            }
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
            {
                if(!error)
                {
                    [weakSelf fetchSensorDataCountOfObjectId:objectId orDeviceId:deviceId sensorDefinition:sensorDefinition fromStartDate:startDate toEndDate:endDate allowRefreshToken:NO completion:completion];
                }
                else
                {
                    if(completion) completion(0, error);
                }
            }];
        }
        else
        {
            if(completion) completion(0, [MBOError errorWithError:error extraInfo:data]);
        }
    }];
}


#pragma mark Sensor Sample 2.0


- (void)sendSample:(MBOSample *)sample withObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion
{
    BOOL byObjectId = objectId.length > 0;
    
    NSString *postSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboPostSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode]]];
    
    NSLog(@"Sample sent with path : %@", postSensorPath);
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    NSDictionary *parameters = @{ @"id_type" : byObjectId ? @"objectid" : @"deviceid"};
    
    NSDictionary *data = @{@"samples": @[[sample toDictionary]]};
    
    __weak mnubo *weakSelf = self;

     [_httpClient POST:postSensorPath headers:headers parameters:parameters data:data completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
      {
          if(!error)
          {
              if(completion) completion(nil);
          }
          else if(error.code == 401)
          {
              [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
               {
                   if(!error)
                   {
                       [weakSelf sendSample:sample withObjectId:objectId orDeviceId:deviceId completion:completion];
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
              }
              else
              {
                  builtError = [MBOError errorWithError:error extraInfo:data];
              }
              
              if(completion) completion(builtError);
          }
      }];
}

- (void)sendToPublicSensorASample:(MBOSample *)sample withName:(NSString *)sensorName withObjectId:(NSString *)objectId orDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion
{
    BOOL byObjectId = objectId.length > 0;
    
    NSString *postSensorPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboPostPublicSensorDataPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode], sensorName]];
    
    NSLog(@"Sample sent with path : %@", postSensorPath);
    
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _userAccessToken] };
    NSDictionary *parameters = @{ @"id_type" : byObjectId ? @"objectid" : @"deviceid"};
    
    NSDictionary *data = @{@"samples": @[[sample toDictionary]]};
    
    __weak mnubo *weakSelf = self;
    
    [_httpClient POST:postSensorPath headers:headers parameters:parameters data:data completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
     {
         if(!error)
         {
             if(completion) completion(nil);
         }
         else if(error.code == 401)
         {
             [weakSelf getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error)
              {
                  if(!error)
                  {
                      [weakSelf sendSample:sample withObjectId:objectId orDeviceId:deviceId completion:completion];
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
             }
             else
             {
                 builtError = [MBOError errorWithError:error extraInfo:data];
             }
             
             if(completion) completion(builtError);
         }
     }];
}

//------------------------------------------------------------------------------
#pragma mark Tokens
//------------------------------------------------------------------------------
- (void)getClientAccessTokenCompletion:(void (^)(MBOError *error))completion
{
    NSString *getTokenPath = [NSString stringWithFormat:@"%@%@", _baseURL, kMnuboGetTokenPath];
    
    NSDictionary *headers = @{ @"Content-Type": @"application/json", @"Authorization" : [NSString stringWithFormat:@"Basic %@", _clientCredentialsTokenBasicAuthentication] };
    NSDictionary *parameters = @{ @"grant_type" : @"client_credentials"};
    
    [_httpClient POST:getTokenPath headers:headers parameters:parameters data:@{} completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
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
    NSString *getTokenPath = [NSString stringWithFormat:@"%@%@", _baseURL, kMnuboGetTokenPath];
    
    NSLog(@"Get user access token with path : %@", getTokenPath);
    
    NSDictionary *headers = @{ @"Content-Type": @"application/x-www-form-urlencoded"};
    NSDictionary *parameters = @{ @"grant_type": @"password", @"client_id": _clientId, @"username": username, @"password": password};
    
    [_httpClient POST:getTokenPath headers:headers parameters:parameters data:@{} completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
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
    
    NSLog(@"Get user access token with refresh token and path : %@", getTokenPath);
    
    NSDictionary *headers = @{ @"Content-Type": @"application/x-www-form-urlencoded"};
    NSDictionary *parameters = @{ @"grant_type": @"refresh_token", @"client_id": _clientId, @"refresh_token": _userRefreshToken};
    
    [_httpClient POST:getTokenPath headers:headers parameters:parameters data:@{} completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
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

- (BOOL)isTokenValid
{
    if (_userRefreshToken)
    {
        NSTimeInterval interval = [_userTokenTimestamp timeIntervalSinceNow];
        double remainingValidity = interval + [_userExpiresIn doubleValue];
        
        NSLog(@"Validity : %f", remainingValidity);
        
        if (remainingValidity <= 0)
        {
            [self getUserAccessTokenWithRefreshTokenCompletion:^(MBOError *error) {
                if (!error)
                    NSLog(@"Refresh Token used.");
                else
                    NSLog(@"ERROR while refreshing the token.");
            }];
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else
    {
        return NO;
    }
}

- (BOOL)isUserConnected
{
    if (_userAccessToken)
        return YES;
    else
        return NO;
}

- (void)logInWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(MBOError *error))completion oauthErrorCompletion:(void (^) (MBOError *error))oauthErrorCompletion
{
    NSLog(@"Login called with username : %@", username);
    
    self.oauthErrorBlock = oauthErrorCompletion;
    
    [self getUserAccessTokenWithUsername:username password:password completion:^(MBOError *error) {
       if(completion) completion(error);
    }];
}

- (void)logOut
{
    NSLog(@"User logged out");
    
    _userAccessToken = nil;
    _userExpiresIn = nil;
    _userTokenTimestamp = nil;
    _userRefreshToken = nil;
    [self saveTokens];
}

- (void)resetPasswordForUsername:(NSString *)username
{
    NSString *resetPasswordPath = [NSString stringWithFormat:@"%@%@", _baseURL, [NSString stringWithFormat:kMnuboResetPasswordPath, username]];
    
    NSLog(@"Reset password with path : %@", resetPasswordPath);
    
    NSDictionary *headers = @{ @"Authorization": [NSString stringWithFormat:@"Bearer %@", _clientAccessToken]};
    
    [_httpClient DELETE:resetPasswordPath headers:headers parameters:nil completion:^(id data, NSError *error)
    {
        if (!error)
        {
            NSLog(@"Password has been reset successfully");
        }
        else
        {
            NSLog(@"Error while reseting the password");
        }
    }];
    
}

- (void)confirmResetPasswordForUsername:(NSString *)username newPassword:(NSString *)newPassword token:(NSString *)token
{
    NSString *resetPasswordPath = [NSString stringWithFormat:@"%@%@", _baseURL, [NSString stringWithFormat:kMnuboResetPasswordPath, username]];
    
    NSLog(@"Confirm reset password with path : %@", resetPasswordPath);
    
    NSDictionary *headers = @{ @"Authorization": [NSString stringWithFormat:@"Bearer %@", _clientAccessToken]};
    NSDictionary *data = @{ @"token": token, @"password": newPassword, @"confirmed_password": newPassword };
    
    [_httpClient POST:resetPasswordPath headers:headers parameters:nil data:data completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
     {
         if (!error)
         {
             NSLog(@"Password reset has been confirmed successfully");
         }
         else
         {
             NSLog(@"Error while confirming the reset password");
         }
     }];
    
}


- (void)confirmEmailForUsername:(NSString *)username password:(NSString *)password token:(NSString *)token
{
    NSString *confirmEmailPath = [NSString stringWithFormat:@"%@%@", _baseURL, [NSString stringWithFormat:kMnuboConfirmEmailPath, username]];
    
    NSLog(@"Confirm email with path : %@", confirmEmailPath);
    
    NSDictionary *headers = @{ @"Authorization": [NSString stringWithFormat:@"Bearer %@", _userAccessToken]};
    NSDictionary *data = @{ @"token": token, @"password": password};
    
    [_httpClient POST:confirmEmailPath headers:headers parameters:nil data:data completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
     {
         if (!error)
         {
             NSLog(@"Email has been confirmed successfully");
         }
         else
         {
             NSLog(@"Error while confirming the email");
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
