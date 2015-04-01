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

@interface MBOSample()

    @property(nonatomic, copy) NSMutableDictionary *commonValues;

@end


@implementation MBOSample

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _commonValues = [[NSMutableDictionary alloc] init];
        [_commonValues setObject:[NSDate date] forKey:@"registration_date"];
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self)
    {
        
        _commonValues = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
        if (![_commonValues objectForKey:@"registration_date"])
        {
            [_commonValues setObject:[NSDate date] forKey:@"registration_date"];
        }
    }
    
    return self;
}

- (void)addSensorWithName:(NSString *)name andDictionary:(NSDictionary *)sensorDictionary
{
    [_commonValues setValue:sensorDictionary forKey:name];
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
    SafeSetValueForKey(_commonValues, @"timestamp", [MBODateHelper mnuboStringFromDate:[_commonValues objectForKey:@"timestamp"]]);
    SafeSetValueForKey(_commonValues, @"registration_date", [MBODateHelper mnuboStringFromDate:[_commonValues objectForKey:@"registration_date"]]);
    return _commonValues;
}

@end
