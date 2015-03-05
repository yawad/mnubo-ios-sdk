//
//  MBOSample.h
//  ConnecteDeviceExample
//
//  Created by Guillaume on 2015-02-26.
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBOSample : NSObject

- (instancetype)init;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (void)addSensorWithName:(NSString *)name andDictionary:(NSDictionary *)sensorDictionary;
- (NSDictionary *)toDictionary;

@end
