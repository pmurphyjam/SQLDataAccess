//
//  DAAppDelegate.m
//  SQLDataAccess
//
//  Created by pmurphyjam on 03/05/2017.
//  Copyright (c) 2017 pmurphyjam. All rights reserved.
//

#import "DAAppDelegate.h"
#import "AppManager.h"
#import "SettingsModel.h"

@implementation DAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //Set some fake user for now
    if(![SettingsModel getLoginState])
    {
        [SettingsModel setUserName:@"John Smith"];
        [SettingsModel setUserId:[NSNumber numberWithInt:1]];
        [SettingsModel setCountry:@"USA"];
    }
#ifdef ENCRYPT
    //Set this just once! These are required for SQLCipher and encryption since the passwords
    //are always used for the encryption keys plus some salt
    if(![SettingsModel getLoginState])
    {
        [SettingsModel setDBPW0:@"1260793RTgu"];
        [SettingsModel setDBPW1:@"1260793RTgu"];
    }
    [SettingsModel setDBCanEncrypt:YES];
#endif
    
    [SettingsModel setLoginState:YES];
    
    [AppManager InitializeAppManager];
    //Open the Database. Typically you wouldn't do this until a user has enter a password first
    //In the login or signin views. Never open the DB with Encryption until you have a password present.
    
    //Always open the DB when the App initializes, this applys the encryption keys if the DB is encrypted
    //so the DB can be read, this is only done once, but if called more then once it's no harm since
    //it will only execute once.
    [[AppManager SQLDataAccess] openConnection];
    
    BOOL status = NO;
    NSMutableArray *dataArray = [[AppManager SQLDataAccess] GetRecordsForQuery:@"select name from AppInfo ",nil];
    if([dataArray count] > 0)
    {
        NSString *appName = [[dataArray objectAtIndex:0] objectForKey:@"name"];
        if([appName isEqualToString:@"App"])
            status = YES;
    }
    
    if(status)
    {
        BOOL executeStatus = [[AppManager SQLDataAccess] ExecuteStatement:@"update AppInfo set name = ?, value = ? ,descrip = ?",@"App",@"1.2",@"Database works",nil];
    }
    else
    {
        BOOL executeStatus = [[AppManager SQLDataAccess] ExecuteStatement:@"insert into AppInfo (name,value,descrip) values(?,?,?)",@"App",@"1.2","Database works",nil];
    }
    
    dataArray = [[AppManager SQLDataAccess] GetRecordsForQuery:@"select * from AppInfo ",nil];
    
    NSLog(@"AppDelegate : dataArray = %@",dataArray);
    
    /*
     //You'll see this if the Database worked
     AppDelegate : dataArray = (
     {
     ID = 1;
     descrip = "Database works";
     name = App;
     value = "1.2";
     }
     )
     */
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
