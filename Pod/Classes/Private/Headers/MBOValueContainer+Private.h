//
//  MBOValueContainer+Private.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOValueContainer.h"

@class MBOValueDefinition;

@interface MBOValueContainer (Private)

- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition;
- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition value:(id)value;
- (instancetype)initWithValueDefinition:(MBOValueDefinition *)definition valueString:(NSString *)valueString;

@end
