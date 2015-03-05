//
//  MBOHttpClient.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-17.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBOHttpClient <NSObject>

- (void)GET:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters completion:(void (^)(id data, NSError *error))completion;

- (void)PUT:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters data:(NSDictionary *)data completion:(void (^)(id data, NSError *error))completion;

- (void)POST:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters data:(NSDictionary *)data completion:(void (^)(id data, NSDictionary *responsesHeaderFields, NSError *error))completion;

- (void)DELETE:(NSString *)path headers:(NSDictionary *)headers parameters:(NSDictionary *)parameters completion:(void (^)(id data, NSError *error))completion;

@end
