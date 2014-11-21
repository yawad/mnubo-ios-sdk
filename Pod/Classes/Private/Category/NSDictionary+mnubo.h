//
//  NSDictionary+mnubo.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-10.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (mnubo)

- (NSArray *)arrayForKey:(id)key;
- (NSDictionary *)dictionaryForKey:(id)key;
- (NSString *)stringForKey:(id)key;
- (NSNumber *)numberForKey:(id)key;

@end
