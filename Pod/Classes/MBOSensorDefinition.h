//
//  MBOSensorDefinition.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-10.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBOValueDefinition;

@interface MBOSensorDefinition : NSObject <NSCopying, NSCoding>

@property(nonatomic, readonly, copy) NSString *name;
@property(nonatomic, readonly, copy) NSString *templateName;
@property(nonatomic, readonly, copy) NSString *templateDescription;

@property(nonatomic, readonly, copy) NSArray *sensorValueDefinitions;

- (NSArray *)allSensorValueNames;

- (MBOValueDefinition *)sensorValueDefinitionForName:(NSString *)name;

@end
