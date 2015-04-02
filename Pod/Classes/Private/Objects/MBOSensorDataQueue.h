//
//  MBOSensorDataQueue.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class mnubo;
@class MBOCommonSensorData;
@class MBOSample;

@interface MBOSensorDataQueue : NSObject

- (instancetype)initWithRetryInterval:(NSTimeInterval)retryInterval mnuboSDK:(mnubo *)mnuboSDK;

- (void)setRetryInterval:(NSTimeInterval)retryInterval;

- (void)addSample:(MBOSample *)sample objectId:(NSString *)objectId deviceId:(NSString *)deviceId publicSensorName:(NSString *)publicSensorName completion:(void (^)(NSString *queueIdentifiyer))completion;

- (void)removeSensorDataWithIdentifier:(NSString *)queueIdentifiyer;

- (void)moveToRetryQueueSensorDataWithIdentifier:(NSString *)queueIdentifiyer;

@end
