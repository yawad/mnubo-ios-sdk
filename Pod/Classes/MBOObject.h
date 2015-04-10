//
//  MBOObject.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBOAttribute;
@class MBOLocation;

@interface MBOObject : NSObject <NSCopying, NSCoding>

/// Read only field
@property(nonatomic, readonly, copy) NSString *objectId;

/// Mandatory fields
@property(nonatomic, copy) NSString *objectModelName;

/// Optional fields
@property(nonatomic, copy) NSString *deviceId;
@property(nonatomic, copy) NSString *ownerUsername;

@property(nonatomic, readonly) NSDictionary *attributes;

@property(nonatomic) double latitude;
@property(nonatomic) double longitude;
@property(nonatomic) double elevation;

@property(nonatomic, copy) NSDate *registrationDate;

@property(nonatomic, copy) NSArray *collections;


- (NSDictionary *)toDictionary;

- (void)setAttributes:(NSDictionary *)attributes;
- (void)addAttribute:(NSString *)key value:(id)value;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
