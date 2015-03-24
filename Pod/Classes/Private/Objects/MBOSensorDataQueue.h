//
//  MBOSensorDataQueue.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

@class mnubo;
@class MBOCommonSensorData;
@class MBOSample;

@interface MBOSensorDataQueue : NSObject

- (instancetype)initWithRetryInterval:(NSTimeInterval)retryInterval mnuboSDK:(mnubo *)mnuboSDK;

- (void)setRetryInterval:(NSTimeInterval)retryInterval;

- (void)addSensorData:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData objectId:(NSString *)objectId deviceId:(NSString *)deviceId completion:(void (^)(NSString *queueIdentifiyer))completion;

- (void)addSample:(MBOSample *)sample objectId:(NSString *)objectId deviceId:(NSString *)deviceId completion:(void (^)(NSString *queueIdentifiyer))completion;

- (void)removeSensorDataWithIdentifier:(NSString *)queueIdentifiyer;

- (void)moveToRetryQueueSensorDataWithIdentifier:(NSString *)queueIdentifiyer;

@end
