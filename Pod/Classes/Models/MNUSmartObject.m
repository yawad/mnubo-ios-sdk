//
//  MNUSmartObject.m
//  APIv3
//
//  Created by Guillaume on 2015-08-14.
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MNUSmartObject.h"

@implementation MNUSmartObject

//------------------------------------------------------------------------------
#pragma mark Helper methods
//------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _attributes = [[NSMutableDictionary alloc] init];
        //_registrationDate = [NSDate date];
    }
    
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
    
    SafeSetValueForKey(attributeDictionary, @"x_device_id", _deviceId);
    SafeSetValueForKey(attributeDictionary, @"object_id", _objectId);
    SafeSetValueForKey(attributeDictionary, @"x_object_type", _objectType);
    SafeSetValueForKey(attributeDictionary, @"x_registration_date", _registrationDate);
    SafeSetValueForKey(attributeDictionary, @"owner", _owner);
    
    
    for(id key in _attributes)
        SafeSetValueForKey(attributeDictionary, key, [_attributes objectForKey:key]);
    
    return [NSDictionary dictionaryWithDictionary:attributeDictionary];
}

@end
