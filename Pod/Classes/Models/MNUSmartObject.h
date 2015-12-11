//
//  MNUSmartObject.h
//  APIv3
//
//  Created by Guillaume on 2015-08-14.
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MNUOwner.h"

@interface MNUSmartObject : NSObject

@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, copy) NSString *objectType;
@property (nonatomic, copy) NSDate *registrationDate;
@property (nonatomic, copy) MNUOwner *owner;
@property (nonatomic, copy) NSMutableDictionary *attributes;

- (NSDictionary *)toDictionary;

@end
