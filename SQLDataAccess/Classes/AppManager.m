//
//  AppManager.m
//  AppIOS
//
//  Created by Pat Murphy on 5/16/14.
//  Copyright (c) 2014 Fitamatic All rights reserved.
//
//  Info : Manages the app. Opens the data base also.
//  Has lots of DateFormatter methods since the DB must always store dates in UTC format.
//

#import "AppManager.h"
#import "SQLDataAccess.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCryptor.h>
#import "SettingsModel.h"

@implementation AppManager

__strong static SQLDataAccess *dataAccess;
__strong static UTCDate *utcDate;
__strong static NSDateFormatter *dateFormatter = nil;

//#define DEBUG
#import "AppConstants.h"

+(void) InitializeAppManager
{
	dataAccess = [[SQLDataAccess alloc]init];
	utcDate = [[UTCDate alloc] init];
    dateFormatter = [[NSDateFormatter alloc] init];
}

+(BOOL) OpenDBConnection;
{
	return [dataAccess openConnection];
}

+(void) CloseDBConnection
{
	[dataAccess closeConnection];
}

+(void) KillDB
{
	[dataAccess killDB];
}

+(SQLDataAccess*) SQLDataAccess
{
	return dataAccess;
}

+(NSString *) UTCDateTime
{
	dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
	NSTimeZone *utc = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	[dateFormatter setTimeZone:utc];
	NSString *UTCDatetime = [dateFormatter stringFromDate:[NSDate date]];
	return UTCDatetime;
}

+(UTCDate *) UTCDate
{
	return utcDate;
}

+(NSMutableData*)AES256Encrypt:(NSString*)plainText
{
    NSString *key = EN_KEY;
	char keyPtr[kCCKeySizeAES256+1];
    bzero( keyPtr, sizeof(keyPtr) );
    NSMutableData *data = [NSMutableData dataWithData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
	
    [key getCString: keyPtr maxLength: sizeof(keyPtr) encoding: NSUTF8StringEncoding];
    size_t numBytesEncrypted = 0;
    
    NSUInteger dataLength = [data length];
	
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
    CCCryptorStatus result = CCCrypt( kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                     keyPtr, kCCKeySizeAES256,
                                     NULL,
                                     [data mutableBytes], [data length],
                                     buffer, bufferSize,
                                     &numBytesEncrypted );
    
	
    NSMutableData *output = [NSMutableData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
	if( result == kCCSuccess )
	{
		return output;
	}
    return NULL;
}

+(NSString*)AES256Decrypt:(NSMutableData*)encryptData
{
    NSString *key = EN_KEY;
	char  keyPtr[kCCKeySizeAES256+1];
    bzero( keyPtr, sizeof(keyPtr) );
    
    NSMutableData *data = encryptData;
    
    [key getCString: keyPtr maxLength: sizeof(keyPtr) encoding: NSUTF8StringEncoding];
    
    size_t numBytesEncrypted = 0;
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer_decrypt = malloc(bufferSize);
    
    CCCryptorStatus result = CCCrypt( kCCDecrypt , kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                     keyPtr, kCCKeySizeAES256,
                                     NULL,
                                     [data mutableBytes], [data length],
                                     buffer_decrypt, bufferSize,
                                     &numBytesEncrypted );
    
    NSMutableData *output_decrypt = [NSMutableData dataWithBytesNoCopy:buffer_decrypt length:numBytesEncrypted];
    if( result == kCCSuccess )
    {
        return [[NSString alloc] initWithData:output_decrypt encoding:NSUTF8StringEncoding];
    }
    return NULL;
}

+(NSString*)PathForFileWithName:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pathForFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSURL *url = [NSURL fileURLWithPath:documentsDirectory];
    NSError *error = nil;
    //Adding this so the Documents directory is not backup to iCloud
    BOOL success = [url setResourceValue:[NSNumber numberWithBool:YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(success)
        NDLog(@"AppManager : PathForFileWithName : Documents directory Excluded From Backup SUCCESS");
    else
        NDLog(@"AppManager : PathForFileWithName : Documents directory Excluded From Backup FAILURE");
    
    return pathForFile;
}

+(BOOL)DoesFileExistWithName:(NSString*)fileName
{
    BOOL status = YES;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *pathForFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    if(![fileManager fileExistsAtPath:pathForFile])
        status = NO;
    return status;
}

+(BOOL)DeleteFileWithName:(NSString*)fileName
{
    BOOL status = YES;
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *pathForFile = [documentsDirectory stringByAppendingPathComponent:fileName];
    if ([fileManager removeItemAtPath:pathForFile error:&error] != YES)
        status = NO;
    return status;
}

@end
