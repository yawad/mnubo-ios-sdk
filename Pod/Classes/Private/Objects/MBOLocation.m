//
//  MBOLocation.m
//  SensorLogger
//
//  Created by Dominic Plouffe on 2014-07-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOLocation.h"
#import "MBOLocation+Private.h"
#import "MBOMacros.h"

@implementation MBOLocation

- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude elevation:(double)elevation
{
    self = [super init];
    
    if (self)
    {
        _latitude = @(latitude);
        _longitude = @(longitude);
        _elevation = @(elevation);
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        _latitude = [aDecoder decodeObjectForKey:@"latitude"];
        _longitude = [aDecoder decodeObjectForKey:@"longitude"];
        _elevation = [aDecoder decodeObjectForKey:@"elevation"];
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    if (self)
    {
        NSString *latitudeStringValue = dictionary[@"latitude"];
        if ([latitudeStringValue isKindOfClass:[NSString class]])
        {
            _latitude = @([latitudeStringValue doubleValue]);
        }
        
        NSString *longitudeStringValue = dictionary[@"longitude"];
        if ([longitudeStringValue isKindOfClass:[NSString class]])
        {
            _longitude = @([longitudeStringValue doubleValue]);
        }
        
        NSString *elevationStringValue = dictionary[@"elevation"];
        if ([elevationStringValue isKindOfClass:[NSString class]])
        {
            _elevation = @([elevationStringValue doubleValue]);
        }
    }
    
    return self;
}

+ (instancetype)locationWithLatitude:(double)latitude longitude:(double)longitude elevation:(double)elevation
{
    return [[[self class] alloc] initWithLatitude:latitude longitude:longitude elevation:elevation];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_latitude forKey:@"latitude"];
    [aCoder encodeObject:_longitude forKey:@"longitude"];
    [aCoder encodeObject:_elevation forKey:@"elevation"];
}

- (id)copyWithZone:(NSZone *)zone
{
    MBOLocation *copy = [[MBOLocation alloc] init];
    copy.latitude = _latitude;
    copy.longitude = _longitude;
    copy.elevation = _elevation;
    return copy;
}

- (BOOL)isEqual:(MBOLocation *)otherLocation
{
    if (![otherLocation isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqualToNumber(_latitude, otherLocation.latitude) &&
    IsEqualToNumber(_longitude, otherLocation.longitude) &&
    IsEqualToNumber(_elevation, otherLocation.elevation);
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_latitude hash];
    hash += [_longitude hash];
    hash += [_elevation hash];
    return hash;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    SafeSetValueForKey(dictionary, @"latitude", [_latitude stringValue]);
    SafeSetValueForKey(dictionary, @"longitude", [_longitude stringValue]);
    SafeSetValueForKey(dictionary, @"elevation", [_elevation stringValue]);
    
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
