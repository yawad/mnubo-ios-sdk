//
//  MBOAttribute.h
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@interface MBOAttribute : NSObject <NSCopying, NSCoding>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) id value;
@property (nonatomic, readonly) NSString *category;

- (instancetype)initWithName:(NSString *)name category:(NSString *)category stringValue:(NSString *)stringValue;

- (instancetype)initWithName:(NSString *)name category:(NSString *)category floatValue:(CGFloat)floatValue;

- (instancetype)initWithName:(NSString *)name category:(NSString *)category dateValue:(NSDate *)dateValue;

- (instancetype)initWithName:(NSString *)name category:(NSString *)category uuidValue:(NSUUID *)uuidValue;


@end
