//
//  MBOUser.m
//  
//  Copyright (c) 2015 mnubo. All rights reserved.
//

#import "MBOUser.h"
#import "MBODateHelper.h"
#import "MBOMacros.h"
#import "MBOAttribute+Private.h"

NSString const * kMBOUserUserIdKey = @"userId";
NSString const * kMBOUserUsernameKey = @"username";
NSString const * kMBOUserPasswordKey = @"password";
NSString const * kMBOUserConfirmedPasswordKey = @"confirmed_password";
NSString const * kMBOUserFirstNameKey = @"firstname";
NSString const * kMBOUserLastNameKey = @"lastname";
NSString const * kMBOUserRegistrationDateKey = @"registration_date";
NSString const * kMBOUserAttributesKey = @"attributes";

@interface MBOUser ()
{
    NSMutableArray *_innerAttributes;
}

@property(nonatomic, readwrite, copy) NSString *userId;

@end

@implementation MBOUser

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _innerAttributes = [NSMutableArray array];
        _registrationDate = [NSDate date];
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self)
    {
        _innerAttributes = [NSMutableArray array];
        _registrationDate = [NSDate date];
        
        _userId = [dictionary objectForKey:kMBOUserUserIdKey];
        _username = [dictionary objectForKey:kMBOUserUsernameKey];
        _firstName = [dictionary objectForKey:kMBOUserFirstNameKey];
        _lastName = [dictionary objectForKey:kMBOUserLastNameKey];
        
        if ([dictionary objectForKey:kMBOUserRegistrationDateKey])
        {
            _registrationDate = [MBODateHelper dateFromMnuboString:[dictionary objectForKey:kMBOUserRegistrationDateKey]];
        }

        NSMutableArray *attributes = [NSMutableArray array];
        NSArray *attributesDictionaries = [dictionary objectForKey:kMBOUserAttributesKey];
        [attributesDictionaries enumerateObjectsUsingBlock:^(NSDictionary *attributeDictionary, NSUInteger idx, BOOL *stop)
        {
            MBOAttribute *attribute = [[MBOAttribute alloc] initWithDictionary:attributeDictionary];
            if (attribute)
            {
                [attributes addObject:attribute];
            }
        }];
        
        _innerAttributes = attributes;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        _userId = [aDecoder decodeObjectForKey:@"userId"];
        _username = [aDecoder decodeObjectForKey:@"username"];
        _password = [aDecoder decodeObjectForKey:@"password"];
        _confirmedPassword = [aDecoder decodeObjectForKey:@"confirmedPassword"];
        _firstName = [aDecoder decodeObjectForKey:@"firstName"];
        _lastName = [aDecoder decodeObjectForKey:@"lastName"];
        _registrationDate = [aDecoder decodeObjectForKey:@"registrationDate"];
        _innerAttributes = [aDecoder decodeObjectForKey:@"attributes"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_userId forKey:@"userId"];
    [encoder encodeObject:_username forKey:@"username"];
    [encoder encodeObject:_password forKey:@"password"];
    [encoder encodeObject:_confirmedPassword forKey:@"confirmedPassword"];
    [encoder encodeObject:_firstName forKey:@"firstName"];
    [encoder encodeObject:_lastName forKey:@"lastName"];
    [encoder encodeObject:_registrationDate forKey:@"registrationDate"];
    [encoder encodeObject:_innerAttributes forKey:@"attributes"];
}

- (id)copyWithZone:(NSZone *)zone
{
    MBOUser *copyUser = [[MBOUser alloc] init];
    
    copyUser.userId = _userId;
    copyUser.username = _username;
    copyUser.password = _password;
    copyUser.confirmedPassword = _confirmedPassword;
    copyUser.firstName = _firstName;
    copyUser.lastName = _lastName;
    copyUser.registrationDate = _registrationDate;

    [_innerAttributes enumerateObjectsUsingBlock:^(MBOAttribute *attribute, NSUInteger idx, BOOL *stop)
    {
        [copyUser addAttribute:attribute];
    }];

    return copyUser;
}

- (BOOL)isEqual:(MBOUser *)otherUser
{
    if (![otherUser isKindOfClass:[self class]])
    {
        return NO;
    }
    
    return IsEqualToString(_userId, otherUser.userId) &&
    IsEqualToString(_username, otherUser.username) &&
    IsEqualToString(_password, otherUser.password) &&
    IsEqualToString(_confirmedPassword, otherUser.confirmedPassword) &&
    IsEqualToString(_firstName, otherUser.firstName) &&
    IsEqualToString(_lastName, otherUser.lastName) &&
    IsEqualToDate(_registrationDate, otherUser.registrationDate) &&
    IsEqualToArray(_innerAttributes, otherUser.attributes);
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash += [_userId hash];
    hash += [_username hash];
    hash += [_password hash];
    hash += [_confirmedPassword hash];
    hash += [_firstName hash];
    hash += [_lastName hash];
    hash += [_registrationDate hash];
    hash += [_innerAttributes hash];
    return hash;
}

- (NSArray *)attributes
{
    return [NSArray arrayWithArray:_innerAttributes];
}

- (void)addAttribute:(MBOAttribute *)attribute
{
    [_innerAttributes addObject:attribute];
}

- (void)insertAttribute:(MBOAttribute *)attribute atIndex:(NSInteger)index
{
    [_innerAttributes insertObject:attribute atIndex:index];
}

- (void)removeAttribute:(MBOAttribute *)attribute
{
    [_innerAttributes removeObject:attribute];
}

- (void)removeAttributeAtIndex:(NSInteger)index
{
    [_innerAttributes removeObjectAtIndex:index];
}

- (void)removeAllAttributes
{
    [_innerAttributes removeAllObjects];
}

//------------------------------------------------------------------------------
#pragma mark Public method
//------------------------------------------------------------------------------
- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    if(_username.length)
    {
        [dictionary setObject:_username forKey:kMBOUserUsernameKey];
    }

    if(_password.length)
    {
        [dictionary setObject:_password forKey:kMBOUserPasswordKey];
    }
    
    if(_confirmedPassword.length)
    {
        [dictionary setObject:_confirmedPassword forKey:kMBOUserConfirmedPasswordKey];
    }

    if(_firstName.length)
    {
        [dictionary setObject:_firstName forKey:kMBOUserFirstNameKey];
    }

    if(_lastName.length)
    {
        [dictionary setObject:_lastName forKey:kMBOUserLastNameKey];
    }

    if(_registrationDate)
    {
        [dictionary setObject:[MBODateHelper mnuboStringFromDate:_registrationDate] forKey:kMBOUserRegistrationDateKey];
    }

    NSMutableArray *attributeDictionaries = [NSMutableArray array];
    [_innerAttributes enumerateObjectsUsingBlock:^(MBOAttribute *attribute, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *attributeDictionary = [attribute toDictionary];
        if (attributeDictionary)
        {
            [attributeDictionaries addObject:attributeDictionary];
        }
    }];

    if (attributeDictionaries.count > 0)
    {
        [dictionary setObject:[NSArray arrayWithArray:attributeDictionaries] forKey:@"attributes"];
    }
    
    return dictionary;
}

//------------------------------------------------------------------------------
#pragma mark  Debug
//------------------------------------------------------------------------------

- (NSString *)description
{
    return [NSString stringWithFormat:@"MBOUser | username:%@  firstName:%@  lastName:%@ | attributes:%@", _username, _firstName, _lastName, _innerAttributes];
}

@end
