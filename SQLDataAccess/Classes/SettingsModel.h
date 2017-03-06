//
//  SettingsModel.h
//  AppIOS
//
//  Created by Pat Murphy on 5/16/14.
//  Copyright (c) 2014 Fitamatic All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsModel : NSObject

+(void)logout;
+(void)setUserName:(NSString*)userName;
+(NSString*)getUserName;
+(void)setCountry:(NSString*)country;
+(NSString*)getCountry;
+(void)setUserId:(NSNumber*)userId;
+(NSNumber*)getUserId;
+(NSString*)getUserStrId;
+(void)setGotNewOne:(BOOL)gotNewOne;
+(BOOL)getGotNewOne;
+(void)setDBPW0:(NSString*)someStr;
+(NSString*)getDBPW0;
+(void)setDBPW1:(NSString*)someStr;
+(NSString*)getDBPW1;
+(void)setDBIsEncrypted:(BOOL)dbEncrpted;
+(BOOL)getDBIsEncrypted;
+(void)setDBCanEncrypt:(BOOL)dbEncrpted;
+(BOOL)getDBCanEncrypt;
+(NSString*)getBuildDate;
+(void)setLoginState:(BOOL)loginState;
+(BOOL)getLoginState;
+(NSString*)getAppVersion;
+(NSString*)getBuildValue;
+(NSString*)getBuildVersion;
//Used for Performance measuring
+(void)setStartDateTimeStamp:(NSString*)startDateTime forIndex:(int)index;
+(void)setFinishDateTimeStamp:(NSString*)finishDateTime forIndex:(int)index;
+(NSTimeInterval)getStartToFinishTimeForIndex:(int)index;

@end
