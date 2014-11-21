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

typedef NS_ENUM(NSUInteger, MBOErrorCode)
{
    MBOErrorCodeInvalidDataReceived = 1000,
    MBOErrorCodeInvalidParameter,
    MBOErrorCodeGetNewCreatedObjectError,
    MBOErrorCodeWillBeRetryLaterAutomatically
};

@interface mnubo : NSObject

@property(nonatomic) BOOL useSandbox;
@property(nonatomic) NSTimeInterval sensorDataRetryInterval; // Default value: 30 seconds
@property(nonatomic) BOOL disableSensorDataInternalRetry;

- (instancetype)initWithAccountName:(NSString *)accountName
                          namespace:(NSString *)namespace
              readAccessConsumerKey:(NSString *)readAccessConsumerKey
           readAccessConsumerSecret:(NSString *)readAccessConsumerSecret
             writeAccessConsumerKey:(NSString *)writeAccessConsumerKey
          writeAccessConsumerSecret:(NSString *)writeAccessConsumerSecret;

/// User management
- (void)createUser:(MBOUser *)user updateIfAlreadyExist:(BOOL)updateIfAlreadyExist completion:(void (^)(MBOError *error))completion;

- (void)updateUser:(MBOUser *)user completion:(void (^)(MBOError *error))completion;

- (void)getUserWithUsername:(NSString *)username completion:(void (^)(MBOUser *user, MBOError *error))completion;

- (void)deleteUserWithUsername:(NSString *)username completion:(void (^)(MBOError *error))completion;


/// Object management
- (void)createObject:(MBOObject *)object updateIfAlreadyExist:(BOOL)updateIfAlreadyExist completion:(void (^)(MBOObject *newlyCreatedObject, MBOError *error))completion;

- (void)updateObject:(MBOObject *)object completion:(void (^)(MBOError *error))completion;

- (void)getObjectWithObjectId:(NSString *)objectId completion:(void (^)(MBOObject *object, MBOError *error))completion;
- (void)getObjectWithDeviceId:(NSString *)deviceId completion:(void (^)(MBOObject *object, MBOError *error))completion;

- (void)deleteObjectWithObjectId:(NSString *)objectId completion:(void (^)(MBOError *error))completion;
- (void)deleteObjectWithDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion;


/// Sensor data
- (void)sendSensorData:(NSArray *)sensorDatas forObjectId:(NSString *)objectId completion:(void (^)(MBOError *error))completion;
- (void)sendSensorData:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData forObjectId:(NSString *)objectId completion:(void (^)(MBOError *error))completion;

- (void)sendSensorData:(NSArray *)sensorDatas forDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion;
- (void)sendSensorData:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData forDeviceId:(NSString *)deviceId completion:(void (^)(MBOError *error))completion;

- (void)fetchLastSensorDataOfObjectId:(NSString *)objectId sensorDefinition:(MBOSensorDefinition *)sensorDefinition completion:(void (^)(MBOSensorData *sensorData, MBOError *error))completion;
- (void)fetchLastSensorDataOfDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition completion:(void (^)(MBOSensorData *sensorData, MBOError *error))completion;

- (void)fetchSensorDatasOfObjectId:(NSString *)objectId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate completion:(void (^)(NSArray *sensorDatas, MBOError *error))completion;
- (void)fetchSensorDatasOfDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate completion:(void (^)(NSArray *sensorDatas, MBOError *error))completion;

- (void)fetchSensorDataCountOfObjectId:(NSString *)objectId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate completion:(void (^)(NSUInteger count, MBOError *error))completion;
- (void)fetchSensorDataCountOfDeviceId:(NSString *)deviceId sensorDefinition:(MBOSensorDefinition *)sensorDefinition fromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate completion:(void (^)(NSUInteger count, MBOError *error))completion;


@end
