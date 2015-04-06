//
//  MBOError.m
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOError.h"

@implementation MBOError

- (instancetype)initWithError:(NSError *)error extraInfo:(id)extraInfo
{
    self = [super initWithDomain:error.domain code:error.code userInfo:error.userInfo];
    if(self)
    {
        if([extraInfo isKindOfClass:[NSDictionary class]])
        {
            _mnuboErrorCode = [[extraInfo objectForKey:@"errorCode"] integerValue];
            
            if ([extraInfo objectForKey:@"message"])
            {
                _mnuboErrorMessage = [extraInfo objectForKey:@"message"];
            }
            else
            {
                _mnuboErrorMessage = [extraInfo objectForKey:@"error_description"];
            }
            
            // Custom error code
            if ([_mnuboErrorMessage rangeOfString:@"User "].location != NSNotFound && [_mnuboErrorMessage rangeOfString:@" already exists"].location != NSNotFound)
            {
                _mnuboErrorCode = MBOErrorCodeUserAlreadyExists;
            }
            else if ([_mnuboErrorMessage rangeOfString:@"Bad credentials"].location != NSNotFound)
            {
                    _mnuboErrorCode = MBOErrorCodeBadCredentials;
            }
        }
    }
    
    
    return self;
}

+ (MBOError *)errorWithError:(NSError *)error extraInfo:(id)extraInfoData
{

    return [[MBOError alloc] initWithError:error extraInfo:extraInfoData];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ mnuboMessage:%@ mnobuError:%ld", [super description], _mnuboErrorMessage, (long)_mnuboErrorCode];
}

@end
