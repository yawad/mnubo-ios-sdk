//
//  MBOSensorValueDefinition.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
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
