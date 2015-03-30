//
//  MBOError.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-27.
//  Copyright (c) 2014 Mirego. All rights reserved.
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
