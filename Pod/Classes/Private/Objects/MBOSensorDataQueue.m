//
//  MBOSensorDataQueue.m
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-07-16.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOSensorDataQueue.h"
#import "NSDictionary+mnubo.h"
#import "Reachability.h"
#import "mnubo.h"

@interface MBOSensorDataQueue()
{
    __weak mnubo *_mnuboSDK;
    NSOperationQueue *_diskAccessQueue;
    
    NSTimeInterval _retryInterval;
    NSTimer *_retryTimer;
}

@end

@implementation MBOSensorDataQueue

- (instancetype)initWithRetryInterval:(NSTimeInterval)retryInterval mnuboSDK:(mnubo *)mnuboSDK
{
    self = [super init];
    if(self)
    {
        _retryInterval = MAX(retryInterval, 5);
        _mnuboSDK = mnuboSDK;

        _diskAccessQueue = [[NSOperationQueue alloc] init];
        _diskAccessQueue.maxConcurrentOperationCount = 1;

        [self createAllFolders];
        [self moveSendingDataToRetryFolder];
        
        _retryTimer = [NSTimer scheduledTimerWithTimeInterval:_retryInterval target:self selector:@selector(retryJobs) userInfo:nil repeats:YES];
    }

    return self;
}

//------------------------------------------------------------------------------
#pragma mark Public methods
//------------------------------------------------------------------------------

- (void)setRetryInterval:(NSTimeInterval)retryInterval
{
    _retryInterval = retryInterval;
    [_retryTimer invalidate];
    
    _retryTimer = [NSTimer scheduledTimerWithTimeInterval:_retryInterval target:self selector:@selector(retryJobs) userInfo:nil repeats:YES];
}

- (void)addSensorData:(NSArray *)sensorDatas commonData:(MBOCommonSensorData *)commonData objectId:(NSString *)objectId deviceId:(NSString *)deviceId completion:(void (^)(NSString *queueIdentifiyer))completion
{
    [_diskAccessQueue addOperationWithBlock:^
    {
        NSMutableDictionary *objectData = [NSMutableDictionary dictionary];
        if(sensorDatas.count > 0)
        {
            objectData[@"sensorDatas"] = sensorDatas;
        }

        if(commonData)
        {
            objectData[@"commonData"] = commonData;
        }

        if(objectId.length > 0)
        {
            objectData[@"objectId"] = objectId;
        }

        if(deviceId.length > 0)
        {
            objectData[@"deviceId"] = deviceId;
        }

        NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:objectData];
        NSString *queueIdentifier = [[NSUUID UUID] UUIDString];
        [MBOSensorDataQueue saveData:encodedData forFileIdentifier:queueIdentifier inSendingPath:YES];
        
        if(completion) completion(queueIdentifier);
    }];
}

- (void)removeSensorDataWithIdentifier:(NSString *)queueIdentifiyer
{
    [_diskAccessQueue addOperationWithBlock:^
    {
        [MBOSensorDataQueue deleteFileWithSensorDataWithIdentifier:queueIdentifiyer inSendingPath:YES];
    }];
}

- (void)moveToRetryQueueSensorDataWithIdentifier:(NSString *)queueIdentifiyer
{
    [_diskAccessQueue addOperationWithBlock:^
    {
        [[NSFileManager defaultManager] moveItemAtPath:[MBOSensorDataQueue pathForIdenfitifer:queueIdentifiyer inSendingPath:YES]
                                                toPath:[MBOSensorDataQueue pathForIdenfitifer:queueIdentifiyer inSendingPath:NO]
                                                 error:nil];
    }];
}

//------------------------------------------------------------------------------
#pragma mark Private methods
//------------------------------------------------------------------------------

- (void)retryJobs
{
    // Do not try to retry the job if there is no internet connection
    if([Reachability reachabilityForInternetConnection] == NO) return;

    [_diskAccessQueue addOperationWithBlock:^
    {
        [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[MBOSensorDataQueue retryQueueFolderPath] error:NULL] enumerateObjectsUsingBlock:^(NSString *fileIdentifier, NSUInteger idx, BOOL *stop)
        {
            if([fileIdentifier hasPrefix:@"."] == NO && [fileIdentifier pathExtension].length == 0)
            {
                [self retryJobWithIdentifier:fileIdentifier];
            }
        }];
    }];
}

