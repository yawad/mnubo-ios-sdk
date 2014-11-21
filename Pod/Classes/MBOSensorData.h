//
//  MBOSensorData.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBOSensorDefinition;
@class MBOLocation;

@interface MBOSensorData : NSObject <NSCopying, NSCoding>

@property(nonatomic, readonly) MBOSensorDefinition *sensorDefinition;

@property(nonatomic, readonly, copy) NSString *name;

@property(nonatomic, readonly, copy) NSDate *timeStamps;

@property(nonatomic) double latitude;
@property(nonatomic) double longitude;
@property(nonatomic) double elevation;

- (instancetype)initWithSensorDefinition:(MBOSensorDefinition *)sensorDefinition;

- (NSArray *)allSensorNames;
- (id)valueForSensorValueName:(NSString *)sensorValueName;

- (void)updateTimestamp; /// if not called the timestamp will be generated at the construction of the object

- (void)setValue:(id)value forSensorValueName:(NSString *)sensorValueName;

@end
