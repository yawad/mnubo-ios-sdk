//
//  MBOSensorData.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOSensorData.h"
#import "MBOSensorDefinition.h"
#import "MBODateHelper.h"
#import "NSDictionary+mnubo.h"
#import "MBOValueDefinition.h"
#import "MBODateHelper.h"
#import "MBOValueContainer.h"
#import "MBOValueContainer+Private.h"
#import "MBOValueDefinition+Private.h"
#import "MBOMacros.h"
#import "MBOLocation.h"
#import "MBOCommonSensorData.h"
#import "MBOLocation+Private.h"

@interface MBOSensorData()

@property(nonatomic, readwrite, copy) NSString *name;
@property(nonatomic, readwrite, copy) NSDate *timeStamps;
@property(nonatomic, copy) MBOLocation *location;
@property(nonatomic) BOOL isReadOnly;
@property(nonatomic, copy) NSMutableArray *sensorValues;
@property(nonatomic, readonly) BOOL isCommonSensor;
@property(nonatomic, copy) NSMutableDictionary *commonValues;

@end

@implementation MBOSensorData

- (instancetype)init
{
    NSAssert(NO, @"Init unavailable");
    return nil;
}

- (instancetype)initForCommonSensor
{
    self = [super init];
    if(self)
    {
        _isReadOnly = NO;
        _commonValues = [NSMutableDictionary dictionary];
    }

    return self;
}

- (instancetype)initWithSensorDefinition:(MBOSensorDefinition *)sensorDefinition
{
    self = [super init];
    if(self)
    {
        _isReadOnly = NO;

        _sensorDefinition = [sensorDefinition copy];

        _sensorValues = [NSMutableArray array];
        
        _timeStamps = [NSDate date];
        
        _location = [[MBOLocation alloc] init];
        
        [_sensorDefinition.sensorValueDefinitions enumerateObjectsUsingBlock:^(MBOValueDefinition *sensorValueDefinition, NSUInteger idx, BOOL *stop)
        {
            MBOValueContainer *valueContainer = [[MBOValueContainer alloc] initWithValueDefinition:sensorValueDefinition];
            [_sensorValues addObject:valueContainer];
        }];
    }

    return self;
}

- (instancetype)initWithSensorDefinition:(MBOSensorDefinition *)sensorDefinition andDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self)
    {
        _isReadOnly = YES;

        _sensorDefinition = [sensorDefinition copy];

        _timeStamps = [MBODateHelper dateFromMnuboString:[dictionary stringForKey:@"timestamp"]];
        
        _location = [[MBOLocation alloc] initWithDictionary:dictionary];

        _sensorValues = [NSMutableArray array];
        NSDictionary *values = [dictionary dictionaryForKey:@"values"];
        [values enumerateKeysAndObjectsUsingBlock:^(NSString *valueName, id value, BOOL *stop)
        {
            MBOValueContainer *valueContainer = [[MBOValueContainer alloc] initWithValueDefinition:
                                  [sensorDefinition sensorValueDefinitionForName:valueName] valueString:value];
            [_sensorValues addObject:valueContainer];
        }];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        _sensorDefinition = [aDecoder decodeObjectForKey:@"sensorDefinition"];
        _name = [aDecoder decodeObjectForKey:@"name"];
        _timeStamps = [aDecoder decodeObjectForKey:@"timestamp"];
        _location = [aDecoder decodeObjectForKey:@"location"];
        _isReadOnly = [aDecoder decodeBoolForKey:@"isReadOnly"];
        _sensorValues = [aDecoder decodeObjectForKey:@"sensorValues"];
        _commonValues = [aDecoder decodeObjectForKey:@"commonValues"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_sensorDefinition forKey:@"sensorDefinition"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_timeStamps forKey:@"timestamp"];
    [aCoder encodeObject:_location forKey:@"location"];
    [aCoder encodeBool:_isReadOnly forKey:@"isReadOnly"];
    [aCoder encodeObject:_sensorValues forKey:@"sensorValues"];
    [aCoder encodeObject:_commonValues forKey:@"commonValues"];
}

- (id)copyWithZone:(NSZone *)zone
{
    MBOSensorData *copy = [[MBOSensorData alloc] initWithSensorDefinition:_sensorDefinition];
    copy.name = _name;
    copy.timeStamps = _timeStamps;
    copy.location = _location;
    copy.isReadOnly = _isReadOnly;
    copy.sensorValues = _sensorValues;
    copy.commonValues = _commonValues;
    return copy;
}

