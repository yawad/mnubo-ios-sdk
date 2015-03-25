//
//  mnubo.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOError.h"
#import "MBOObject.h"
#import "MBOSensorData.h"
#import "MBOCommonSensorData.h"
#import "MBOSensorDefinition.h"
#import "MBOUser.h"
#import "MBOAttribute.h"
#import "MBOSample.h"



@interface mnubo : NSObject

@property(nonatomic) BOOL useSandbox;
@property(nonatomic) NSTimeInterval sensorDataRetryInterval; // Default value: 30 seconds
@property(nonatomic) BOOL disableSensorDataInternalRetry;

@property (copy, nonatomic) void (^oauthErrorBlock) (MBOError *error);


+ (mnubo *)sharedInstanceWithClientId:(NSString *)clientId clientSecret:(NSString *)clientSecret hostname:(NSString *)hostname;
+ (mnubo *)sharedInstance;
+ (void)enableLogging;
+ (void)disableLogging;
+ (BOOL)isLoggingEnabled;


/// User management
- (void)createUser:(MBOUser *)user updateIfAlreadyExist:(BOOL)updateIfAlreadyExist completion:(void (^)(MBOError *error))completion;

- (void)updateUser:(MBOUser *)user completion:(void (^)(MBOError *error))completion;

- (void)getUserWithUsername:(NSString *)username completion:(void (^)(MBOUser *user, MBOError *error))completion;

- (void)deleteUserWithUsername:(NSString *)username completion:(void (^)(MBOError *error))completion;

- (void)getObjectsOfUsername:(NSString *)username completion:(void (^) (NSArray *objects, NSError *error))completion;

- (void)changePasswordForUsername:(NSString *)username oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completion:(void (^) (NSError *error))completion;

/// Object management
- (void)createObject:(MBOObject *)object updateIfAlreadyExist:(BOOL)updateIfAlreadyExist completion:(void (^)(MBOObject *newlyCreatedObject, MBOError *error))completion;

- (void)updateObject:(MBOObject *)object completion:(void (^)(MBOError *error))completion;

- (void)getObjectWithObjectId:(NSString *)objectId completion:(void (^)(MBOObject *object, MBOError *error))completion;
- (void)getObjectWithDeviceId:(NSString *)deviceId completion:(void (^)(MBOObject *object, MBOError *error))completion;

- (void)deleteObjectWithObjectId:(NSString *)objectId completion:(void (^)(MBOError *error))completion;
- (void)deleteObjectWithDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion;


/// Sensor data

- (void)sendSample:(MBOSample *)sample toPublicSensorName:(NSString *)sensorName withObjectId:(NSString *)objectId completion:(void (^) (MBOError *error))completion;
- (void)sendSample:(MBOSample *)sample toPublicSensorName:(NSString *)sensorName withDeviceId:(NSString *)deviceId completion:(void (^) (MBOError *error))completion;

- (void)sendSample:(MBOSample *)sample forObjectId:(NSString *)objectId completion:(void (^) (MBOError *error))completion;
- (void)sendSample:(MBOSample *)sample forDeviceId:(NSString *)deviceId completion:(void (^) (MBOError *error))completion;

- (void)fetchLastSampleOfObjectId:(NSString *)objectId sensorName:(NSString *)sensorName completion:(void (^)(MBOSample *sample, MBOError *error))completion;
- (void)fetchLastSampleOfDeviceId:(NSString *)deviceId sensorName:(NSString *)sensorName completion:(void (^)(MBOSample *sample, MBOError *error))completion;

/// Tokens
- (BOOL)isUserConnected;

- (void)logInWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(MBOError *error))completion oauthErrorCompletion:(void (^) (MBOError *error))oauthErrorCompletion;

- (void)logOut;

- (void)resetPasswordForUsername:(NSString *)username completion:(void (^)(MBOError *error))completion;

- (void)confirmResetPasswordForUsername:(NSString *)username newPassword:(NSString *)newPassword token:(NSString *)token completion:(void (^)(MBOError *error))completion;

- (void)confirmEmailForUsername:(NSString *)username password:(NSString *)password token:(NSString *)token completion:(void (^) (MBOError *error))completion;

@end
