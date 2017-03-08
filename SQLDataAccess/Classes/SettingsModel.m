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

@synthesize prefs;

- (id)init {
    if (self = [super init]) {
        self.prefs = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

+ (instancetype)settings
{
    static SettingsModel *settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [[self alloc] init];
    });
    return settings;
}

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
    [[[SettingsModel settings] prefs] setObject:userName forKey:@"UserName"];
}

+(NSString*)getUserName
{
    return [[[SettingsModel settings] prefs] objectForKey:@"UserName"];
}

+(void)setUserId:(NSNumber*)userId
{
    [[[SettingsModel settings] prefs] setObject:userId forKey:@"UserID"];
}

+(NSNumber*)getUserId
{
    NSNumber *userId = [[[SettingsModel settings] prefs] objectForKey:@"UserID"];
    if ([userId isKindOfClass:[NSNull class]] || userId == nil)
        userId = [NSNumber numberWithInt:-1];
    return userId;
}

+(NSString*)getUserStrId
{
    NSNumber *userId = [[[SettingsModel settings] prefs] objectForKey:@"UserID"];
    if ([userId isKindOfClass:[NSNull class]] || userId == nil)
        userId = [NSNumber numberWithInt:-1];
    return [NSString stringWithFormat:@"%@",userId];
}

+(void)setDBPW0:(NSString*)someStr
{
    [[[SettingsModel settings] prefs] setObject:[AppManager AES256Encrypt:someStr] forKey:@"SOMESTR0"];
}

+(NSString*)getDBPW0
{
    return [AppManager AES256Decrypt:[[[SettingsModel settings] prefs] objectForKey:@"SOMESTR0"]];
}

+(void)setDBPW1:(NSString*)someStr
{
    [[[SettingsModel settings] prefs] setObject:[AppManager AES256Encrypt:someStr] forKey:@"SOMESTR1"];
}

+(NSString*)getDBPW1
{
    return [AppManager AES256Decrypt:[[[SettingsModel settings] prefs] objectForKey:@"SOMESTR1"]];
}

+(void)setGotNewOne:(BOOL)gotNewOne
{
    [[[SettingsModel settings] prefs] setBool:gotNewOne forKey:@"GotNewOne"];
}

+(BOOL)getGotNewOne
{
    return [[[SettingsModel settings] prefs] boolForKey:@"GotNewOne"];
}

+(void)setDBIsEncrypted:(BOOL)dbEncrpted
{
    [[[SettingsModel settings] prefs] setBool:dbEncrpted forKey:@"DBEncrypted"];
}

+(BOOL)getDBIsEncrypted;
{
    return [[[SettingsModel settings] prefs] boolForKey:@"DBEncrypted"];
}

+(void)setDBCanEncrypt:(BOOL)dbEncrpted
{
    [[[SettingsModel settings] prefs] setBool:dbEncrpted forKey:@"CanEncrypt"];
}

+(BOOL)getDBCanEncrypt;
{
    return [[[SettingsModel settings] prefs] boolForKey:@"CanEncrypt"];
}

+(NSString*)getBuildDate
{
    NSString *buildDate =[[[NSBundle mainBundle] infoDictionary] valueForKey:@"BuildDate"];
    return buildDate;
}

+(void)setLoginState:(BOOL)loginState
{
    [[[SettingsModel settings] prefs] setBool:loginState forKey:@"LoginState"];
}

+(BOOL)getLoginState
{
    return [[[SettingsModel settings] prefs] boolForKey:@"LoginState"];
}

+(void)setCountry:(NSString*)country
{
    [[[SettingsModel settings] prefs] setObject:country forKey:@"Country"];
}

+(NSString*)getCountry
{
    return [[[SettingsModel settings] prefs] objectForKey:@"Country"];
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
    NSString *startKey = [NSString stringWithFormat:@"StartDateTime%d",index];
    [[[SettingsModel settings] prefs] setObject:startDateTime forKey:startKey];
}

+(void)setFinishDateTimeStamp:(NSString*)finishDateTime forIndex:(int)index
{
    NSString *finishKey = [NSString stringWithFormat:@"FinishDateTime%d",index];
    [[[SettingsModel settings] prefs] setObject:finishDateTime forKey:finishKey];
}

+(NSTimeInterval)getStartToFinishTimeForIndex:(int)index
{
    NSString *startKey = [NSString stringWithFormat:@"StartDateTime%d",index];
    NSString *finishKey = [NSString stringWithFormat:@"FinishDateTime%d",index];
    NSString *startDateStr = [[[SettingsModel settings] prefs] objectForKey:startKey];
    NSString *finishDateStr = [[[SettingsModel settings] prefs] objectForKey:finishKey];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    NSDate *startDate = [dateFormatter dateFromString:startDateStr];
    NSDate *finishDate = [dateFormatter dateFromString:finishDateStr];
    NSTimeInterval secondsBetween = [finishDate timeIntervalSinceDate:startDate];
    return secondsBetween;
}

@end
