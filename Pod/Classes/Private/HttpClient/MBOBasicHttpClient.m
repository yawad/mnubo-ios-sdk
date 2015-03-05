//
//  MBOBasicHttpClient.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-27.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOBasicHttpClient.h"
#import "NSString+mnubo.h"

typedef void (^MBOBasicClientCompletionBlock)(id data, NSDictionary *responseHeaderFields, NSError *error);

@interface MBOBasicHttpClientDelegate : NSObject<NSURLConnectionDataDelegate>

- (instancetype)initWithCompletion:(MBOBasicClientCompletionBlock)completion;

@end

@implementation MBOBasicHttpClient

- (void)GET:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters completion:(void (^)(id data, NSError *error))completion
{
    NSParameterAssert(completion != nil);

    // Network call needs to be trigger in the main thread
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [NSURLConnection connectionWithRequest:[MBOBasicHttpClient generateRequestWithPath:path method:@"GET" headers:headers parameters:parameters]
                                      delegate:[[MBOBasicHttpClientDelegate alloc] initWithCompletion:^(id data, NSDictionary *responseHeaderFields, NSError *error)
                                                {
                                                    completion(data, error);
                                                }]];
    });
}

- (void)PUT:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters data:(NSDictionary *)data completion:(void (^)(id data, NSError *error))completion
{
    NSParameterAssert(completion != nil);

    NSMutableURLRequest *request = [MBOBasicHttpClient generateRequestWithPath:path method:@"PUT" headers:headers parameters:parameters];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    [request setHTTPBody:jsonData];

    // Network call needs to be trigger in the main thread
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [NSURLConnection connectionWithRequest:request
                                      delegate:[[MBOBasicHttpClientDelegate alloc] initWithCompletion:^(id data, NSDictionary *responseHeaderFields, NSError *error)
                                                {
                                                    completion(data, error);
                                                }]];
    });
}

- (void)POST:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters data:(NSDictionary *)data completion:(void (^)(id data, NSDictionary *responsesHeaderFields, NSError *error))completion
{
    NSParameterAssert(completion != nil);
    
    NSMutableURLRequest *request = [MBOBasicHttpClient generateRequestWithPath:path method:@"POST" headers:headers parameters:parameters];
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    [request setHTTPBody:jsonData];

    // Network call needs to be trigger in the main thread
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [NSURLConnection connectionWithRequest:request
                                      delegate:[[MBOBasicHttpClientDelegate alloc] initWithCompletion:completion]];
    });
}

- (void)DELETE:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters completion:(void (^)(id data, NSError *error))completion
{
    NSParameterAssert(completion != nil);
    
    // Network call needs to be trigger in the main thread
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [NSURLConnection connectionWithRequest:[MBOBasicHttpClient generateRequestWithPath:path method:@"DELETE" headers:headers parameters:parameters]
                                      delegate:[[MBOBasicHttpClientDelegate alloc] initWithCompletion:^(id data, NSDictionary *responseHeaderFields, NSError *error)
                                                {
                                                    completion(data, error);
                                                }]];
    });
}

//------------------------------------------------------------------------------
#pragma mark Helper methods
//------------------------------------------------------------------------------

+ (NSMutableURLRequest *)generateRequestWithPath:(NSString *)path method:(NSString *)method headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[MBOBasicHttpClient addParameters:parameters toPath:path]]];
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

//------------------------------------------------------------------------------
#pragma mark NSURLConnection Delegate Class
//------------------------------------------------------------------------------

@implementation MBOBasicHttpClientDelegate
{
    MBOBasicClientCompletionBlock _completionBlock;
    NSError *_error;
    NSMutableData *_data;
    NSDictionary *_responseHeaders;
}

- (instancetype)initWithCompletion:(MBOBasicClientCompletionBlock)completion
{
    self = [super init];
    if(self)
    {
        _completionBlock = completion;
        _data = [[NSMutableData alloc] init];
    }

    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSAssert([response isKindOfClass:[NSHTTPURLResponse class]], @"Invalid reponse classe!");

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    _responseHeaders = httpResponse.allHeaderFields;
    _error = [MBOBasicHttpClientDelegate errorFromHttpResponse:httpResponse];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if((error.code == 303 || error.code == -1017) && ([connection.currentRequest.HTTPMethod isEqualToString:@"PUT"] || [connection.currentRequest.HTTPMethod isEqualToString:@"DELETE"]))
    {
        // MEGA HACK... the mnubo server is returning packet that can't be parsed by iOS. The invalid packets only happend for PUT and DELETE on a success response.
        // So for these cases, we thread the error like a success.
        if(_completionBlock) _completionBlock(nil, _responseHeaders, nil);
    }
    else
    {
        if(_completionBlock) _completionBlock(nil, _responseHeaders, error);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        id jsonData = _data.length > 0 ? [NSJSONSerialization JSONObjectWithData:_data options:0 error:nil] : nil;
        dispatch_async(dispatch_get_main_queue(), ^
        {
            if(_completionBlock) _completionBlock(jsonData, _responseHeaders, _error);
        });
    });
}

+ (NSError *)errorFromHttpResponse:(NSHTTPURLResponse *)response
{
    // 2XX code are success
    if(response.statusCode / 100 == 2) return nil;

    return [NSError errorWithDomain:@"com.mnubo.sdk" code:response.statusCode userInfo:nil];
}

@end
