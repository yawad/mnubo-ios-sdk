//
//  MBOError+Private.h
// 
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOError.h"

@interface MBOError ()

+ (MBOError *)errorWithError:(NSError *)error extraInfo:(id)extraInfoData;

@end
