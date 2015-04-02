//
//  MBOUser.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBOAttribute;

@interface MBOUser : NSObject <NSCopying, NSCoding>

@property(nonatomic, readonly, copy) NSString *userId;
@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *confirmedPassword;
@property(nonatomic, copy) NSString *firstName;
@property(nonatomic, copy) NSString *lastName;
@property(nonatomic, copy) NSDate *registrationDate;
@property(nonatomic, readonly, copy) NSArray *attributes;
@property (nonatomic, copy) NSArray *collectionIds;
@property (nonatomic, copy) NSArray *groupIds;

- (void)addAttribute:(MBOAttribute *)attribute;
- (void)insertAttribute:(MBOAttribute *)attribute atIndex:(NSInteger)index;

- (void)removeAttribute:(MBOAttribute *)attribute;
- (void)removeAttributeAtIndex:(NSInteger)index;
- (void)removeAllAttributes;

- (NSDictionary *)toDictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
