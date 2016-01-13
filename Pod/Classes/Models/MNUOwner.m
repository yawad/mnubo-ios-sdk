//
//  MNUOwner.m
//  APIv3
//
//  Created by Guillaume on 2015-08-14.
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MNUOwner.h"

@implementation MNUOwner


//------------------------------------------------------------------------------
#pragma mark Helper methods
//------------------------------------------------------------------------------
- (instancetype)init {
    
    self = [super init];
    if (self) {
        _attributes = [[NSMutableDictionary alloc] init];
        _registrationDate = [NSDate date];
    }
    
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
    
    SafeSetValueForKey(attributeDictionary, @"username", _username);
    SafeSetValueForKey(attributeDictionary, @"x_password", _password);
    SafeSetValueForKey(attributeDictionary, @"x_registration_date", _registrationDate);
    
    for (id key in _attributes)
        SafeSetValueForKey(attributeDictionary, key, [_attributes objectForKey:key]);
    
    return [NSDictionary dictionaryWithDictionary:attributeDictionary];
}

@end