- (BOOL)isEqual:(MBOSensorData *)otherSensorData
{
    if (![otherSensorData isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqual(_sensorDefinition, otherSensorData.sensorDefinition) &&
    IsEqualToString(_name, otherSensorData.name) &&
    IsEqualToDate(_timeStamps, otherSensorData.timeStamps) &&
    IsEqual(_location, otherSensorData.location) &&
    IsEqualToDictionary(_commonValues, otherSensorData.commonValues);
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_sensorDefinition hash];
    hash += [_name hash];
    hash += [_timeStamps hash];
    hash += [_location hash];
    hash += [_commonValues hash];
    return hash;
}

- (BOOL)isCommonSensor
{
    return _commonValues != nil;
}

//------------------------------------------------------------------------------
#pragma mark Genetal methods
//------------------------------------------------------------------------------

- (NSArray *)allSensorNames
{
    if(self.isCommonSensor)
    {
        return _commonValues.allKeys;
    }
    else
    {
        return [_sensorValues valueForKeyPath:@"definition.name"];
    }
}

- (id)valueForSensorValueName:(NSString *)sensorValueName
{
    if(self.isCommonSensor)
    {
        return _commonValues[sensorValueName];
    }
    else
    {
        return [self valueContainerWithSensorValueName:sensorValueName].value;
    }
}

//------------------------------------------------------------------------------
#pragma mark Editable methods
//------------------------------------------------------------------------------

- (void)setValue:(id)value forSensorValueName:(NSString *)sensorValueName
{
    if(self.isCommonSensor)
    {
        _commonValues[sensorValueName] = value;
    }
    else
    {
        NSAssert(_isReadOnly == NO, @"Can't change value of a read only Sensor data");
        NSAssert([self valueNameIsValid:sensorValueName], @"Invalid sensor value name ");
        MBOValueContainer *valueContainer = [self valueContainerWithSensorValueName:sensorValueName];
        valueContainer.value = value;
    }
}

- (void)updateTimestamp
{
    NSAssert(_isReadOnly == NO, @"Can't change value of a read only Sensor data");
    
    _timeStamps = [NSDate date];
}

- (double)latitude
{
    return [_location.latitude floatValue];
}

- (void)setLatitude:(double)latitude
{
    _location.latitude = @(latitude);
}

- (double)longitude
{
    return [_location.longitude floatValue];
}

- (void)setLongitude:(double)longitude
{
    _location.longitude = @(longitude);
}

- (double)elevation
{
    return [_location.elevation floatValue];
}

- (void)setElevation:(double)elevation
{
    _location.elevation = @(elevation);
}

//------------------------------------------------------------------------------
#pragma mark Private methods
//------------------------------------------------------------------------------

- (NSDictionary *)generateNameValueDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if(self.isCommonSensor)
    {
        [_commonValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop)
        {
            id valueForDictionary = nil;
            
            if([value isKindOfClass:[NSString class]])
            {
                valueForDictionary = value;
            }
            else if([value isKindOfClass:[NSDate class]])
            {
                valueForDictionary = [MBODateHelper mnuboStringFromDate:value];
            }
            else if([value isKindOfClass:[NSNumber class]])
            {
                valueForDictionary = value;
            }
            else if([value isKindOfClass:[NSUUID class]])
            {
                NSUUID *uuid = value;
                valueForDictionary = [uuid UUIDString];
            }
            else
            {
                NSLog(@"Invalid data class type: %@", [value class]);
            }

            if(valueForDictionary)
            {
                dictionary[key] = valueForDictionary;
            }
        }];
    }
    else
    {
        [_sensorValues enumerateObjectsUsingBlock:^(MBOValueContainer *valueContainer, NSUInteger idx, BOOL *stop)
        {
            if (valueContainer.value)
            {
                if([valueContainer.value isKindOfClass:[NSNumber class]])
                {
                    dictionary[valueContainer.definition.name] = valueContainer.value;
                }
                else
                {
                    dictionary[valueContainer.definition.name] = [valueContainer stringValue];
                }
            }
        }];
    }

    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (MBOValueContainer *)valueContainerWithSensorValueName:(NSString *)sensorName
{
    __block MBOValueContainer *returnValue = nil;
    [_sensorValues enumerateObjectsUsingBlock:^(MBOValueContainer *valueContainer, NSUInteger idx, BOOL *stop)
    {
        if ([valueContainer.definition.name isEqualToString:sensorName])
        {
            returnValue = valueContainer;
            *stop = YES;
        }
    }];
    return returnValue;
}

- (BOOL)valueNameIsValid:(NSString *)valueName
{
    return ([_sensorDefinition sensorValueDefinitionForName:valueName] != nil);
}

//------------------------------------------------------------------------------
#pragma mark Public static method
//------------------------------------------------------------------------------

+ (NSDictionary *)dictionaryFromSensorDatas:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData
{
    NSMutableArray *sensorDataDictionaries = [NSMutableArray arrayWithCapacity:sensorDatas.count];
    [sensorDatas enumerateObjectsUsingBlock:^(MBOSensorData *sensorData, NSUInteger idx, BOOL *stop)
    {
        [sensorDataDictionaries addObject:[sensorData toDictionary]];
    }];

    if(commonData)
    {
        return @{ @"common" : [commonData toDictionary],
                  @"samples" : sensorDataDictionaries };
    }
    else
    {
        return @{ @"samples" : sensorDataDictionaries };
    }
}

//------------------------------------------------------------------------------
#pragma mark Helper methods
//------------------------------------------------------------------------------

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if(!self.isCommonSensor)
    {
        SafeSetValueForKey(dictionary, @"name", _sensorDefinition.name);
    }
    SafeSetValueForKey(dictionary, @"value", [self generateNameValueDictionary]);
    SafeSetValueForKey(dictionary, @"timestamp", [MBODateHelper mnuboStringFromDate:_timeStamps]);
    SafeSetValueForKey(dictionary, @"latitude", [_location.latitude stringValue]);
    SafeSetValueForKey(dictionary, @"longitude", [_location.longitude stringValue]);
    SafeSetValueForKey(dictionary, @"elevation", [_location.elevation stringValue]);
    
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSString *)description
{
    __block NSString *description = [super description];
    description = [description stringByAppendingString:@" "];
    [_sensorValues enumerateObjectsUsingBlock:^(MBOValueContainer *valueContainer, NSUInteger idx, BOOL *stop)
    {
        description = [description stringByAppendingFormat:@"%@", [valueContainer description]];
    }];

    return description;
}

@end
