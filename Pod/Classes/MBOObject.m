//
//  MBOObject.m
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOObject.h"
#import "NSDictionary+mnubo.h"
#import "MBOMacros.h"
#import "MBOAttribute+Private.h"
#import "MBOLocation.h"
#import "MBOLocation+Private.h"
#import "MBODateHelper.h"

NSString const * kMBOObjectObjectIdKey = @"object_id";
NSString const * kMBOObjectDeviceIdKey = @"device_id";
NSString const * kMBOObjectModelNameKey = @"object_model";
NSString const * kMBOObjectActivateKey = @"activate";
NSString const * kMBOObjectOwnerKey = @"owner";
NSString const * kMBOObjectCollectionsKey = @"collections";

@interface MBOObject ()
{
    NSMutableDictionary *_innerAttributes;
}

@property(nonatomic, readwrite, copy) NSString *objectId;
@property(nonatomic, copy) MBOLocation *location;

@end

@implementation MBOObject

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _innerAttributes = [NSMutableDictionary dictionary];
        _location = [[MBOLocation alloc] init];
        _registrationDate = [NSDate date];
    }

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self init];
    if(self)
    {
        
        NSArray* attributes  = [dictionary objectForKey:@"attributes"];
        for (int i=0; i<attributes.count; i++)
        {
            [_innerAttributes setObject:[attributes[i] objectForKey:@"value"] forKey:[attributes[i] objectForKey:@"name"]];
        }
        
        _location = [[MBOLocation alloc] init];
        _registrationDate = [NSDate date];
        
        _objectId = [dictionary stringForKey:kMBOObjectObjectIdKey];
        _deviceId = [dictionary stringForKey:kMBOObjectDeviceIdKey];
        _objectModelName = [dictionary stringForKey:kMBOObjectModelNameKey];
        _ownerUsername = [dictionary stringForKey:kMBOObjectOwnerKey];
        
        
        
        _location = [[MBOLocation alloc] initWithDictionary:[dictionary dictionaryForKey:@"registration_location"]];
        if ([dictionary stringForKey:@"registration_date"])
        {
            _registrationDate = [MBODateHelper dateFromMnuboString:[dictionary stringForKey:@"registration_date"]];
        }

        _collections = [dictionary objectForKey:@"collections"];
        
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        _objectModelName = [aDecoder decodeObjectForKey:@"objectModelName"];
        _deviceId = [aDecoder decodeObjectForKey:@"deviceId"];
        _ownerUsername = [aDecoder decodeObjectForKey:@"ownerUsername"];
        _objectId = [aDecoder decodeObjectForKey:@"objectId"];
        _innerAttributes = [aDecoder decodeObjectForKey:@"attributes"];
        _location = [aDecoder decodeObjectForKey:@"location"];
        _registrationDate = [aDecoder decodeObjectForKey:@"registration_date"];
        _collections = [aDecoder decodeObjectForKey:@"collections"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_objectModelName forKey:@"objectModelName"];
    [aCoder encodeObject:_deviceId forKey:@"deviceId"];
    [aCoder encodeObject:_ownerUsername forKey:@"ownerUsername"];
    [aCoder encodeObject:_objectId forKey:@"objectId"];
    [aCoder encodeObject:_innerAttributes forKey:@"attributes"];
    [aCoder encodeObject:_location forKey:@"location"];
    [aCoder encodeObject:_registrationDate forKey:@"registration_date"];
    [aCoder encodeObject:_collections forKey:@"collections"];
}

- (id)copyWithZone:(NSZone *)zone
{
    MBOObject *copy = [[MBOObject alloc] init];
    
    copy.objectModelName = _objectModelName;
    copy.deviceId = _deviceId;
    copy.ownerUsername = _ownerUsername;
    copy.objectId = _objectId;
    copy.location = _location;
    copy.registrationDate = _registrationDate;
    copy.collections = _collections;

    
    return copy;
}

- (BOOL)isEqual:(MBOObject *)otherObject
{
    if (![otherObject isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqualToString(_objectModelName, otherObject.objectModelName) &&
    IsEqualToString(_deviceId, otherObject.deviceId) &&
    IsEqualToString(_ownerUsername, otherObject.ownerUsername) &&
    IsEqualToString(_objectId, otherObject.objectId) &&
    IsEqualToDictionary(_innerAttributes, otherObject.attributes) &&
    IsEqual(_location, otherObject.location) &&
    IsEqualToDate(_registrationDate, otherObject.registrationDate) &&
    IsEqualToArray(_collections, otherObject.collections);
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_objectModelName hash];
    hash += [_deviceId hash];
    hash += [_ownerUsername hash];
    hash += [_objectId hash];
    hash += [_innerAttributes hash];
    hash += [_location hash];
    hash += [_registrationDate hash];
    hash += [_collections hash];
    return hash;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *_dictionary = [[NSMutableDictionary alloc] init];

    
    if (_location.longitude && _location.latitude)
    {
        [_dictionary setObject:[_location toDictionary] forKey:@"registration_location"];
    }
        
    if(_deviceId.length)
    {
        [_dictionary setObject:_deviceId forKey:kMBOObjectDeviceIdKey];
    }
    
    if(_objectModelName.length)
    {
        [_dictionary setObject:_objectModelName forKey:kMBOObjectModelNameKey];
    }

    if(_ownerUsername.length)
    {
        [_dictionary setObject:_ownerUsername forKey:kMBOObjectOwnerKey];
    }


    if (_innerAttributes.count > 0)
        
    {
        NSMutableArray *attributesArray = [NSMutableArray array];
        for (NSString *key in _innerAttributes)
        {
            [attributesArray addObject:@{@"name": key, @"value": [_innerAttributes valueForKey:key]}];
        }
        
        
        [_dictionary setObject:attributesArray forKey:@"attributes"];
    }
    
    SafeSetValueForKey(_dictionary, @"registration_date", [MBODateHelper mnuboStringFromDate:_registrationDate]);

    if (_collections)
    {
        [_dictionary setObject:_collections forKey:kMBOObjectCollectionsKey];
    }

    return _dictionary;
}

- (void)setCollections:(NSArray *)collections
{
    _collections = collections;
}

- (void)setAttributes:(NSDictionary *)attributes
{
    _innerAttributes = [[NSMutableDictionary alloc] initWithDictionary:attributes];
}

- (NSDictionary *)attributes
{
    return [NSDictionary dictionaryWithDictionary:_innerAttributes];
}

- (void)addAttributes:(NSDictionary *)attributesDictionary
{
    for (NSString *key in attributesDictionary)
    {
        [_innerAttributes setObject:[attributesDictionary objectForKey:key] forKey:key];
    }
}

- (void)addAttribute:(NSString *)key value:(id)value
{
    [_innerAttributes setObject:value forKey:key];
}

- (void)removeAllAttributes
{
    [_innerAttributes removeAllObjects];
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
