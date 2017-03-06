//
//  SQLDataAccess.m
//  AppIOS
//
//  Created by Pat Murphy on 5/16/14.
//  Copyright (c) 2014 Fitamatic All rights reserved.
//
// Info : This DataAccess class controls all accesses to the SQLite Database, and greatly facilitates
// the writing of SQL statements making them easily readable, efficient and maintable. This class has
// been ran with Databases that have been in the Gigabytes for size.
//
// Additionally the Database may be fully Encrypted using SQLCipher where all accesses are fully
// Encrypted, and the Database can not be viewed unless opened with the proper Key. Once a DB is
// encrypted, it can be easily be decrypted using the method : convertDBtoPlain, and an unencrypted plain text DB
// can be easily encrypted with : convertDBtoCipher provided the encryption key is known. Also the size of
// the aes encryption key length can easily be set for different countries as defined by law.
// To use SQLCipher you must remove 'libsqlite3.0.dylib', and add 'libsqlcipher.a' along with referencing the
// SQLCipher version of <sqlite3.h>
// To use the standard SQLite, just use 'libsqlite3.0.dylib' and the standard <sqlite3.h>
//
// SQL statements take the form of an NSMutableString, and Parameters are an NSMutableArray.
// The SQL strings and parameters are typically put in an NSDictionary, and then passed to this class.
//
// Alternatively one can write short queries for GetRecordsForQuery or ExecuteStatement.
//
// For selects
// NSMutableArray = GetRecordsForQuery:@"select firstName, lastName from Company where lastName = ? ",@"Smith",nil];
// OR
// For inserts or updates
// BOOL = ExecuteStatement:@"insert into Company (firstName, lastName) values(?,?)",@"John",@"Smith", nil];
//
// GetRecordsForQuery always returns an NSMutableArray of NSDictionary's where the Key's are the DB column names,
// and the Values are the DB value contained in that column.
// ExecuteStatement always returns a BOOL which may or may not be used indicating success or failure.
//
// This class also decodes all SQL statement errors and prints out a meaningful NSLog statement with the SQLite decoded
// error making for easy debug and identification of SQL errors.
//
// All methods are thread safe, do not leak memory.
// This class can handle Integer, Floats, Doubles, NSDates, Strings, or Blobs effiencently.
// Additionally SQL transactions can be excuted by loading an NSMutableArray of SQL And Parameters statements, and
// then executed via sqlAndParamsForTransaction making for very efficient and quick inserts for large data sets.
//
// For Database's that go through revisions or addition of tables or columns, an AppInfo table can be created which
// will store the DB's current version, and this version value will then dictate what alter table commands need to be
// ran to upgrade the DB to the latest version.
//
// The SQLite Database can also be printed out or displayed in an NSLog via
// getDatabaseTables : displays all the create tables in the database.
// getDatabaseDump : displays all the tables and data in the database.
//

#import "SQLDataAccess.h"
#import "AppManager.h"
#import "UTCDate.h"

@implementation SQLDataAccess

//#define DEBUGNSQL
#import "AppConstants.h"

-(void) moveDBtoDocumentDirectory:(NSString*)dbFile
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:dbFile];
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:dbFile];
    
    if(![fileManager fileExistsAtPath:writableDBPath])
    {
        bool success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
        if (!success )
            NELog(@"DA : moveDBtoDocumentDirectory : FAILED : file = %@", writableDBPath);
        else
            NELog(@"DA : moveDBtoDocumentDirectory : SUCCESS : file = %@", writableDBPath);

    }
}

-(void) copyDBtoDocumentDirectory:(NSString*)copyDBFile toDB:(NSString*)toDBFile
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *copyDBPath = [documentsDirectory stringByAppendingPathComponent:copyDBFile];
    NSString *toDBPath = [documentsDirectory stringByAppendingPathComponent:toDBFile];
    
    if(![fileManager fileExistsAtPath:copyDBPath])
    {
        bool success = [fileManager copyItemAtPath:copyDBPath toPath:toDBPath error:&error];
        if (!success )
            NELog(@"DA : copyDBtoDocumentDirectory : FAILED : file = %@", toDBPath);
        else
            NELog(@"DA : copyDBtoDocumentDirectory : SUCCESS : file = %@", toDBPath);
    }
}

-(void) replaceDBinDocumentDirectory
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *removeDBPath = [documentsDirectory stringByAppendingPathComponent:DB_FILE];
    NSString *renameDBPath = [documentsDirectory stringByAppendingPathComponent:DB_FILEX];
    [[NSFileManager defaultManager] removeItemAtPath:removeDBPath error:&error];
    
    [[NSFileManager defaultManager] moveItemAtPath:renameDBPath
                                            toPath:removeDBPath
                                             error:&error];
    
    if(![fileManager fileExistsAtPath:removeDBPath])
        NELog(@"DA : replaceDBinDocumentDirectory : FAILED : file = %@", removeDBPath);
    else
        NELog(@"DA : replaceDBinDocumentDirectory : SUCCESS : file = %@", removeDBPath);
    
}

