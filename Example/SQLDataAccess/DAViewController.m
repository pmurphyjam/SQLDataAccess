//
//  DAViewController.m
//  SQLDataAccess
//
//  Created by pmurphyjam on 03/05/2017.
//  Copyright (c) 2017 pmurphyjam. All rights reserved.
//

#import "DAViewController.h"
//#import "AppManager.h"

@interface DAViewController ()

@property(nonatomic,weak) IBOutlet UITextView *textView;
@property(nonatomic,weak) IBOutlet UILabel *dataLabel;

@end

@implementation DAViewController

@synthesize textView;
@synthesize dataLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [dataLabel setText:@"Should see a simple SQLDataAccess here."];
    /*
    NSMutableArray *dataArray = [[AppManager SQLDataAccess] GetRecordsForQuery:@"select * from AppInfo ",nil];
    NSLog(@"DAView : dataArray = %@",dataArray);
    NSMutableString *data = [NSMutableString new];
    if([dataArray count] > 0)
    {
        [data appendString:@"Database : Example.db \r"];
        [data appendString:@"SQL : 'select * from AppInfo' \r"];
        [data appendString:@"Results are : \r"];
        [data appendFormat:@"%@",dataArray];
        [textView setText:data];
     }
    */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
