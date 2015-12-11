//
//  MNUEvent.h
//  APIv3
//
//  Created by Guillaume on 2015-08-14.
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MNUSmartObject.h"
#import "MNUMacros.h"

@interface MNUEvent : NSObject

@property (nonatomic, copy) NSString *eventId;
@property (nonatomic, copy) MNUSmartObject *smartObject;
@property (nonatomic, copy) NSString *eventType;
@property (nonatomic, copy) NSDate *timestamp;
@property (nonatomic, copy) NSMutableDictionary *timeseries;

- (NSDictionary *)toDictionary;

@end