-(void) closeConnection
{
    NSDBLog(@"DA : sqlite3dbConn : CLOSED");
    sqlite3_close(sqlite3dbConn);
    sqlite3dbConn = nil;
}

-(void) killDB
{
    BOOL doesDBFileExist = [AppManager DoesFileExistWithName:DB_FILE];
    NSDBLog(@"DA : doesDBFileExist = %@",doesDBFileExist?@"YES":@"NO");
    NSError *error;
    NSString* dbfile = [AppManager PathForFileWithName:DB_FILE];
    
    if(doesDBFileExist)
    {
        NSFileManager *fileMgr = [NSFileManager new];
        [fileMgr contentsOfDirectoryAtPath:dbfile error:&error];
        
        if ([fileMgr removeItemAtPath:dbfile error:&error] != YES)
        {
            NELog(@"DA : Path to file: %@", dbfile);
            NELog(@"DA : Is deletable file at path: %d", [fileMgr isDeletableFileAtPath:dbfile]);
            NELog(@"DA : Unable to delete file: %@", [error localizedDescription]);
        }
        else
        {
            NSDBLog(@"DA : File was deleted %@", dbfile);
        }
    }
}

-(BOOL) openLibraryConnection:(NSString*)dbFile
{
    if(sqlite3dbConn)
        return true;
    
    NSString* dbfile = [AppManager ReturnPathForLibraryFileWithName:dbFile];
    BOOL doesDBFileExist = [AppManager DoesLibraryFileExistWithName:dbFile];
    NSDBLog(@"DA : doesDBFileExist = %@",doesDBFileExist?@"YES":@"NO");
    
    conn_pointer = (sqlite3_open([dbfile UTF8String], &sqlite3dbConn) == SQLITE_OK);
    
    if(!doesDBFileExist)
    {
        NSDBLog(@"DA : openLibraryConnection : ERROR no DBFile ");
        return false;
    }
    
    if(!conn_pointer)
    {
        NSDBLog(@"DA : Error code opening the database : %@ : %@",[NSString stringWithFormat:@"%d",sqlite3_errcode(sqlite3dbConn)],[NSString stringWithFormat:@"%s",sqlite3_errmsg(sqlite3dbConn)]);
        return false;
    }
    else
    {
        return true;
    }
}

-(BOOL)isDBOpened
{
    BOOL status = NO;
    if(sqlite3dbConn)
        status = YES;
    
    return status;
}

