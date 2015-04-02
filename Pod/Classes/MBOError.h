//
//  MBOError.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBOError : NSError


typedef NS_ENUM(NSUInteger, MBOErrorCode)
{
    MBOErrorCodeInvalidDataReceived = 1000,
    MBOErrorCodeInvalidParameter,
    MBOErrorCodeGetNewCreatedObjectError,
    MBOErrorCodeWillBeRetryLaterAutomatically
};

@property(nonatomic, readonly) NSString *mnuboErrorMessage;
@property(nonatomic, readonly) NSInteger mnuboErrorCode;

@end
