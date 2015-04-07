//
//  MBOSample.m
//  ConnecteDeviceExample
//
//  Created by Guillaume on 2015-02-26.
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOSample.h"
#import "MBOMacros.h"
#import "MBODateHelper.h"
#import "MBOLocation+Private.h"

@interface MBOSample()

@property(nonatomic, copy) NSMutableDictionary *commonValues;
@property(nonatomic, copy) MBOLocation *location;

@end


@implementation MBOSample

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _location = [[MBOLocation alloc] init];
        _attributes = [NSMutableDictionary dictionary];
        _commonValues = [[NSMutableDictionary alloc] init];
        _registrationDate = [NSDate date];
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self)
    {
        _registrationDate = [NSDate date];
        _attributes = [NSMutableDictionary dictionary];
        _location = [[MBOLocation alloc] init];
        _commonValues = [[NSMutableDictionary alloc] initWithDictionary:dictionary];

    }
    
    return self;
}

- (void)addSensorWithName:(NSString *)name andDictionary:(NSDictionary *)sensorDictionary
{
    [_attributes setValue:sensorDictionary forKey:name];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        _commonValues = [aDecoder decodeObjectForKey:@"commonValues"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_commonValues forKey:@"commonValues"];
}

- (id)copyWithZone:(NSZone *)zone
{
    MBOSample *copy = [[MBOSample alloc] initWithDictionary:_commonValues];
    return copy;
}

- (BOOL)isEqual:(MBOSample *)otherSample
{
    if (![otherSample isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqualToDictionary(_commonValues, otherSample.commonValues);
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_commonValues hash];
    return hash;
}

//------------------------------------------------------------------------------
#pragma mark Public method
//------------------------------------------------------------------------------

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *_dictionary = [[NSMutableDictionary alloc] init];
    
    SafeSetValueForKey(_dictionary, @"timestamp", [MBODateHelper mnuboStringFromDate:_registrationDate]);
    SafeSetValueForKey(_dictionary, @"name", _name);
    
    
    for (NSString *key in _attributes)
    {
        SafeSetValueForKey(_dictionary, key, [_attributes valueForKey:key]);
    }

    
    if (_location.longitude && _location.latitude)
    {
        [_dictionary setObject:[_location toDictionary] forKey:@"registration_location"];
    }
    
    return _dictionary;
}

- (double)latitude
{
    return [_location.latitude doubleValue];
}

- (void)setLatitude:(double)latitude
{
    _location.latitude = @(latitude);
}

- (double)longitude
{
    return [_location.longitude doubleValue];
}

- (void)setLongitude:(double)longitude
{
    _location.longitude = @(longitude);
}

- (double)elevation
{
    return [_location.elevation doubleValue];
}

- (void)setElevation:(double)elevation
{
    _location.elevation = @(elevation);
}

@end
