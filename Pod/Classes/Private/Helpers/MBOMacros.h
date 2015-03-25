//
//  MBOMacros.h
//  SensorLogger
//
//  Created by Dominic Plouffe on 2014-07-11.
//  Copyright (c) 2014 Mirego. All rights reserved.
//

#define IsEqualToString(x,y) (([x isEqualToString:y]) || (!x && !y))
#define IsEqualToDate(x,y) (([x isEqualToDate:y]) || (!x && !y))
#define IsEqualToArray(x,y) (([x isEqualToArray:y]) || (!x && !y))
#define IsEqualToDictionary(x,y) (([x isEqualToDictionary:y]) || (!x && !y))
#define IsEqualToNumber(x,y) (([x isEqualToNumber:y]) || (!x && !y))
#define IsEqual(x,y) (([x isEqual:y]) || (!x && !y))

#define SafeSetValueForKey(dict, k, v) if (v) dict[k] = v;

#define MBOLog(string, ...) if ([mnubo isLoggingEnabled]) NSLog (string, ##__VA_ARGS__)