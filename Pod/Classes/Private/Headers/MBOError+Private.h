//
//  MBOError+Private.h
//  SensorLogger
//
//  Created by Hugo Lefrancois on 2014-06-27.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#import "MBOError.h"

@interface MBOError ()

+ (MBOError *)errorWithError:(NSError *)error extraInfo:(id)extraInfoData;

@end
