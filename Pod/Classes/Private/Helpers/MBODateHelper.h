//
//  MBODateHelper.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBODateHelper : NSObject

+ (NSDate *)dateFromMnuboString:(NSString *)dateString;

+ (NSString *)mnuboStringFromDate:(NSDate *)date;

@end
