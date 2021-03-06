//
//  MNUHTTPClient.m
//  APIv3
//
//  Created by Guillaume on 2015-10-06.
//  Copyright © 2015 mnubo. All rights reserved.
//

#import "MNUHTTPClient.h"
#import "NSString+mnubo.h"

@implementation MNUHTTPClient

+ (void)POST:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters body:(NSDictionary *)body completion:(void (^)(id data, NSDictionary *responsesHeaderFields, NSError *error))completion {
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];

    NSMutableURLRequest *urlRequest = [self generateRequestWithPath:path method:@"POST" headers:headers parameters:parameters];

    if (body) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@[body] options:0 error:nil];
        [urlRequest setHTTPBody:jsonData];
    }

    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonData = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        
        if (httpResponse.statusCode != 200) {
            error = [[NSError alloc] initWithDomain:@"mnubo" code:400 userInfo:nil];
        }
        
        if (completion) completion(jsonData, httpResponse.allHeaderFields, error);
    }];
    
    [dataTask resume];
}


+ (void)PUT:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters body:(NSDictionary *)body completion:(void (^)(id data, NSDictionary *responsesHeaderFields, NSError *error))completion {
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    NSMutableURLRequest *urlRequest = [self generateRequestWithPath:path method:@"PUT" headers:headers parameters:parameters];
    
    if (body) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
        [urlRequest setHTTPBody:jsonData];
    }
    
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonData = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;

        if (httpResponse.statusCode != 200 || httpResponse.statusCode != 201) {
            error = [[NSError alloc] initWithDomain:@"mnubo" code:400 userInfo:nil];
        }
        
        if (completion) completion(jsonData, httpResponse.allHeaderFields, error);
    }];
    
    [dataTask resume];
}


//------------------------------------------------------------------------------
#pragma mark Helper methods
//------------------------------------------------------------------------------

+ (NSMutableURLRequest *)generateRequestWithPath:(NSString *)path method:(NSString *)method headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request;
    
    if ([[headers objectForKey:@"Content-Type"] isEqualToString:@"application/x-www-form-urlencoded"])
    {
        request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:path]];
        NSString *encodedParams = [[self addParameters:parameters toPath:@""] substringFromIndex:1];
        [request setHTTPBody:[encodedParams dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else
    {
        request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[self addParameters:parameters toPath:path]]];
    }
    
    [request setHTTPMethod:method];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop)
     {
         [request setValue:value forHTTPHeaderField:key];
     }];
    
    return request;
}

+ (NSString *)addParameters:(NSDictionary *)parameters toPath:(NSString *)path
{
    if (!parameters) return path;
    
    __block NSString *newPath = path;
    __block BOOL firstParameterDone = NO;
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop)
     {
         if(!firstParameterDone)
         {
             newPath = [newPath stringByAppendingFormat:@"?%@=%@", key, [value urlEncode]];
             firstParameterDone = YES;
         }
         else
         {
             newPath = [newPath stringByAppendingFormat:@"&%@=%@", key, [value urlEncode]];
         }
         
     }];
    
    return newPath;
}


@end
