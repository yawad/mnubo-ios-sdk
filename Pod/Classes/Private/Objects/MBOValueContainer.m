//
//  MBOValueContainer.m
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOValueContainer.h"
#import "MBOValueDefinition.h"
#import "MBOValueContainer+Private.h"
#import "MBOValueDefinition+Private.h"
#import "MBODateHelper.h"
#import "MBOMacros.h"

@implementation MBOValueContainer

- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition
{
    return [self initWithValueDefinition:definition value:nil];
}

- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition value:(id)value
{
    self = [super init];
    
    if (self)
    {
        _definition = [definition copy];
        self.value = value;
    }
    
    return self;
}

- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition valueString:(NSString *)valueString
{
    return [self initWithValueDefinition:definition value:
            [MBOValueContainer valueFromValueString:valueString datatype:definition.type]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        _definition = [aDecoder decodeObjectForKey:@"definition"];
        _value = [aDecoder decodeObjectForKey:@"value"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_definition forKey:@"definition"];
    [aCoder encodeObject:_value forKey:@"value"];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[MBOValueContainer alloc] initWithValueDefinition:_definition value:_value];
}

- (BOOL)isEqual:(MBOValueContainer *)otherValueContainer
{
    if (![otherValueContainer isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqual(_definition, otherValueContainer.definition) && IsEqual(_value, otherValueContainer.value);
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_definition hash];
    hash += [_value hash];
    return hash;
}

- (void)setValue:(id)value
{
    if (_value != value)
    {
        NSAssert([MBOValueContainer isValueValid:value forDataType:_definition.type], @"Invalid value for datatype");
        _value = value;
    }
}

- (NSString *)stringDataType
{
    return [_definition stringDataType];
}

- (NSString *)stringValue
{
    switch (_definition.type)
    {
        case MBODataTypeString:
        case MBODataTypeUUID:
            return _value;
        case MBODataTypeFloat:
        case MBODataTypeInteger:
            return [_value stringValue];
        case MBODataTypeDate:
            return [MBODateHelper mnuboStringFromDate:_value];
            return nil;
    }
}

//------------------------------------------------------------------------------
#pragma mark Private Methods
//------------------------------------------------------------------------------

+ (BOOL)isValueValid:(id)value forDataType:(MBODataType)dataType
{
    switch (dataType)
    {
        case MBODataTypeString:
        case MBODataTypeUUID:
            return [value isKindOfClass:[NSString class]];
        case MBODataTypeFloat:
        case MBODataTypeInteger:
            return [value isKindOfClass:[NSNumber class]];
        case MBODataTypeDate:
            return [value isKindOfClass:[NSDate class]];
    };
}

+ (id)valueFromValueString:(NSString *)valueString datatype:(MBODataType)datatype
{
    switch (datatype)
    {
        case MBODataTypeString:
        case MBODataTypeUUID:
            return valueString;
        case MBODataTypeFloat:
            return @([valueString doubleValue]);
        case MBODataTypeInteger:
            return @([valueString integerValue]);
        case MBODataTypeDate:
            return [MBODateHelper dateFromMnuboString:valueString];
    }
}

@end
