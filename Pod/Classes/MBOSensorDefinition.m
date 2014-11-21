//
//  MBOSensorDefinition.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-10.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOSensorDefinition.h"
#import "NSDictionary+mnubo.h"
#import "MBOValueDefinition+Private.h"
#import "MBOMacros.h"

@interface MBOSensorDefinition ()

@property(nonatomic, readwrite, copy) NSString *name;
@property(nonatomic, readwrite, copy) NSString *templateName;
@property(nonatomic, readwrite, copy) NSString *templateDescription;
@property(nonatomic, readwrite, copy) NSArray *sensorValueDefinitions;

@end

@implementation MBOSensorDefinition

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self)
    {
        _name = [dictionary stringForKey:@"name"];

        NSDictionary *template = [dictionary dictionaryForKey:@"template"];
        _templateName = [template stringForKey:@"name"];
        _templateDescription = [template stringForKey:@"description"];

        NSArray *definitions = [template arrayForKey:@"definition"];
        NSMutableArray *valueDefinitions = [NSMutableArray arrayWithCapacity:definitions.count];

        [definitions enumerateObjectsUsingBlock:^(NSDictionary *definition, NSUInteger idx, BOOL *stop)
        {
            if([definition isKindOfClass:[NSDictionary class]])
            {
                [valueDefinitions addObject:[[MBOValueDefinition alloc] initWithDictionary:definition]];
            }
        }];

        _sensorValueDefinitions = valueDefinitions;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _templateName = [aDecoder decodeObjectForKey:@"templateName"];
        _templateDescription = [aDecoder decodeObjectForKey:@"templateDescription"];
        _sensorValueDefinitions = [aDecoder decodeObjectForKey:@"sensorValueDefinitions"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_templateName forKey:@"templateName"];
    [aCoder encodeObject:_templateDescription forKey:@"templateDescription"];
    [aCoder encodeObject:_sensorValueDefinitions forKey:@"sensorValueDefinitions"];
}

- (id)copyWithZone:(NSZone *)zone
{
    MBOSensorDefinition *copy = [[MBOSensorDefinition alloc] init];
    
    copy.name = _name;
    copy.templateName = _templateName;
    copy.templateDescription = _templateDescription;
    copy.sensorValueDefinitions = _sensorValueDefinitions;
    
    return copy;
}

- (BOOL)isEqual:(MBOSensorDefinition *)otherSensorDefinition
{
    if (![otherSensorDefinition isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqualToString(_name, otherSensorDefinition.name) &&
    IsEqualToString(_templateName, otherSensorDefinition.templateName) &&
    IsEqualToString(_templateDescription, otherSensorDefinition.templateDescription) &&
    IsEqualToArray(_sensorValueDefinitions, otherSensorDefinition.sensorValueDefinitions);
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_name hash];
    hash += [_templateName hash];
    hash += [_templateDescription hash];
    hash += [_sensorValueDefinitions hash];
    return hash;
}

- (NSArray *)allSensorValueNames
{
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:_sensorValueDefinitions.count];
    [_sensorValueDefinitions enumerateObjectsUsingBlock:^(MBOValueDefinition *valueDefinition, NSUInteger idx, BOOL *stop)
    {
        [names addObject:valueDefinition.name];
    }];
    
    return names;
}

- (MBOValueDefinition *)sensorValueDefinitionForName:(NSString *)name
{
    __block MBOValueDefinition *sensorValueDefinition = nil;
    [_sensorValueDefinitions enumerateObjectsUsingBlock:^(MBOValueDefinition *valueDefinition, NSUInteger idx, BOOL *stop)
    {
        if([name isEqualToString:valueDefinition.name])
        {
            sensorValueDefinition = valueDefinition;
            *stop  = YES;
        }
    }];

    return sensorValueDefinition;
}

@end
