//
//  NSString+mnubo.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-17.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "NSString+mnubo.h"

@implementation NSString (mnubo)

- (NSString *)urlEncode
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (__bridge CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
}

- (NSString *)base64Encode
{
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

@end
