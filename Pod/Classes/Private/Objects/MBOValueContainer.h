//
//  MBOValueContainer.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBOValueDefinition.h"

@interface MBOValueContainer : NSObject <NSCopying, NSCoding>

@property (nonatomic, readonly, copy) MBOValueDefinition *definition;
@property (nonatomic, copy) id value;

- (NSString *)stringValue;
- (NSString *)stringDataType;

@end
