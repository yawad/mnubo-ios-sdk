//
//  MNUOwner.h
//  APIv3
//
//  Created by Guillaume on 2015-08-14.
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MNUMacros.h"

@interface MNUOwner : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSMutableDictionary* attributes;

- (NSDictionary *)toDictionary;

@end