- (void)retryJobWithIdentifier:(NSString *)fileIdentifier
{
    NSData *encodedJobData = [NSData dataWithContentsOfFile:[MBOSensorDataQueue pathForIdenfitifer:fileIdentifier inSendingPath:NO]];
    if(encodedJobData)
    {
        NSDictionary *jobData = [NSKeyedUnarchiver unarchiveObjectWithData:encodedJobData];
        if([jobData stringForKey:@"deviceId"].length > 0)
        {
            [_mnuboSDK sendSensorData:[jobData arrayForKey:@"sensorDatas"] commonData:[jobData objectForKey:@"commonData"] forDeviceId:[jobData stringForKey:@"deviceId"] completion:nil];
        }
        else
        {
            [_mnuboSDK sendSensorData:[jobData arrayForKey:@"sensorDatas"] commonData:[jobData objectForKey:@"commonData"] forObjectId:[jobData stringForKey:@"objectId"] completion:nil];
        }
    }

    // The _mnuboSDK sendSensorData will put back a instance of that new job in the "sending queue", so we can delete this one right away
    [MBOSensorDataQueue deleteFileWithSensorDataWithIdentifier:fileIdentifier inSendingPath:NO];
}

- (void)createAllFolders
{
    [_diskAccessQueue addOperationWithBlock:^
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:[MBOSensorDataQueue sendingQueueFolderPath] withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:[MBOSensorDataQueue retryQueueFolderPath] withIntermediateDirectories:YES attributes:nil error:nil];
    }];
}

- (void)moveSendingDataToRetryFolder
{
    [_diskAccessQueue addOperationWithBlock:^
    {
        [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[MBOSensorDataQueue sendingQueueFolderPath] error:NULL] enumerateObjectsUsingBlock:^(NSString *fileIdentifier, NSUInteger idx, BOOL *stop)
        {
            [[NSFileManager defaultManager] moveItemAtPath:[MBOSensorDataQueue pathForIdenfitifer:fileIdentifier inSendingPath:YES]
                                                    toPath:[MBOSensorDataQueue pathForIdenfitifer:fileIdentifier inSendingPath:NO]
                                                     error:nil];
        }];
    }];
}

//------------------------------------------------------------------------------
#pragma mark Helper methods
//------------------------------------------------------------------------------
+ (void)saveData:(NSData *)data forFileIdentifier:(NSString *)fileIdentifier inSendingPath:(BOOL)inSendingPath
{
    NSString *filePath = [MBOSensorDataQueue pathForIdenfitifer:fileIdentifier inSendingPath:inSendingPath];
    [data writeToFile:filePath atomically:YES];
}

+ (void)deleteFileWithSensorDataWithIdentifier:(NSString *)fileIdentifier inSendingPath:(BOOL)inSendingPath
{
    [[NSFileManager defaultManager] removeItemAtPath:[MBOSensorDataQueue pathForIdenfitifer:fileIdentifier inSendingPath:inSendingPath] error:nil];
}

+ (NSString *)pathForIdenfitifer:(NSString *)identifier inSendingPath:(BOOL)inSendingPath
{
    NSString *path = inSendingPath ? [MBOSensorDataQueue sendingQueueFolderPath] : [MBOSensorDataQueue retryQueueFolderPath];
    return [path stringByAppendingPathComponent:identifier];
}

+ (NSString *)sendingQueueFolderPath
{
    NSArray *urls = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentFolderPath = [NSString stringWithFormat:@"%@", urls[0]];

    return [documentFolderPath stringByAppendingPathComponent:@"com.mnubo.sdk.sendingqueue"];
}

+ (NSString *)retryQueueFolderPath
{
    NSArray *urls = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentFolderPath = [NSString stringWithFormat:@"%@", urls[0]];
    
    return [documentFolderPath stringByAppendingPathComponent:@"com.mnubo.sdk.retryqueue"];
}

@end
