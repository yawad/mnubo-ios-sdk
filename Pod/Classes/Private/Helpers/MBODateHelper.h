//
//  MBODateHelper.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-02.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBODateHelper : NSObject

+ (NSDate *)dateFromMnuboString:(NSString *)dateString;

+ (NSString *)mnuboStringFromDate:(NSDate *)date;

@end
