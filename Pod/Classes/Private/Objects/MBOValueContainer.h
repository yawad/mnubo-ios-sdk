//
//  MBOValueContainer.h
//  SensorLogger
//
//  Created by Dominic Plouffe on 2014-07-14.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBOValueDefinition.h"

@interface MBOValueContainer : NSObject <NSCopying, NSCoding>

@property (nonatomic, readonly, copy) MBOValueDefinition *definition;
@property (nonatomic, copy) id value;

- (NSString *)stringValue;
- (NSString *)stringDataType;

@end