-(BOOL) openConnection
{
    //
    //Can only execute this once and apply the encryption key
    //
    if(sqlite3dbConn)
    {
        NSDBLog(@"DA : sqlite3dbConn : OPENED");
        return true;
    }
    else
    {
        NSDBLog(@"DA : sqlite3dbConn : OPENING DB (initialization)");
    }
    
    NSString* dbfile = [AppManager PathForFileWithName:DB_FILE];
    BOOL doesDBFileExist = [AppManager DoesFileExistWithName:DB_FILE];
    NSDBLog(@"DA : doesDBFileExist = %@",doesDBFileExist?@"YES":@"NO");
    int sqlLiteVersion = sqlite3_libversion_number();
    
    if(!doesDBFileExist)
    {
        [self moveDBtoDocumentDirectory:DB_FILE];
        dbfile = [AppManager PathForFileWithName:DB_FILE];
        conn_pointer = (sqlite3_open([dbfile UTF8String], &sqlite3dbConn) == SQLITE_OK);
        if(!conn_pointer)
        {
            NSDBLog(@"DA : Error code copying the database : %@ : %@",[NSString stringWithFormat:@"%d",sqlite3_errcode(sqlite3dbConn)],[NSString stringWithFormat:@"%s",sqlite3_errmsg(sqlite3dbConn)]);
            [self closeConnection];
            return false;
        }
        else
        {
            if(sqlLiteVersion >= SQLITE_CIPHER_VERSION)
            {
                BOOL isDBEncrypted = [SettingsModel getDBIsEncrypted];
                BOOL canEncrypt = [SettingsModel getDBCanEncrypt];
                NSDBLog(@"DA : canEncrypt = %@",canEncrypt?@"YES":@"NO");
                if(!isDBEncrypted && canEncrypt)
                {
                    NSDBLog(@"DA : convertDBtoCipher");
                    //Default DB template is never encrypted so convert it
                    [SettingsModel setStartDateTimeStamp:[AppManager UTCDateTime] forIndex:125];
                    [self convertDBtoCipher];
                    [SettingsModel setFinishDateTimeStamp:[AppManager UTCDateTime] forIndex:125];
                    NSDBLog(@"DA : convertDBtoCipher : DB Encrypted time = %f secs",[SettingsModel getStartToFinishTimeForIndex:125]);
                }
            }
        }
    }
    else
        conn_pointer = (sqlite3_open([dbfile UTF8String], &sqlite3dbConn) == SQLITE_OK);
    
    if(!conn_pointer)
    {
        NSDBLog(@"DA : Error code opening the database : %@ : %@",[NSString stringWithFormat:@"%d",sqlite3_errcode(sqlite3dbConn)],[NSString stringWithFormat:@"%s",sqlite3_errmsg(sqlite3dbConn)]);
        [self closeConnection];
        return false;
    }
    else
    {
        NELog(@"DA : Application Connection opened : SQLLite Version = %d",sqlLiteVersion);
        if(sqlLiteVersion >= SQLITE_CIPHER_VERSION)
        {
#ifdef SQLITE_HAS_CODEC
            BOOL gotNew = [SettingsModel getGotNewOne];
            if(gotNew)
            {
                NSDBLog(@"DA : Need to do something special");
                //ENCRYPT is on for Release or Production. If use this you need SQLCipher
#ifdef ENCRYPT
                //Open 1st with old one, then reapply with new one
                //This is where we rekey the cipher if we get a new one
                //Only run encryption if we have ENCRYPT
                sqlite3_key(sqlite3dbConn,[self getDBPass1],(int)strlen([self getDBPass1]));
                NSString *sql = [NSString stringWithFormat:@"PRAGMA cipher = 'aes-256-cfb';"];
                sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
                NSDBLog(@"DA : ENCRYPT REKEY #1 : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
                sqlite3_rekey(sqlite3dbConn,[self getDBPass0],(int)strlen([self getDBPass0]));
                sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
                NSDBLog(@"DA : ENCRYPT REKEY #2 : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
#endif
                [SettingsModel setGotNewOne:NO];
                NELog(@"DA:OpenConnection: ReKeying DB ");
            }
            else
            {
#ifdef ENCRYPT
                //Check DB Encrypted BOOL, if NO DB was never encrypted so convert it
                //Otherwise just open it properly
                BOOL isDBEncrypted = [SettingsModel getDBIsEncrypted];
                BOOL canEncrypt = [SettingsModel getDBCanEncrypt];
                NSDBLog(@"DA : ENCRYPT : canEncrypt = %@ :  isDBEncrypted = %@",canEncrypt?@"YES":@"NO",isDBEncrypted?@"YES":@"NO");
                
                if(!isDBEncrypted && canEncrypt)
                {
                    NSDBLog(@"DA : convertDBtoCipher : connection opened");
                    [self convertDBtoCipher];
                }
                
                if (canEncrypt)
                {
                    //Only run encryption if we have ENCRYPT
                    //Got an encrypted DB so open it with the key
                    NSDBLog(@"DA : ENCRYPT : applying KEY");
                    sqlite3_key(sqlite3dbConn,[self getDBPass0],(int)strlen([self getDBPass0]));
                    NSString *sql = [NSString stringWithFormat:@"PRAGMA cipher = 'aes-256-cfb';"];
                    sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
                    NSDBLog(@"DA : ENCRYPT : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
                }
#endif
                //If you have an encrypted DB and want to convert it back to plain use this
                //[self convertDBtoPlain];
            }
#endif
            
#ifdef ENCRYPT
            BOOL canEncrypt = [SettingsModel getDBCanEncrypt];
            if(canEncrypt)
            {
                NSMutableArray *dataArray = [self GetRecordsForQuery:@"PRAGMA cipher_version; ",nil];
                if([dataArray count] > 0)
                {
                    NSString *version = [[dataArray objectAtIndex:0] objectForKey:@"cipher_version"];
                    NELog(@"DA : Application Connection opened : SQLCipher Version = %@",version);
                }
                
                NSDBLog(@"DA : Application Connection opened : Running Encrypted");
            }
            else
            {
                NSDBLog(@"DA : Application Connection opened : Running Unencrypted");
            }
#else
            NSDBLog(@"DA : Application Connection opened : Running Unencrypted");
#endif
        }
        else
        {
            NSDBLog(@"DA : Application Connection opened : Running Unencrypted");
        }
        
        BOOL status = NO;
        if (sqlite3_exec(sqlite3dbConn, (const char*) "SELECT count(*) FROM AppInfo;", NULL, NULL, NULL) == SQLITE_OK)
        {
            if(sqlLiteVersion >= SQLITE_CIPHER_VERSION)
            {
                NSDBLog(@"DA : Primary DB connection opened SQLCipher.");
            }
            else
            {
                NSDBLog(@"DA : Primary DB connection opened Regular SQL.");
            }
            status = YES;
            //If we're upgrading an Old Client of version 1.2 then SQLCipher DB needs to be upgraded
            double dbVersion = [self getDBVersion];
            [self upgradeDB:dbVersion];
        }
        else
        {
            if(sqlLiteVersion >= SQLITE_CIPHER_VERSION)
            {
                NELog(@"DA : PRIMARY DB OPEN ENCRYPTION FAILURE!");
                [SettingsModel setLoginState:NO];
            }
            else
            {
                NELog(@"DA : PRIMARY DB OPEN FAILURE.");
                [SettingsModel setLoginState:NO];
            }
            status = NO;
            [self closeConnection];
        }
        return status;
    }
}

-(const char*)getDBPass0
{
    NSString *some0 = [SettingsModel getDBPW0];
    const char *ss = [[NSString stringWithFormat:@"ft67s%@58uy%@fge4",DB_KEY,some0] UTF8String];
#ifdef DEV
    NSDBLog(@"DA : %s ",ss);
#endif
    return ss;
}

-(const char*)getDBPass1
{
    NSString *some1 = [SettingsModel getDBPW1];
    const char *ss = [[NSString stringWithFormat:@"ft67s%@58uy%@fge4",DB_KEY,some1] UTF8String];
    return ss;
}

-(void)createPass
{
    NSString *some0 = [SettingsModel getDBPW0];
    if([some0 length] == 0)
    {
        //User never had a proper password so create a random one for them. They can change this later.
        //Here we just do this, and then let SQLCipher encrypt the DB with this.
        //We also need to add the modificationDate to UserContacts
        [SettingsModel setDBPW0:@"1260793RTgu"];
        NELog(@"DA:OpenConnection: Creating Dummy ");
    }
}

-(void)convertDBtoCipher
{
#ifdef ENCRYPT
    //Only run encryption if we have ENCRYPT
    //Only do this if we have the SQLITE_CIPHER_VERSION
    //Copy the existing DB_FILE to DB_FILEX, encrypt DB_FILEX and then remove DB_FILE, and rename
    //DB_FILEX to DB_FILE
    [self copyDBtoDocumentDirectory:DB_FILE toDB:DB_FILEX];
    NSString *dbfileX = [AppManager PathForFileWithName:DB_FILEX];
    NSString *sql = [NSString stringWithFormat:@"attach database '%@' as encrypted KEY '%s';",dbfileX,[self getDBPass0]];
    sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
    NSDBLog(@"DA : convertDBtoCipher : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
    sql = [NSString stringWithFormat:@"select sqlcipher_export('encrypted');"];
    sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
    NSDBLog(@"DA : convertDBtoCipher : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
    sql = [NSString stringWithFormat:@"detach database encrypted;"];
    sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
    NSDBLog(@"DA : convertDBtoCipher : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
    [self replaceDBinDocumentDirectory];
    NSDBLog(@"DA : convertDBtoCipher : DB is ENCRYPTED ");
    [SettingsModel setDBIsEncrypted:YES];
    NSString *dbfile = [AppManager PathForFileWithName:DB_FILE];
    conn_pointer = (sqlite3_open([dbfile UTF8String], &sqlite3dbConn) == SQLITE_OK);
#endif
}

-(void)convertDBtoPlain
{
    //Only do this if we have the SQLITE_CIPHER_VERSION
    //Copy the existing DB_FILE to DB_FILEX, encrypt DB_FILEX and then remove DB_FILE, and rename
    //DB_FILEX to DB_FILE
    [self copyDBtoDocumentDirectory:DB_FILE toDB:DB_FILEX];
    NSString *dbfileX = [AppManager PathForFileWithName:DB_FILEX];
    NSString *sql = [NSString stringWithFormat:@"attach database '%@' as plaintext KEY '';",dbfileX];
    sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
    NSDBLog(@"DA : convertDBtoPlain : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
    sql = [NSString stringWithFormat:@"select sqlcipher_export('plaintext');"];
    sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
    NSDBLog(@"DA : convertDBtoPlain : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
    sql = [NSString stringWithFormat:@"detach database plaintext;"];
    sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
    NSDBLog(@"DA : convertDBtoCipher: sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
    [self replaceDBinDocumentDirectory];
    NSDBLog(@"DA :convertDBtoPlain : DB is UNENCRYPTED ");
    [SettingsModel setDBIsEncrypted:NO];
    NSString *dbfile = [AppManager PathForFileWithName:DB_FILE];
    conn_pointer = (sqlite3_open([dbfile UTF8String], &sqlite3dbConn) == SQLITE_OK);
}

-(double)getDBVersion
{
    //Need to check for old DB and App version 1.0, the AppInfo will have nothing in it
    double version = 0.0;
    NSMutableString *sql = [NSMutableString string];
    NSMutableArray *parameters = [NSMutableArray array];
    [sql appendString:@"select name,value,descrip from AppInfo"];
    NSMutableArray *resultsArray = [[AppManager SQLDataAccess] GetRecordsForQuery:sql WithParameters:parameters];
    NSDBLog(@"DA : getDBVersion : results = %@",resultsArray);
    BOOL isDBEncrypted = [SettingsModel getDBIsEncrypted];
    
    if([resultsArray count] == 0)
    {
        NSMutableString *sql = [NSMutableString string];
        NSMutableArray *parameters = [NSMutableArray array];
        [parameters addObject:@"App"];
        [parameters addObject:@"1.1"];
        if(isDBEncrypted)
            [parameters addObject:@"encrypted"];
        else
            [parameters addObject:@"unencrypted"];
        
        [sql appendString:@"insert into AppInfo (name,value,descrip) values(?,?,?) "];
        BOOL status = [[AppManager SQLDataAccess] ExecuteStatement:sql WithParameters:parameters];
        NSDBLog(@"DA : getDBVersion : status = %@",status?@"YES":@"NO");
        if(status)
        {
            version = 1.1;
        }
    }
    else
    {
        version = [[[resultsArray objectAtIndex:0] objectForKey:@"value"] doubleValue];
    }
    
    return version;
}

-(BOOL)upgradeDB:(double)dbVersion
{
    BOOL status = NO;
    if(dbVersion <= 1.0)
    {
        //Shows how you would add an Alter Table to an older database version to rev it to the latest
        //There is no Alter Table if exists, but we should know by the version that we need to add this.
        NSString *sql = [NSString stringWithFormat:@"alter table Companys add column hasPhoto integer;"];
        sqlite3_exec(sqlite3dbConn, (const char*)[sql UTF8String], NULL, NULL, NULL);
        NSDBLog(@"DA : upgradeDB : sqlErrCode = %d : sqlErrMsg = %s",sqlite3_errcode(sqlite3dbConn),sqlite3_errmsg(sqlite3dbConn));
        status = YES;
    }
    else if (dbVersion >= 1.0)
    {
        //Were at the proper DB level, new DB alter table SQL would go here for the specific version
        status = YES;
    }
    NSDBLog(@"DA : upgradeDB : dbVersion = %f : status = %@",dbVersion,status?@"YES":@"NO");
    return status;
}

-(int)currentSizeOfDatabase
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *databasePath = [documentsDirectory stringByAppendingPathComponent:DB_FILE];
    int fileSize = 0;
    NSError *attributesError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:databasePath error:&attributesError];
    if( attributesError == nil )
    {
        fileSize = (int)[fileAttributes fileSize];
    }
    return fileSize;
}

-(sqlite3_stmt*) stmt:(sqlite3_stmt*)ps FromQuery:(NSString*)query WithParameters:(NSMutableArray*) parameters
{
    if (!sqlite3dbConn)
    {
        return nil;
    }
    
    int code = sqlite3_prepare_v2(sqlite3dbConn, [query UTF8String], (int)[query lengthOfBytesUsingEncoding:NSUTF8StringEncoding], &ps, NULL);
    
    if(code == SQLITE_OK)
    {
        for(int i = 0;i < [parameters count]; i++)
        {
            NSQLog(@"DA :  %@ isKindOfClass %@",[parameters objectAtIndex:i], [[parameters objectAtIndex:i] class]);
            if([[parameters objectAtIndex:i] isKindOfClass:[NSNumber class]])
            {
                NSString *objcType = [NSString stringWithUTF8String:[[parameters objectAtIndex:i] objCType]];
                NSQLog(@"DA : DataAccess : objcType = %@",objcType);
                if ([objcType isEqualToString:@"d"])
                {
                    NSQLog(@"DA : SetParameterDouble %@",[parameters objectAtIndex:i]);
                    sqlite3_bind_double(ps, i+1, [[parameters objectAtIndex:i] floatValue]);
                }
                else if ([objcType isEqualToString:@"q"])
                {
                    NSQLog(@"DA : SetParameterLongLong %@",[parameters objectAtIndex:i]);
                    sqlite3_bind_int64(ps, i+1, [[parameters objectAtIndex:i] longLongValue]);
                }
                else
                {
                    //All others treated as Int's
                    NSQLog(@"DA : Default SetParameterInt %@",[parameters objectAtIndex:i]);
                    sqlite3_bind_int(ps, i+1, [[parameters objectAtIndex:i] intValue]);
                }
            }
            else if([[parameters objectAtIndex:i] isKindOfClass:[NSString class]])
            {
                sqlite3_bind_text(ps, i + 1, [[parameters objectAtIndex:i]  UTF8String], -1, SQLITE_TRANSIENT);
                NSQLog(@"DA :  SetParameterString %@",[parameters objectAtIndex:i]);
            }
            else if([[parameters objectAtIndex:i] isKindOfClass:[UTCDate class]])
            {
                NSString *utcdatetime = [AppManager UTCDateTime];
                sqlite3_bind_text(ps, i + 1, [utcdatetime  UTF8String], -1, SQLITE_TRANSIENT);
                NSQLog(@"DA :  SetParameterDate");
            }
            else if([[parameters objectAtIndex:i] isKindOfClass:[NSData class]])
            {
                NSData *dataValue = [parameters objectAtIndex:i];
                sqlite3_bind_blob64(ps, i+1, [dataValue bytes], (int)[dataValue length], SQLITE_STATIC);
            }
            else
            {
                NELog(@"DA : Error: No match found for Data Type %@",[parameters objectAtIndex:i]);
            }
        }
    }
    return ps;
}

-(BOOL) ExecuteStatement:(NSString *)query, ... NS_REQUIRES_NIL_TERMINATION
{
    @synchronized(self)
    {
        if (!sqlite3dbConn)
            return NO;
        
        //Note the args list must always be terminted with a nil
        va_list args;
        va_start(args, query);
        NSMutableArray *parameters = [NSMutableArray array];
        id arg;
        while ( ( arg = va_arg(args, id) ) != nil)
        {
            [parameters addObject:arg];
        }
        va_end(args);
        BOOL status = [self ExecuteStatement:query WithParameters:parameters];
        return status;
    }
}

-(BOOL) ExecuteStatement:(NSString *)query WithParameters:(NSMutableArray*) parameters
{
    @synchronized(self)
    {
        BOOL status = NO;
        if (!sqlite3dbConn)
            return NO;
        
        sqlite3_stmt *ps = nil;
        int code;
        ps = [self stmt:ps FromQuery:query WithParameters:parameters];
        if(ps)
        {
            code = sqlite3_step(ps);
            status = (code == SQLITE_DONE);
        }
        NSQLog(@"DA : SQL : query : %@", query);
        
        if( !ps || !status )
        {
            NSString *errCode = [NSString stringWithFormat:@"%d",sqlite3_errcode(sqlite3dbConn)];
            NSString *codeStr = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3dbConn)];
            NELog(@"DA : SQL Error during insert : Err[%@] = %@  : Q = %@\n",errCode,codeStr, query);
            if(![errCode isEqualToString:@"19"])
            {
                //Don't log not unique errors, we get tons of these
            }
        }
        //This releases the ps
        sqlite3_finalize(ps);
        sqlite3_exec(sqlite3dbConn, "COMMIT TRANSACTION", 0, 0, 0);
        return status;
    }
}

-(BOOL) ExecuteStatement:(NSString *)query WithParameters:(NSMutableArray*) parameters OutParameter:(NSString**)errorCodeStr
{
    @synchronized(self)
    {
        BOOL status = NO;
        if (!sqlite3dbConn)
            return NO;
        
        sqlite3_stmt *ps = nil;
        int code;
        ps = [self stmt:ps FromQuery:query WithParameters:parameters];
        if(ps)
        {
            code = sqlite3_step(ps);
            status = (code == SQLITE_DONE);
        }
        NSQLog(@"DA : SQL : query : %@", query);
        
        if( !ps || !status )
        {
            NSString *errCode = [NSString stringWithFormat:@"%d",sqlite3_errcode(sqlite3dbConn)];
            NSString *codeStr = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3dbConn)];
            NELog(@"DA : SQL Error during insert : %@ : %@",errCode,codeStr);
            //not sure if we should rollback in sqlite3
            if (!status)
            {
                *errorCodeStr = codeStr;
            }
            
        }
        //This releases the ps
        sqlite3_finalize(ps);
        sqlite3_exec(sqlite3dbConn, "COMMIT TRANSACTION", 0, 0, 0);
        return status;
    }
}

-(BOOL) ExecuteTransaction:(NSMutableArray *)sqlAndParamsForTransaction
{
    @synchronized(self)
    {
        //NELog(@"%@", sqlAndParamsForTransaction);
        BOOL status = NO;
        if (!sqlite3dbConn)
            return NO;
        
        NSQLog(@"DA : ExecuteTransaction : Count = %d", [sqlAndParamsForTransaction count]);
        sqlite3_exec(sqlite3dbConn, "BEGIN EXCLUSIVE TRANSACTION", 0, 0, 0);
        sqlite3_stmt *ps = nil;
        for (int i = 0; i< [sqlAndParamsForTransaction count]; i++)
        {
            NSString *query = [[sqlAndParamsForTransaction objectAtIndex:i] objectForKey:@"SQL"];
            NSMutableArray *parameters = [[sqlAndParamsForTransaction objectAtIndex:i] objectForKey:@"Parameters"];
            NSQLog(@"DA : ExecuteTransaction[%d] : query = %@\n : parameters = %@\n",i,query,parameters);
            int code;
            ps = [self stmt:ps FromQuery:query WithParameters:parameters];
            if(ps)
            {
                code = sqlite3_step(ps);
                status = (code == SQLITE_DONE);
            }
            if( !ps || !status )
            {
                NSString *errCode = [NSString stringWithFormat:@"%d",sqlite3_errcode(sqlite3dbConn)];
                NSString *codeStr = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3dbConn)];
                NELog(@"DA : ExecuteTransaction : SQL Error during transaction insert : %@ : %@",errCode,codeStr);
                sqlite3_exec(sqlite3dbConn, "ROLLBACK", 0, 0, 0);
                status = NO;
                break;
            }
            //This releases the ps
            sqlite3_finalize(ps);
        }
        if(status)
        {
            sqlite3_exec(sqlite3dbConn, "COMMIT TRANSACTION", 0, 0, 0);
        }
        return status;
    }
}

-(NSMutableArray*)GetRecordsForQuery:(NSString*)query, ... NS_REQUIRES_NIL_TERMINATION
{
    //Note the args list must always be terminted with a nil
    @synchronized(self)
    {
        if (!sqlite3dbConn)
            return nil;
        
        va_list args;
        va_start(args, query);
        NSMutableArray *parameters = [NSMutableArray array];
        id arg = nil;
        while ( ( arg = va_arg(args, id) ) != nil)
        {
            [parameters addObject:arg];
        }
        va_end(args);
        NSMutableArray *results = [self GetRecordsForQuery:query WithParameters:parameters];
        return results;
    }
}

-(NSMutableArray *) GetRecordsForQuery:(NSString*)query WithParameters:(NSMutableArray*)parameters
{
    @synchronized(self)
    {
        if (!sqlite3dbConn)
            return nil;
        
        sqlite3_stmt *ps = nil;
        ps = [self stmt:ps FromQuery:query WithParameters:parameters];
        NSMutableArray *results = [[NSMutableArray alloc] init];
        NSQLog(@"DA : Query %@", query);
        if (ps)
        {
            int columnCount = sqlite3_column_count(ps);
            NSMutableDictionary *result;
            while (sqlite3_step(ps)==SQLITE_ROW)
            {
                NSQLog(@"DA : columnCount = %d", columnCount);
                int i = 0;
                result = [[NSMutableDictionary alloc] init];
                for (; i < columnCount; i++)
                {
                    int columnType = sqlite3_column_type(ps, i);
                    switch (columnType)
                    {
                        case SQLITE_INTEGER:
                            [result setObject:[NSString stringWithFormat:@"%lld" ,sqlite3_column_int64(ps, i)] forKey:[NSString stringWithUTF8String:sqlite3_column_name(ps, i)]];
                            break;
                            /*
                             case SQLITE_INTEGER:
                             [result setObject:[NSString stringWithFormat:@"%d" ,sqlite3_column_int(ps, i)] forKey:[NSString stringWithUTF8String:sqlite3_column_name(ps, i)]];
                             break;
                             */
                        case SQLITE_FLOAT:
                            [result setObject:[NSString stringWithFormat:@"%f" ,sqlite3_column_double(ps, i)] forKey:[NSString stringWithUTF8String:sqlite3_column_name(ps, i)]];
                            break;
                            
                        case SQLITE_TEXT:
                            [result setObject:[NSString stringWithUTF8String:(char*)sqlite3_column_text(ps, i)] forKey:[NSString stringWithUTF8String:sqlite3_column_name(ps, i)]];
                            break;
                            
                        case SQLITE_BLOB:
                        {
                            NSData *blobData = [NSData dataWithBytes:sqlite3_column_blob(ps, i) length: sqlite3_column_bytes(ps, i)];
                            [result setObject:[NSData dataWithData:blobData] forKey:[NSString stringWithUTF8String:sqlite3_column_name(ps, i)]];
                        }
                            break;
                            
                        case SQLITE_NULL:
                            //boolean type
                            NSQLog(@"DA : column type %d for column %@ ", columnType, [NSString stringWithUTF8String:sqlite3_column_name(ps, i)]);
                            [result setObject:@"" forKey:[NSString stringWithUTF8String:sqlite3_column_name(ps, i)]];
                            break;
                            
                        default:
                            NSQLog(@"DA : Invalid column type %d for column %@ ", columnType, [NSString stringWithUTF8String:sqlite3_column_name(ps, i)]);
                            break;
                    }
                }
                [results addObject:result];
            }
        }
        else
        {
            NSString *errCode = [NSString stringWithFormat:@"%d",sqlite3_errcode(sqlite3dbConn)];
            NSString *codeStr = [NSString stringWithFormat:@"%s",sqlite3_errmsg(sqlite3dbConn)];
            NELog(@"DA : SQL Error Prepared Stmt : %@ : %@ : %@",query,errCode,codeStr);
        }
        //This releases the ps
        sqlite3_finalize(ps);
        NSMutableArray *returnedResults = [NSMutableArray new];
        if(results != nil)
            [returnedResults setArray:results];
        
        return returnedResults;
    }
}

- (NSString *)getDatabaseTables
{
    NSMutableString *dump = [NSMutableString string];
    [dump appendFormat:@"\n DataBase Tables for \n\n DB = %@\n\n",DB_FILE];
    NSMutableString *sql = [NSMutableString string];
    NSMutableArray *parameters = [NSMutableArray array];
    [sql appendString:@"select * from sqlite_master where type='table' and name not like 'sqlite_%';"];
    NSMutableArray *rows = [self GetRecordsForQuery:sql WithParameters:parameters];
    for (int i = 0; i<[rows count]; i++)
    {
        NSDictionary *obj = [rows objectAtIndex:i];
        //get sql "create table" sentence
        NSString *sql = [obj objectForKey:@"sql"];
        [dump appendString:[NSString stringWithFormat:@"%@;\n",sql]];
    }
    return dump;
}

- (NSString *)getDatabaseDump
{
    NSMutableString *dump = [NSMutableString string];
    [dump appendFormat:@"\n DataBase Dump for \n\n DB = %@\n\n",DB_FILE];
    
    NSMutableString *sql = [NSMutableString string];
    NSMutableArray *parameters = [NSMutableArray array];
    [sql appendString:@"select * from sqlite_master where type='table' and name not like 'sqlite_%';"];
    NSMutableArray *rows = [self GetRecordsForQuery:sql WithParameters:parameters];
    
    //loop through all tables
    for (int i = 0; i<[rows count]; i++)
    {
        NSDictionary *obj = [rows objectAtIndex:i];
        //get sql "create table" sentence
        NSString *sql = [obj objectForKey:@"sql"];
        [dump appendString:[NSString stringWithFormat:@"%@;\n",sql]];
        //get table name
        NSString *tableName = [obj objectForKey:@"name"];
        //get all table content
        NSMutableString *sqls = [NSMutableString string];
        [sqls appendFormat:@"select * from %@",tableName];
        NSMutableArray *tableContent = [self GetRecordsForQuery:sqls WithParameters:parameters];
        
        for (int j = 0; j<[tableContent count]; j++)
        {
            NSDictionary *item = [tableContent objectAtIndex:j];
            //keys are column names
            NSArray *keys = [item allKeys];
            //values are column values
            NSArray *values = [item allValues];
            //start constructing insert statement for this item
            [dump appendString:[NSString stringWithFormat:@"insert into %@ (",tableName]];
            //loop through all keys (aka column names)
            NSEnumerator *enumerator = [keys objectEnumerator];
            id obj;
            while (obj = [enumerator nextObject])
            {
                [dump appendString:[NSString stringWithFormat:@"%@,",obj]];
            }
            
            //delete last comma
            NSRange range;
            range.length = 1;
            range.location = [dump length]-1;
            [dump deleteCharactersInRange:range];
            [dump appendString:@") values ("];
            
            // loop through all values
            enumerator = [values objectEnumerator];
            while (obj = [enumerator nextObject])
            {
                //if it's a number (integer or float)
                if ([obj isKindOfClass:[NSNumber class]])
                {
                    [dump appendString:[NSString stringWithFormat:@"%@,",[obj stringValue]]];
                }
                //if it's a null
                else if ([obj isKindOfClass:[NSNull class]])
                {
                    [dump appendString:@"null,"];
                }
                //else is a string
                else
                {
                    [dump appendString:[NSString stringWithFormat:@"'%@',",obj]];
                }
            }
            //delete last comma again
            range.length = 1;
            range.location = [dump length]-1;
            [dump deleteCharactersInRange:range];
            //finish our insert statement
            [dump appendString:@");\n"];
        }
    }
    return dump;
}

@end
