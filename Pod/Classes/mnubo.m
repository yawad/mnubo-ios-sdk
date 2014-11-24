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

NSString * const kMnuboReadAccessTokenKey = @"com.mnubo.sdk.read_access_token";
NSString * const kMnuboWriteAccessTokenKey = @"com.mnubo.sdk.write_access_token";

NSString * const kMnuboRestApiBaseURL = @"api.mnubo.com";

NSString * const kMnuboGetTokenPath = @"/tokens/1";

/// Users
NSString * const kMnuboCreateUserPath = @"objwrite/1/users/";
NSString * const kMnuboUpdateUserPath = @"objwrite/1/users/%@";
NSString * const kMnuboDeleteUserPath = @"objwrite/1/users/%@";
NSString * const kMnuboGetUserPath = @"objread/1/users/%@";


/// Objects
NSString * const kMnuboCreateObjectPath = @"objwrite/1/objects/";
NSString * const kMnuboGetObjectPath = @"objread/1/objects/%@";
NSString * const kMnuboUpdateObjectPath = @"objwrite/1/objects/%@";
NSString * const kMnuboDeleteObjectPath = @"objwrite/1/objects/%@";


/// Sensor Data
NSString * const kMnuboPostSensorDataPath = @"objwrite/1/objects/%@/samples";
NSString * const kMnuboGetSensorDataPath = @"/objread/1/objects/%@/sensors/%@/samples";

typedef NS_ENUM(NSUInteger, MnuboApplicationType)
{
    MnuboApplicationTypeReadOnly,
    MnuboApplicationTypeWriteOnly
};

@interface mnubo()
{
    id<MBOHttpClient> _httpClient;
    MBOSensorDataQueue *_sensorDataQueue;

    NSString *_clientId;
    NSString *_baseURL;

    /// Tokens
    NSString *_readAccessToken;
    NSString *_writeAccessToken;

    /// Authentication
    NSString *_readTokenBasicAuthentication;
    NSString *_writeTokenBasicAuthentication;

    NSString *_accountName;
}

@end

@implementation mnubo

