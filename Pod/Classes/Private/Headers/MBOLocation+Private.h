//
//  MBOLocation+Private.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOLocation.h"

@interface MBOLocation (Private)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
