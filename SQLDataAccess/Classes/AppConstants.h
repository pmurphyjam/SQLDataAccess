//
//  AppConstants.h
//  ABExample
//
//  Created by Pat Murphy on 5/16/14.
//  Copyright (c) 2014 Fitamatic All rights reserved.
//
//  Info : Central place for all the App constants, and controls debug logs.
//  Simply comment in or out a debug log below to see log information to aid in quick debug.
//  Developer should define their own meaningful debug logs, like NTXLog for all transmit events, etc.
//

#define ServerUrl @"http://your.company.com/"
#define ServerDomain "yahoo.com"

//Declare as extern so they can be changed in projects AppDelegate
extern NSString *DB_FILE;
extern NSString *DB_FILEX;

#define DB_KEY                        @"24592ED456983DEAB4598234598EDC3F25098EF240975EDF4358297DEF245FDE"
#define EN_KEY                        @"3FEF5CA851E7B34E5670B023F08503493D451A05CE4D2EDC6833F666A8086BEC"
#define SQLITE_CIPHER_VERSION         3008000


//#define DEBUGNSQL
#ifdef DEBUGNSQL
#    define NSQLog(...) NSLog(__VA_ARGS__)
#else
#    define NSQLog(...)
#endif

//#define DEBUGDB
#ifdef DEBUGDB
#    define NSDBLog(...) NSLog(__VA_ARGS__)
#else
#    define NSDBLog(...)
#endif

#define DEBUGERROR
#ifdef DEBUGERROR
#    define NELog(...) NSLog(__VA_ARGS__)
#else
#    define NELog(...)
#endif

