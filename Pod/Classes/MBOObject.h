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

@property(nonatomic, readonly) NSArray *attributes;

@property(nonatomic) double latitude;
@property(nonatomic) double longitude;
@property(nonatomic) double elevation;

@property(nonatomic, copy) NSDate *registrationDate;

@property(nonatomic, copy) NSArray *collectionId;


- (NSDictionary *)toDictionary;

- (void)setAttributes:(NSArray *)attributes;

- (void)addAttribute:(MBOAttribute *)attribute;
- (void)insertAttribute:(MBOAttribute *)attribute atIndex:(NSInteger)index;

- (void)removeAttribute:(MBOAttribute *)attribute;
- (void)removeAttributeAtIndex:(NSInteger)index;
- (void)removeAllAttributes;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
