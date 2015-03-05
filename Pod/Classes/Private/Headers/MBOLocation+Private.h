//
//  MBOLocation+Private.h
//  SensorLogger
//
//  Created by Dominic Plouffe on 2014-07-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOLocation.h"

@interface MBOLocation (Private)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
