//
//  MBOUser.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBOAttribute;

@interface MBOUser : NSObject <NSCopying, NSCoding>

@property(nonatomic, readonly, copy) NSString *userId;
@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *firstName;
@property(nonatomic, copy) NSString *lastName;
@property(nonatomic, copy) NSDate *registrationDate;
@property(nonatomic, readonly, copy) NSArray *attributes;

- (void)addAttribute:(MBOAttribute *)attribute;
- (void)insertAttribute:(MBOAttribute *)attribute atIndex:(NSInteger)index;

- (void)removeAttribute:(MBOAttribute *)attribute;
- (void)removeAttributeAtIndex:(NSInteger)index;
- (void)removeAllAttributes;

@end
