mnubo iOS SDK
============

iOS SDK allowing iOS apps to quickly implement the mnubo REST API.

## How To Get Started

1. Install [CocoaPods](http://cocoapods.org/) with `gem install cocoapods`.
2. Create a file in your XCode project called `Podfile` and add the following line:

    ```ruby
    pod 'mnuboSDK'
    ```

3. Run `pod install` in your xcode project directory. CocoaPods should download and
install the mnubo iOS SDK, and create a new Xcode workspace. Open up this workspace in Xcode.


## Architecture

### mnubo

The primary class of the SDK has to be initialize with your mnubo account informations (name, namespace, consumer keys, consumer secrets). mnubo REST API calls are represented by a method of that class.

* `User Management`
  - `createUser:updateIfAlreadyExist:completion:`
  - `updateUser:completion:`
  - `getUserWithUsername:completion:`
  - `deleteUserWithUsername:completion:`
* `Object Management`
  - `createObject:updateIfAlreadyExist:completion:`
  - `updateObject:completion:`
  - `getObjectWithObjectId:completion:`
  - `getObjectWithDeviceId:completion:`
  - `deleteObjectWithObjectId:completion:`
  - `deleteObjectWithDeviceId:completion:`
* `Send Sensor Data`
  - `sendSensorData:forObjectId:completion:`
  - `sendSensorData:commonData:forObjectId:completion:`
  - `sendSensorData:forDeviceId:completion:`
  - `sendSensorData:commonData:forDeviceId:completion:`
* `Fetch Sensor Data`
  - `fetchLastSensorDataOfObjectId:sensorDefinition:completion:`
  - `fetchLastSensorDataOfDeviceId:sensorDefinition:completion:`
  - `fetchSensorDatasOfObjectId:sensorDefinition:fromStartDate:toEndDate:completion:`
  - `fetchSensorDatasOfDeviceId:sensorDefinition:fromStartDate:toEndDate:completion:`
  - `fetchSensorDataCountOfObjectId:sensorDefinition:fromStartDate:toEndDate:completion:`
  - `fetchSensorDataCountOfDeviceId:sensorDefinition:fromStartDate:toEndDate:completion:`

## Usage

### Initialize mnubo

We recommend to use only one instance of the mnubo SDK in your application and should initialize the object as follows:

```objc
#import <mnuboSDK/mnubo.h>

...

_mnuboSDK = [[mnubo alloc] initWithAccountName:@"ACCOUNT_NAME"
                                     namespace:@"NAMESAPCE"
                         readAccessConsumerKey:@"READ_ACCESS_CONSUMER_KEY"
                      readAccessConsumerSecret:@"READ_ACCESS_CONSUMER_SECRET"
                        writeAccessConsumerKey:@"WRITE_ACCESS_CONSUMER_KEY"
                     writeAccessConsumerSecret:@"WRITE_ACCESS_CONSUMER_SECRET"];
```

### Create an object

```objc

MBOObject *newObject = [[MBOObject alloc] init];
newObject.deviceId = @"DEVICE_ID";
newObject.objectModelName = @"OBJECT_MODEL_NAME";
newObject.registrationDate = [NSDate date]; // optional

[_mnuboSDK createObject:newObject updateIfAlreadyExist:YES completion:^(MBOObject *newlyCreatedObject, MBOError *error) {
}];

```

### Create an user

```objc

MBOUser *newUser = [[MBOUser alloc] init];
newUser.username = @"USERNAME";
newUser.password = @"USER_PASSWORD"; // optional
newUser.firstName = @"USER_FIRST_NAME"; // optional
newUser.lastName = @"USER_LAST_NAME"; // optional
newUser.registrationDate = [NSDate date]; // optional

[_mnuboSDK createUser:newUser updateIfAlreadyExist:YES completion:^(MBOError *error) {
}];

```

### Post Sensor Data

```objc

MBOSensorDefinition *sensorDefinition = [newlyCreatedObject getSensorDefinitionOfSensorName:@"SENSOR_NAME"];
MBOSensorData *sensorData = [[MBOSensorData alloc] initWithSensorDefinition:sensorDefinition];
[sensorData setValue:@(10) forSensorValueName:@"FLOAT_SENSOR_VALUE_NAME"];
[sensorData setValue:@"VALUE" forSensorValueName:@"STRING_SENSOR_VALUE_NAME"];

[_mnuboSDK sendSensorData:@[sensorData] forDeviceId:newlyCreatedObject.deviceId completion:^(MBOError *error) {  
}];

```

All the "sendSensorData" methods have an internal retry mechanism, if the send failed with a retryable error (also if there is no internet connection), the errorCode of the MBOError of the completion block will be set to MBOErrorCodeWillBeRetryLaterAutomatically and the job will be retry after the number of seconds configured in sensorDataRetryInterval (default to 30 seconds). The retry queue is persisted on disk, so the jobs will be retried also after a restart of the application. If you want to disable that feature you can set the property disableSensorDataInternalRetry to NO on your mnubo object.

### Fetch Sensor Data

```objc

MBOSensorDefinition *sensorDefinition = [newlyCreatedObject getSensorDefinitionOfSensorName:@"SENSOR_NAME"];

[_mnuboSDK fetchLastSensorDataOfObjectId:newlyCreatedObject.objectId sensorDefinition:sensorDefinition completion:^(MBOSensorData *sensorData, MBOError *error) {
}];

```