- (instancetype)initWithAccountName:(NSString *)accountName
                          namespace:(NSString *)namespace
              readAccessConsumerKey:(NSString *)readAccessConsumerKey
           readAccessConsumerSecret:(NSString *)readAccessConsumerSecret
             writeAccessConsumerKey:(NSString *)writeAccessConsumerKey
          writeAccessConsumerSecret:(NSString *)writeAccessConsumerSecret
{
    self = [super init];
    if(self)
    {
        _sensorDataRetryInterval = 30;
        _disableSensorDataInternalRetry = NO;
        
        _sensorDataQueue = [[MBOSensorDataQueue alloc] initWithRetryInterval:_sensorDataRetryInterval mnuboSDK:self];

        _httpClient = [[MBOBasicHttpClient alloc] init];

        _accountName = accountName;
        _clientId = [[NSString stringWithFormat:@"%@:%@", _accountName, namespace] base64Encode];

        _readTokenBasicAuthentication = [[NSString stringWithFormat:@"%@:%@", readAccessConsumerKey, readAccessConsumerSecret] base64Encode];
        _writeTokenBasicAuthentication = [[NSString stringWithFormat:@"%@:%@", writeAccessConsumerKey, writeAccessConsumerSecret] base64Encode];

        _baseURL = [NSString stringWithFormat:@"https://%@.%@", _accountName, kMnuboRestApiBaseURL];

        [self loadTokens];
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
    _readAccessToken = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%@", kMnuboReadAccessTokenKey, _clientId]];
    _writeAccessToken = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%@", kMnuboWriteAccessTokenKey, _clientId]];
}

- (void)saveTokens
{
    [[NSUserDefaults standardUserDefaults] setObject:_readAccessToken forKey:[NSString stringWithFormat:@"%@_%@", kMnuboReadAccessTokenKey, _clientId]];
    [[NSUserDefaults standardUserDefaults] setObject:_writeAccessToken forKey:[NSString stringWithFormat:@"%@_%@", kMnuboWriteAccessTokenKey, _clientId]];
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _writeAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"updateifexists" : updateIfAlreadyExist ? @"1" : @"0"};

    __weak mnubo *weakSelf = self;
    [_httpClient POST:[_baseURL stringByAppendingPathComponent:kMnuboCreateUserPath] headers:headers parameters:parameters data:[user toDictionary] completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
    {
        if(!error)
        {
            if(completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeWriteOnly completion:^(MBOError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _writeAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId };

    __weak mnubo *weakSelf = self;
    [_httpClient PUT:getUsernamePath headers:headers parameters:parameters data:[user toDictionary] completion:^(id data, NSError *error)
    {
        if(!error)
        {
            if(completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeWriteOnly completion:^(MBOError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _readAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId };
    
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
             [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeReadOnly completion:^(MBOError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _writeAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId };

    __weak mnubo *weakSelf = self;
    [_httpClient DELETE:deleteUserPath headers:headers parameters:parameters completion:^(id data, NSError *error)
    {
        if(!error)
        {
            if(completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeWriteOnly completion:^(MBOError *error)
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

//------------------------------------------------------------------------------
#pragma mark Object management
//------------------------------------------------------------------------------

- (void)createObject:(MBOObject *)object updateIfAlreadyExist:(BOOL)updateIfAlreadyExist completion:(void (^)(MBOObject *newlyCreatedObject, MBOError *error))completion
{
    [self createObject:object updateIfAlreadyExist:updateIfAlreadyExist allowRefreshToken:YES completion:completion];
}

- (void)createObject:(MBOObject *)object updateIfAlreadyExist:(BOOL)updateIfAlreadyExist allowRefreshToken:(BOOL)allowRefreshToken completion:(void (^)(MBOObject *newlyCreatedObject, MBOError *error))completion
{
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _writeAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"updateifexists" : updateIfAlreadyExist ? @"1" : @"0"};

    __weak mnubo *weakSelf = self;
    [_httpClient POST:[_baseURL stringByAppendingPathComponent:kMnuboCreateObjectPath] headers:headers parameters:parameters data:[object toDictionary] completion:^(id data, NSDictionary *responsesHeaderFields, NSError *error)
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
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeWriteOnly completion:^(MBOError *error)
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
    NSString *getUsernamePath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboUpdateObjectPath, byObjectId ? [object.objectId urlEncode] : [object.deviceId urlEncode]]];
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _writeAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"idtype" : byObjectId ? @"objectid" : @"deviceid"};

    __weak mnubo *weakSelf = self;
    [_httpClient PUT:getUsernamePath headers:headers parameters:parameters data:[object toDictionary] completion:^(id data, NSError *error)
    {
        if(!error)
        {
            if(completion) completion(nil);
        }
        else if(error.code == 401 && allowRefreshToken)
        {
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeWriteOnly completion:^(MBOError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _readAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"idtype" : byObjectId ? @"objectid" : @"deviceid"};

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
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeReadOnly completion:^(MBOError *error)
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

    NSString *deleteUserPath = [_baseURL stringByAppendingPathComponent:[NSString stringWithFormat:kMnuboDeleteObjectPath, byObjectId ? [objectId urlEncode]: [deviceId urlEncode]]];
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _writeAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"idtype" : byObjectId ? @"objectid" : @"deviceid"};

    __weak mnubo *weakSelf = self;
    [_httpClient DELETE:deleteUserPath headers:headers parameters:parameters completion:^(id data, NSError *error)
    {
         if(!error)
         {
             if(completion) completion(nil);
         }
         else if(error.code == 401 && allowRefreshToken)
         {
             [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeWriteOnly completion:^(MBOError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _writeAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"idtype" : byObjectId ? @"objectid" : @"deviceid"};

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
                [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeWriteOnly completion:^(MBOError *error)
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
                if([mnubo isErrorRetryable:error] && !_disableSensorDataInternalRetry)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _readAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"idtype" : byObjectId ? @"objectid" : @"deviceid",
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
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeReadOnly completion:^(MBOError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _readAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"idtype" : byObjectId ? @"objectid" : @"deviceid",
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
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeReadOnly completion:^(MBOError *error)
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
    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Bearer %@", _readAccessToken] };
    NSDictionary *parameters = @{ @"clientid" : _clientId,
                                  @"idtype" : byObjectId ? @"objectid" : @"deviceid",
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
            [weakSelf refreshTokenOfApplicationType:MnuboApplicationTypeReadOnly completion:^(MBOError *error)
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

//------------------------------------------------------------------------------
#pragma mark Tokens
//------------------------------------------------------------------------------
- (void)refreshTokenOfApplicationType:(MnuboApplicationType)applicationType completion:(void (^)(MBOError *error))completion
{
    NSString *getTokenPath = [_baseURL stringByAppendingPathComponent:kMnuboGetTokenPath];

    NSString *getTokenBasicAuth;
    switch (applicationType)
    {
        case MnuboApplicationTypeReadOnly:
            getTokenBasicAuth = _readTokenBasicAuthentication;
            break;
        case MnuboApplicationTypeWriteOnly:
            getTokenBasicAuth = _writeTokenBasicAuthentication;
            break;
    }

    NSDictionary *headers = @{ @"Authorization" : [NSString stringWithFormat:@"Basic %@", getTokenBasicAuth] };

    [_httpClient GET:getTokenPath headers:headers parameters:@{ @"clientid" : _clientId } completion:^(id data, NSError *error)
    {
        if(!error && [data isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *jsonData = data;
            switch (applicationType)
            {
                case MnuboApplicationTypeReadOnly:
                    _readAccessToken = [jsonData objectForKey:@"access_token"];
                    break;
                case MnuboApplicationTypeWriteOnly:
                    _writeAccessToken = [jsonData objectForKey:@"access_token"];
                    break;
            }

            [self saveTokens];
            if(completion) completion(nil);
        }
        else
        {
            if(completion) completion([MBOError errorWithError:error extraInfo:data]);
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
