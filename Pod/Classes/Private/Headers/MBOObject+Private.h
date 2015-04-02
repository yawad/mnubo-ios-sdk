//
//  MBOObject+Private.h
// 
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOObject.h"

@interface MBOObject (Private)

@property (nonatomic, copy) MBOLocation *location;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
