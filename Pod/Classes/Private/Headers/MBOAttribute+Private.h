//
//  MBOAttribute+Private.h
//  SensorLogger
//
//  Created by Dominic Plouffe on 2014-07-14.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOAttribute.h"

@class MBOValueContainer;

@interface MBOAttribute (Private)

@property (nonatomic, copy) MBOValueContainer *valueContainer;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
