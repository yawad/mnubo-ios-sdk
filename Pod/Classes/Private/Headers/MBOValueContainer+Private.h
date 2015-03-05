//
//  MBOValueContainer+Private.h
//  SensorLogger
//
//  Created by Dominic Plouffe on 2014-07-14.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOValueContainer.h"

@class MBOValueDefinition;

@interface MBOValueContainer (Private)

- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition;
- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition value:(id)value;
- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition valueString:(NSString *)valueString;

@end
