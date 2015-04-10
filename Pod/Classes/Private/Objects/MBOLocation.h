//
//  MBOLocation.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBOLocation : NSObject <NSCopying, NSCoding>

@property(nonatomic) NSNumber *latitude;
@property(nonatomic) NSNumber *longitude;
@property(nonatomic) NSNumber *elevation;

- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude elevation:(double)elevation;
+ (instancetype)locationWithLatitude:(double)latitude longitude:(double)longitude elevation:(double)elevation;

@end
