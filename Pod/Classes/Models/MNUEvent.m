//
//  MNUEvent.m
//  APIv3
//
//  Created by Guillaume on 2015-08-14.
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MNUEvent.h"

@implementation MNUEvent


- (instancetype)init {
    
    self = [super init];
    if (self) {
        _timeseries = [[NSMutableDictionary alloc] init];
        _timestamp = [NSDate date];
    }
    
    return self;
}

//------------------------------------------------------------------------------
#pragma mark Helper methods
//------------------------------------------------------------------------------

- (NSDictionary *)toDictionary {
    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
    
    SafeSetValueForKey(attributeDictionary, @"event_id", _eventId);
    
    SafeSetValueForKey(attributeDictionary, @"x_event_type", _eventType);
    SafeSetValueForKey(attributeDictionary, @"x_timestamp", _timestamp);

    for (id key in _timeseries)
        SafeSetValueForKey(attributeDictionary, key, [_timeseries objectForKey:key]);
    
    return [NSDictionary dictionaryWithDictionary:attributeDictionary];
}

@end
