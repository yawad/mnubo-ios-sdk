//
//  MBOAttribute.m
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOAttribute.h"
#import "MBOAttribute+Private.h"
#import "MBOMacros.h"
#import "MBOValueContainer+Private.h"
#import "MBOValueDefinition+Private.h"

@interface MBOAttribute ()
@property (nonatomic, copy) MBOValueContainer *valueContainer;
@property (nonatomic, readwrite) NSString *category;
@end

@implementation MBOAttribute

- (instancetype)initWithName:(NSString *)name category:(NSString *)category stringValue:(NSString *)stringValue
{
    return [self initWithValueName:name category:category type:@"string" value:stringValue];
}

- (instancetype)initWithName:(NSString *)name category:(NSString *)category floatValue:(CGFloat)floatValue
{
    return [self initWithValueName:name category:category type:@"float" value:@(floatValue)];
}

- (instancetype)initWithName:(NSString *)name category:(NSString *)category dateValue:(NSDate *)dateValue
{
    return [self initWithValueName:name category:category type:@"date" value:dateValue];
}

- (instancetype)initWithName:(NSString *)name category:(NSString *)category uuidValue:(NSUUID *)uuidValue
{
    return [self initWithValueName:name category:category type:@"uuid" value:[uuidValue UUIDString]];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    if (self)
    {
        _valueContainer = [[MBOValueContainer alloc] initWithValueDefinition:
                           [[MBOValueDefinition alloc] initWithDictionary:dictionary] valueString:dictionary[@"value"]];
        _category = dictionary[@"category"];
    }

    return self;
}

- (instancetype)initWithValueName:(NSString *)valueName category:(NSString *)category type:(NSString *)type value:(id)value
{
    self = [super init];
    
    if (self)
    {
        _category = category;
        _valueContainer = [[MBOValueContainer alloc] initWithValueDefinition:
                           [[MBOValueDefinition alloc] initWithDataType:type name:valueName] value:value];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        _valueContainer = [aDecoder decodeObjectForKey:@"valueContainer"];
        _category = [aDecoder decodeObjectForKey:@"category"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_valueContainer forKey:@"valueContainer"];
    [aCoder encodeObject:_category forKey:@"category"];
}

- (id)copyWithZone:(NSZone *)zone
{
    MBOAttribute *copy = [[MBOAttribute alloc] init];
    copy.valueContainer = _valueContainer;
    copy.category = _category;
    return copy;
}

- (BOOL)isEqual:(MBOAttribute *)otherAttribute
{
    if (![otherAttribute isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqual(_valueContainer, otherAttribute.valueContainer) && [_category isEqualToString:otherAttribute.category];
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_valueContainer hash];
    hash += [_category hash];
    return hash;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];

    SafeSetValueForKey(attributeDictionary, @"category", _category);
    SafeSetValueForKey(attributeDictionary, @"name", _valueContainer.definition.name);
    SafeSetValueForKey(attributeDictionary, @"value", [_valueContainer stringValue]);

    return [NSDictionary dictionaryWithDictionary:attributeDictionary];
}

- (id)value
{
    return _valueContainer.value;
}

- (NSString *)name
{
    return _valueContainer.definition.name;
}

@end
