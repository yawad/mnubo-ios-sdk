//
//  MBOObject.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBOSensorDefinition;
@class MBOAttribute;

@interface MBOObject : NSObject <NSCopying, NSCoding>

/// Read only field
@property(nonatomic, readonly, copy) NSString *objectId;
@property(nonatomic, readonly, copy) NSArray *sensorsDefinition;

/// Mandatory fields
@property(nonatomic, copy) NSString *objectModelName;
@property(nonatomic) BOOL activate;

/// Optional fields
@property(nonatomic, copy) NSString *deviceId;
@property(nonatomic, copy) NSString *ownerUsername;

@property(nonatomic, readonly) NSArray *attributes;

@property(nonatomic) double latitude;
@property(nonatomic) double longitude;
@property(nonatomic) double elevation;

@property(nonatomic, copy) NSDate *registrationDate;

@property(nonatomic, copy) NSString *collectionId;

- (MBOSensorDefinition *)getSensorDefinitionOfSensorName:(NSString *)sensorName;

- (NSDictionary *)toDictionary;

- (void)setAttributes:(NSArray *)attributes;

- (void)addAttribute:(MBOAttribute *)attribute;
- (void)insertAttribute:(MBOAttribute *)attribute atIndex:(NSInteger)index;

- (void)removeAttribute:(MBOAttribute *)attribute;
- (void)removeAttributeAtIndex:(NSInteger)index;
- (void)removeAllAttributes;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
