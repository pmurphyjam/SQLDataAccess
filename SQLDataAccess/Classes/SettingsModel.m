//
//  SettingsModel.m
//  AppIOS
//
//  Created by Pat Murphy on 5/16/14.
//  Copyright (c) 2014 Fitamatic All rights reserved.
//
//  Info : Centralized Settings for the App, stored in a plist.
//

#import "SettingsModel.h"
#import "AppManager.h"

@implementation SettingsModel

__strong static NSUserDefaults *prefs;
__strong static NSDictionary *brandDic;

+(void)logout
{
    [self resetDefaults];
}

+ (void)resetDefaults
{
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    for (id key in dict) {
        [defs removeObjectForKey:key];
    }
    [defs synchronize];
}

+(void)setUserName:(NSString*)userName{
	prefs = [NSUserDefaults standardUserDefaults];
	[prefs setObject:userName forKey:@"UserName"];
}

+(NSString*)getUserName
{
	prefs = [NSUserDefaults standardUserDefaults];
	return [prefs objectForKey:@"UserName"];
}

+(void)setUserId:(NSNumber*)userId
{
    prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:userId forKey:@"UserID"];
}

+(NSNumber*)getUserId
{
    prefs = [NSUserDefaults standardUserDefaults];
    NSNumber *userId = [prefs objectForKey:@"UserID"];
    if ([userId isKindOfClass:[NSNull class]] || userId == nil)
        userId = [NSNumber numberWithInt:-1];
    return userId;
}

+(NSString*)getUserStrId
{
    prefs = [NSUserDefaults standardUserDefaults];
    NSNumber *userId = [prefs objectForKey:@"UserID"];
    if ([userId isKindOfClass:[NSNull class]] || userId == nil)
        userId = [NSNumber numberWithInt:-1];
    return [NSString stringWithFormat:@"%@",userId];
}

+(void)setDBPW0:(NSString*)someStr
{
    prefs = [NSUserDefaults standardUserDefaults];
	[prefs setObject:[AppManager AES256Encrypt:someStr] forKey:@"SOMESTR0"];
}

+(NSString*)getDBPW0
{
    [[NSUserDefaults standardUserDefaults] synchronize];
	prefs = [NSUserDefaults standardUserDefaults];
	return [AppManager AES256Decrypt:[prefs objectForKey:@"SOMESTR0"]];
}

+(void)setDBPW1:(NSString*)someStr
{
    prefs = [NSUserDefaults standardUserDefaults];
	[prefs setObject:[AppManager AES256Encrypt:someStr] forKey:@"SOMESTR1"];
}

+(NSString*)getDBPW1
{
    [[NSUserDefaults standardUserDefaults] synchronize];
	prefs = [NSUserDefaults standardUserDefaults];
	return [AppManager AES256Decrypt:[prefs objectForKey:@"SOMESTR1"]];
}

+(void)setGotNewOne:(BOOL)gotNewOne
{
	prefs = [NSUserDefaults standardUserDefaults];
	[prefs setBool:gotNewOne forKey:@"GotNewOne"];
}

+(BOOL)getGotNewOne
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	prefs = [NSUserDefaults standardUserDefaults];
	return [prefs boolForKey:@"GotNewOne"];
}

+(void)setDBIsEncrypted:(BOOL)dbEncrpted
{
	prefs = [NSUserDefaults standardUserDefaults];
	[prefs setBool:dbEncrpted forKey:@"DBEncrypted"];
}

+(BOOL)getDBIsEncrypted;
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	prefs = [NSUserDefaults standardUserDefaults];
	return [prefs boolForKey:@"DBEncrypted"];
}

+(void)setDBCanEncrypt:(BOOL)dbEncrpted
{
    prefs = [NSUserDefaults standardUserDefaults];
    [prefs setBool:dbEncrpted forKey:@"CanEncrypt"];
}

+(BOOL)getDBCanEncrypt;
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    prefs = [NSUserDefaults standardUserDefaults];
    return [prefs boolForKey:@"CanEncrypt"];
}

+(NSString*)getBuildDate
{
    NSString *buildDate =[[[NSBundle mainBundle] infoDictionary] valueForKey:@"BuildDate"];
	return buildDate;
}

+(void)setLoginState:(BOOL)loginState
{
    prefs = [NSUserDefaults standardUserDefaults];
	[prefs setBool:loginState forKey:@"LoginState"];
}

+(BOOL)getLoginState
{
    [[NSUserDefaults standardUserDefaults] synchronize];
	prefs = [NSUserDefaults standardUserDefaults];
	return [prefs boolForKey:@"LoginState"];
}

+(void)setCountry:(NSString*)country
{
    prefs = [NSUserDefaults standardUserDefaults];
	[prefs setObject:country forKey:@"Country"];
}

+(NSString*)getCountry
{
    prefs = [NSUserDefaults standardUserDefaults];
	return [prefs objectForKey:@"Country"];
}

+(NSString*)getAppVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

+(NSString*)getBuildValue
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
}

+(NSString*)getBuildVersion
{
    NSString * version = [self getAppVersion];
    NSString * build = [self getBuildValue];
    NSString * versionBuild = [NSString stringWithFormat: @"v%@", version];
    if (![version isEqualToString: build])
    {
        versionBuild = [NSString stringWithFormat: @"%@(%@)", versionBuild, build];
    }
    return versionBuild;
}

//Used for Performance measuring
+(void)setStartDateTimeStamp:(NSString*)startDateTime forIndex:(int)index
{
    prefs = [NSUserDefaults standardUserDefaults];
    NSString *startKey = [NSString stringWithFormat:@"StartDateTime%d",index];
    [prefs setObject:startDateTime forKey:startKey];
}

+(void)setFinishDateTimeStamp:(NSString*)finishDateTime forIndex:(int)index
{
    prefs = [NSUserDefaults standardUserDefaults];
    NSString *finishKey = [NSString stringWithFormat:@"FinishDateTime%d",index];
	[prefs setObject:finishDateTime forKey:finishKey];
}

+(NSTimeInterval)getStartToFinishTimeForIndex:(int)index
{
    prefs = [NSUserDefaults standardUserDefaults];
    NSString *startKey = [NSString stringWithFormat:@"StartDateTime%d",index];
    NSString *finishKey = [NSString stringWithFormat:@"FinishDateTime%d",index];
    NSString *startDateStr = [prefs objectForKey:startKey];
    NSString *finishDateStr = [prefs objectForKey:finishKey];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    NSDate *startDate = [dateFormatter dateFromString:startDateStr];
    NSDate *finishDate = [dateFormatter dateFromString:finishDateStr];
    NSTimeInterval secondsBetween = [finishDate timeIntervalSinceDate:startDate];
    return secondsBetween;
}

@end
