# SQLDataAccess

[![CI Status](http://img.shields.io/travis/pmurphyjam/SQLDataAccess.svg?style=flat)](https://travis-ci.org/pmurphyjam/SQLDataAccess)
[![Version](https://img.shields.io/cocoapods/v/SQLDataAccess.svg?style=flat)](http://cocoapods.org/pods/SQLDataAccess)
[![License](https://img.shields.io/cocoapods/l/SQLDataAccess.svg?style=flat)](http://cocoapods.org/pods/SQLDataAccess)
[![Platform](https://img.shields.io/cocoapods/p/SQLDataAccess.svg?style=flat)](http://cocoapods.org/pods/SQLDataAccess)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

SQLDataAccess is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
use_frameworks!
target "YourAppName" do
pod "SQLDataAccess"
end
```
Create a database named: "Example.db" and put it in your NSBundle directory.

    DROP TABLE IF EXISTS "AppInfo";
    CREATE TABLE "AppInfo" (
	 "ID" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
	 "name" text,
	 "value" text,
	 "descrip" text
    );
    
Now in your AppDelegate : didFinishLaunchingWithOptions 

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
    
    In AppDelegate : applicationDidEnterBackground
    [[AppManager DataAccess] closeConnection];
        
    In AppDelegate : applicationDidBecomeActive
    [[AppManager DataAccess] openConnection];

This is what the App should do:

    1) Copy Example.db to the Documents directory, remember you have to create it first, and add it to your Xcode project!
    2) Access it, and writes into it, 'App', '1.2', 'Database works'
    3) If it works you see in the console

    AppDelegate : dataArray = (
        {
        ID = 1;
        descrip = "Database works";
        name = App;
        value = "1.2";
    }
    
    For a more complicated example using SQL Transactions see:
    [ABExample](https://github.com/pmurphyjam/ABExample)
    Using the same SQLDataAcess class.

## Author

pmurphyjam, pmurphyjam@gmail.com

## License

SQLDataAccess is available under the MIT license. See the LICENSE file for more info.
