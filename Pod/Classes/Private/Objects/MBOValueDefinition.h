//
//  MBOSensorValueDefinition.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-10.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MBODataType)
{
    MBODataTypeString,
    MBODataTypeFloat,
    MBODataTypeInteger,
    MBODataTypeDate,
    MBODataTypeUUID
};

@interface MBOValueDefinition : NSObject <NSCopying, NSCoding>

@property(nonatomic, readonly, copy) NSString *name;
@property(nonatomic, readonly) MBODataType type;

- (NSString *)stringDataType;

@end
