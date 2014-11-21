//
//  NSDictionary+mnubo.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-10.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "NSDictionary+mnubo.h"

@implementation NSDictionary (mnubo)

- (NSArray *)arrayForKey:(id)key
{
    NSArray *tmpArray = [self valueForKeyPath:key];
    return [tmpArray isKindOfClass:[NSArray class]] ? tmpArray : nil;
}

- (NSDictionary *)dictionaryForKey:(id)key
{
    NSDictionary *tmpDict = [self valueForKeyPath:key];
    return [tmpDict isKindOfClass:[NSDictionary class]] ? tmpDict : nil;
}

- (NSString *)stringForKey:(id)key
{
    id object = [self valueForKeyPath:key];
    if([object isKindOfClass:[NSString class]])
    {
        return object;
    }
    else if([object isKindOfClass:[NSNumber class]])
    {
        return [object stringValue];
    }
    return nil;
}

- (NSNumber *)numberForKey:(id)key
{
    id object = [self valueForKeyPath:key];
    if([object isKindOfClass:[NSNumber class]])
    {
        return object;
    }

    return nil;
}

@end
