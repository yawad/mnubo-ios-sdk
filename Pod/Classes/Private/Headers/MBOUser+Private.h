//
//  MBOUser+Private.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOUser.h"

@interface MBOUser (Private)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
