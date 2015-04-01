//
//  MBOObject.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
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
NSString const * kMBOObjectCollectionIdKey = @"collection";

@interface MBOObject ()
{
    NSMutableArray *_innerAttributes;
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
        _innerAttributes = [NSMutableArray array];
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
        _innerAttributes = [NSMutableArray array];
        _location = [[MBOLocation alloc] init];
        _registrationDate = [NSDate date];
        
        _objectId = [dictionary stringForKey:kMBOObjectObjectIdKey];
        _deviceId = [dictionary stringForKey:kMBOObjectDeviceIdKey];
        _objectModelName = [dictionary stringForKey:kMBOObjectModelNameKey];
        _ownerUsername = [dictionary stringForKey:kMBOObjectOwnerKey];
        
        NSMutableArray *attributes = [NSMutableArray array];
        NSArray *attributesDictionaries = [dictionary objectForKey:@"attributes"];
        [attributesDictionaries enumerateObjectsUsingBlock:^(NSDictionary *attributeDictionary, NSUInteger idx, BOOL *stop)
         {
             MBOAttribute *attribute = [[MBOAttribute alloc] initWithDictionary:attributeDictionary];
             if (attribute)
             {
                 [attributes addObject:attribute];
             }
         }];
        
        _innerAttributes = attributes;
        
        _location = [[MBOLocation alloc] initWithDictionary:[dictionary dictionaryForKey:@"registration_location"]];
        if ([dictionary stringForKey:@"registration_date"])
        {
            _registrationDate = [MBODateHelper dateFromMnuboString:[dictionary stringForKey:@"registration_date"]];
        }

        _collectionId = [dictionary objectForKey:@"collectionId"];
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
        _collectionId = [aDecoder decodeObjectForKey:@"collectionId"];
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
    [aCoder encodeObject:_collectionId forKey:@"collectionId"];
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
    copy.collectionId = _collectionId;
    
    [_innerAttributes enumerateObjectsUsingBlock:^(MBOAttribute *attribute, NSUInteger idx, BOOL *stop)
    {
        [copy addAttribute:attribute];
    }];
    
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
    IsEqualToArray(_innerAttributes, otherObject.attributes) &&
    IsEqual(_location, otherObject.location) &&
    IsEqualToDate(_registrationDate, otherObject.registrationDate) &&
    IsEqualToArray(_collectionId, otherObject.collectionId);
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
    hash += [_collectionId hash];
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
    
    NSMutableArray *attributeDictionaries = [NSMutableArray array];
    [_innerAttributes enumerateObjectsUsingBlock:^(MBOAttribute *attribute, NSUInteger idx, BOOL *stop)
    {
        [attributeDictionaries addObject:[attribute toDictionary]];
    }];

    if (attributeDictionaries.count > 0)
    {
        [_dictionary setObject:attributeDictionaries forKey:@"attributes"];
    }
    
    SafeSetValueForKey(_dictionary, @"registration_date", [MBODateHelper mnuboStringFromDate:_registrationDate]);

    if (_collectionId)
    {
        [_dictionary setObject:@{@"id" : _collectionId} forKey:kMBOObjectCollectionIdKey];
    }

    return _dictionary;
}

- (void)setAttributes:(NSArray *)attributes {
    _innerAttributes = [[NSMutableArray alloc] initWithArray:attributes];
}

- (NSArray *)attributes
{
    return [NSArray arrayWithArray:_innerAttributes];
}

- (void)addAttribute:(MBOAttribute *)attribute
{
    [_innerAttributes addObject:attribute];
}

- (void)insertAttribute:(MBOAttribute *)attribute atIndex:(NSInteger)index
{
    [_innerAttributes insertObject:attribute atIndex:index];
}

- (void)removeAttribute:(MBOAttribute *)attribute
{
    [_innerAttributes removeObject:attribute];
}

- (void)removeAttributeAtIndex:(NSInteger)index
{
    [_innerAttributes removeObjectAtIndex:index];
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
