//
//  MBOLocation.m
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
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
        NSArray *coordinates = dictionary[@"geometry"][@"coordinates"];
        if (coordinates.count > 1) {
            NSNumber *latitudeValue = coordinates[1];
            NSNumber *longitudeValue = coordinates[0];
            
            if ([latitudeValue isKindOfClass:[NSNumber class]])
            {
                _latitude = latitudeValue;
            }
            if ([latitudeValue isKindOfClass:[NSNumber class]])
            {
                _longitude = longitudeValue;
            }
            if (coordinates.count > 2)
            {
                NSNumber *elevationValue = coordinates[2];
                if ([latitudeValue isKindOfClass:[NSNumber class]])
                {
                    _elevation = elevationValue;
                }
            }
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
    NSMutableDictionary *registrationLocationDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *geometryDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *propertiesDictionary = [NSMutableDictionary dictionary];
    
    SafeSetValueForKey(geometryDictionary, @"type", @"Point");
    
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    if (_longitude)
        [coordinates addObject:_longitude];
    
    if (_latitude)
        [coordinates addObject:_latitude];
    
    if (_elevation)
        [coordinates addObject:_elevation];
    
    if (coordinates.count == 0)
        return @{};

    SafeSetValueForKey(geometryDictionary, @"coordinates", coordinates);
    SafeSetValueForKey(propertiesDictionary, @"elevation", _elevation);
    
    SafeSetValueForKey(registrationLocationDictionary, @"type", @"Feature");
    SafeSetValueForKey(registrationLocationDictionary, @"geometry", geometryDictionary)
    //  SafeSetValueForKey(registrationLocationDictionary, @"properties", propertiesDictionary)
    
    
    
    return [NSDictionary dictionaryWithDictionary:registrationLocationDictionary];
}

@end
