# SQLDataAccess

[![CI Status](http://img.shields.io/travis/pmurphyjam/SQLDataAccess.svg?style=flat)](https://travis-ci.org/pmurphyjam/SQLDataAccess)
[![Version](https://img.shields.io/cocoapods/v/SQLDataAccess.svg?style=flat)](http://cocoapods.org/pods/SQLDataAccess)
[![License](https://img.shields.io/cocoapods/l/SQLDataAccess.svg?style=flat)](http://cocoapods.org/pods/SQLDataAccess)
[![Platform](https://img.shields.io/cocoapods/p/SQLDataAccess.svg?style=flat)](http://cocoapods.org/pods/SQLDataAccess)

## Example

To run the example project, clone the repo, and run `>pod install` from the directory where your Podfile is located first.
To get the latest version, run `>pod update` from the directory where your Podfile is located.

## Requirements

You should use Xcode 8.0+, and iOS10.0+ to run this CocoaPod's.

## Installation

SQLDataAccess is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
use_frameworks!
target "YourAppTargetName" do
pod "SQLDataAccess"
end
```
Copy the database named "Example.db" located in:
SQLDataAccess/SQDataAccess/Resources/Example.db
And put it anywhere in your NSBundle directory and make sure it's visible
in Xcode's Project Navigator by dragging it into Xcode. The name is dictated
by the define in AppConstants.h DB_FILE and DB_FILEX.

"Example.db" has the following info in it, the SQL to create it is below.

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
    //If you want to run SQLCipher, add ENRYPT to Xcode project's :
    //Apple LLVM 8.0 - Preprocessing : Preprocessor Macros
    #ifdef ENCRYPT
    //Set this just once! These are required for SQLCipher and encryption since the
    //passwords are always used for the encryption keys plus some salt. 
    //SQLDataAccess explains how to use SQLCipher instead of SQLite, you need the 
    //libsqlcipher-ios.a added to your project.
    if(![SettingsModel getLoginState])
    {
        [SettingsModel setDBPW0:@"1260793RTgu"];
        [SettingsModel setDBPW1:@"1260793RTgu"];
    }
    [SettingsModel setDBCanEncrypt:YES];
    #endif
    
    //This register tells SQLDataAccess the database is Ok to access now
    //If the Database can't be accessed this register will get set to NO
    //And a warning will print out in the Console.
    [SettingsModel setLoginState:YES];
    
    [AppManager InitializeAppManager];
    //Open the Database. Typically you wouldn't do this until a user has entered
    //a password first from the login or signin views. 
    //Never open the DB with Encryption until you have a password present in 
    //getDBPW0, otherwise the DB will fail to open and will fail every single SQL
    //query.
    
    //Always open the DB when the App initializes, this applys the encryption keys
    //if the DB is encrypted so the DB can be read, this is only done once, but if 
    //it's called more then once it's no harm since it will only execute once.
    //For a non-encrypted or plain-text DB this open's the DB's connection 
    //SQLDataAccess : sqlite3dbConn
    [[AppManager SQLDataAccess] openConnection];
    
    //Lets read the database first to see if the table AppInfo exists and has a 
    //column of 'name' which contains the value 'App', this is mostly a sanity 
    //check.
    BOOL status = NO;
    //A very basic SQL select statement, super simple to write!
    NSMutableArray *dataArray = 
    [[AppManager SQLDataAccess] GetRecordsForQuery:@"select name from AppInfo ",nil];
    if([dataArray count] > 0)
    {
    	//If you setup Example.db correctly, the App will come here
        NSString *appName = [[dataArray objectAtIndex:0] objectForKey:@"name"];
        if([appName isEqualToString:@"App"])
            status = YES;
    }
    
    if(status)
    {
        //The table should exist so the App should come here and update the table
	//with this info.
	//See how easy the SQL is to write for an update! 
	//Just add your parameters after the query, don't forget the nil, it's required!
	//If the SQL is messed up, SQLDataAccess will print out an error in the console
	//telling you where SQL is wrong!
	
        BOOL executeStatus = 
	[[AppManager SQLDataAccess] ExecuteStatement:@"update AppInfo set name = ?, value = ? ,descrip = ?"
	,@"App",@"1.2",@"Database works",nil];
    }
    else
    {
    	//See how easy the SQL is to write for an insert! 
	//Just add your parameters after the query!
        BOOL executeStatus = 
	[[AppManager SQLDataAccess] ExecuteStatement:@"insert into AppInfo (name,value,descrip) values(?,?,?)"
	,@"App",@"1.2","Database works",nil];
    }
    
    //Now read the 'AppInfo' table and display it in the Console log window.
    //See how easy the SQL is to write for a select!
    //If you have a where clause just add it's parameters after the query!
    dataArray = [[AppManager SQLDataAccess] GetRecordsForQuery:@"select * from AppInfo ",nil];
    
    NSLog(@"AppDelegate : dataArray = %@",dataArray);
    
Now in your AppDelegate : applicationDidEnterBackground

    //This closes the DB when the App goes into the background. 
    //This is important and secures your database.
    [[AppManager DataAccess] closeConnection];
        
Now in your AppDelegate : applicationDidBecomeActive
	
    //This opens the DB when the App becomes active again, and if it's encrypted it 
    //applies the encryption keys again.
    //If you don't open the DB, the connection won't be valid, and no SQL will execute.
    [[AppManager DataAccess] openConnection];

This is what the App should do:

    1) On the first initialization, the App copies Example.db to the App's working Documents
       directory so it can access it. Remember you have to copy 'Example.db' first, and add 
       it to your Xcode project!
    2) The App then accesses 'Example.db', and writes into it, 'App', '1.2', 'Database works'
    3) If it works you see this in the console

    AppDelegate : dataArray = (
        {
        ID = 1;
        descrip = "Database works";
        name = App;
        value = "1.2";
    }
    
## For a more complicated example using SQL Transactions see:
[ABExample](https://github.com/pmurphyjam/ABExample)
Using the same SQLDataAcess class.

## Author

pmurphyjam, pmurphyjam@gmail.com

## License

SQLDataAccess is available under the MIT license. See the LICENSE file for more info.
