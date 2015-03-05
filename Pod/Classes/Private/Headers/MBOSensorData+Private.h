//
//  MBOSensorData+Private.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-27.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOSensorData.h"

@interface MBOSensorData (Private)

@property(nonatomic) BOOL isReadOnly;
@property(nonatomic, copy) NSMutableArray *sensorValues;
@property(nonatomic, copy) MBOLocation *location;
@property(nonatomic, copy) NSMutableDictionary *commonValues;

- (instancetype)initForCommonSensor;
- (instancetype)initWithSensorDefinition:(MBOSensorDefinition *)sensorDefinition andDictionary:(NSDictionary *)dictionary;

+ (NSDictionary *)dictionaryFromSensorDatas:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData;

@end
