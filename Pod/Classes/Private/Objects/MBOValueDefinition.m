//
//  MBOSensorValueDefinition.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-10.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOValueDefinition.h"
#import "NSDictionary+mnubo.h"
#import "MBOMacros.h"
#import "MBOValueDefinition+Private.h"

@interface MBOValueDefinition ()

@property(nonatomic, readwrite, copy) NSString *name;
@property(nonatomic, readwrite) MBODataType type;

@end

@implementation MBOValueDefinition

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *dataType = [dictionary stringForKey:@"datatype"];
    if (!dataType)
    {
        dataType = [dictionary stringForKey:@"type"];
    }
    
    if (!dataType)
    {
        dataType = @"string";
    }

    NSString *name = [dictionary stringForKey:@"name"];

    return [self initWithDataType:dataType name:name];
}

- (instancetype)initWithDataType:(NSString *)dataType name:(NSString *)name
{
    self = [super init];
    if(self)
    {
        _type = [self dataTypeFromString:dataType];
        _name = name;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _type = [aDecoder decodeIntegerForKey:@"type"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeInteger:_type forKey:@"type"];
}

- (id)copyWithZone:(NSZone *)zone
{
    MBOValueDefinition *copy = [[MBOValueDefinition alloc] init];    
    copy.name = _name;
    copy.type = _type;
    return copy;
}

- (BOOL)isEqual:(MBOValueDefinition *)otherSensorValueDefinition
{
    if (![otherSensorValueDefinition isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqualToString(_name, otherSensorValueDefinition.name) &&
    _type == otherSensorValueDefinition.type;
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_name hash];
    hash += _type;
    return hash;
}

- (NSString *)stringDataType
{
    if (_type == MBODataTypeFloat)
    {
        return @"float";
    }
    else if (_type == MBODataTypeInteger)
    {
        return @"int";
    }
    else if (_type == MBODataTypeDate)
    {
        return @"date";
    }
    else if (_type == MBODataTypeUUID)
    {
        return @"uuid";
    }
    else if (_type == MBODataTypeString)
    {
        return @"string";
    }
}

//------------------------------------------------------------------------------
#pragma mark Private Methods
//------------------------------------------------------------------------------

- (MBODataType)dataTypeFromString:(NSString *)dataTypeString
{
    if([dataTypeString isEqualToString:@"float"])
    {
        return  MBODataTypeFloat;
    }
    else if([dataTypeString isEqualToString:@"int"])
    {
        return  MBODataTypeInteger;
    }
    else if([dataTypeString isEqualToString:@"date"])
    {
        return  MBODataTypeDate;
    }
    else if([dataTypeString isEqualToString:@"uuid"])
    {
        return  MBODataTypeUUID;
    }
    else
    {
        return  MBODataTypeString;
    }
}

@end
