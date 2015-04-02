//
//  MBOSensorValueDefinition+Private.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOValueDefinition.h"

@interface MBOValueDefinition(Private)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithDataType:(NSString *)dataType name:(NSString *)name;

@end
