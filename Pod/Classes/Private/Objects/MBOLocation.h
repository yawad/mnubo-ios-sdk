//
//  MBOLocation.h
//  SensorLogger
//
//  Created by Dominic Plouffe on 2014-07-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBOLocation : NSObject <NSCopying, NSCoding>

@property(nonatomic) NSNumber *latitude;
@property(nonatomic) NSNumber *longitude;
@property(nonatomic) NSNumber *elevation;

- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude elevation:(double)elevation;;
+ (instancetype)locationWithLatitude:(double)latitude longitude:(double)longitude elevation:(double)elevation;

@end
