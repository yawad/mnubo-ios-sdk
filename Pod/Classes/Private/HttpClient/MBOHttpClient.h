//
//  MBOHttpClient.h
// 
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBOHttpClient <NSObject>

- (void)GET:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters completion:(void (^)(id data, NSError *error))completion;

- (void)PUT:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters data:(NSDictionary *)data completion:(void (^)(id data, NSError *error))completion;

- (void)POST:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters data:(NSDictionary *)data completion:(void (^)(id data, NSDictionary *responsesHeaderFields, NSError *error))completion;

- (void)DELETE:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters completion:(void (^)(id data, NSError *error))completion;

@end
