//
//  MBOAttribute+Private.h
//
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOAttribute.h"

@class MBOValueContainer;

@interface MBOAttribute (Private)

@property (nonatomic, copy) MBOValueContainer *valueContainer;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
