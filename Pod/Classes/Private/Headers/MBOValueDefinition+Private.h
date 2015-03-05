//
//  MBOSensorValueDefinition+Private.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-27.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOValueDefinition.h"

@interface MBOValueDefinition(Private)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithDataType:(NSString *)dataType name:(NSString *)name;

@end
