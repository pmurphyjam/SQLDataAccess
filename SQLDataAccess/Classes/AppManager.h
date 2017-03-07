//
//  AppManager.h
//  AppIOS
//
//  Created by Pat Murphy on 5/16/14.
//  Copyright (c) 2014 Fitamatic All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "SQLDataAccess.h"
#include "SQLDataAccess.h"
//#import <SQLDataAccess/SQLDataAccess.h>
#import "UTCDate.h"
#import "SettingsModel.h"

@interface AppManager : NSObject

+(void)InitializeAppManager;
+(BOOL)OpenDBConnection;
+(void)CloseDBConnection;
+(void)KillDB;
+(SQLDataAccess*)SQLDataAccess;
+(NSString*)UTCDateTime;
+(UTCDate*)UTCDate;
+(NSString*)PathForFileWithName:(NSString*)fileName;
+(BOOL)DoesFileExistWithName:(NSString*)fileName;
+(BOOL)DeleteFileWithName:(NSString*)fileName;
+(BOOL)DoesLibraryFileExistWithName:(NSString*)fileName;
+(BOOL)DeleteLibraryFileWithName:(NSString*)fileName;
+(NSString*)ReturnPathForLibraryFileWithName:(NSString*)fileName;
+(NSMutableData*)AES256Encrypt:(NSString*)plainText;
+(NSString*)AES256Decrypt:(NSMutableData*)encryptData;

@end
