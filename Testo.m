//
//  Testo.m
//  SoftModemRemote
//
//  Created by johannes on 5/5/14.
//  Copyright (c) 2014 9Lab. All rights reserved.
//

#import "Testo.h"

@interface Testo ()

@end

@implementation Testo
@synthesize sendRequestDelegate;

-(id)init
{
    self = [super init];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"content loaded with %@",nibNameOrNil);
        // Custom initialization

    }
    NSLog(@"content loaded");
    return self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void) setSelfAsSendRequestDelegate:(id)controller
{
    [self setSendRequestDelegate:controller];
    
    [self.sendRequestDelegate sendRequest:@"00"];
    [NSThread sleepForTimeInterval:0.04];           // This will sleep for 40 millis
    
    [self.receiveDataProgress startAnimating];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) receivedChar:(char)input;
{
    if ([self.receiveDataProgress isAnimating]) {
        [self.receiveDataProgress stopAnimating];
    }

    self.myTextView.text = [self.myTextView.text stringByAppendingString:[NSString stringWithFormat:@"%c",input]];
    [self.myTextView scrollRangeToVisible:NSMakeRange([self.myTextView.text length], 0)];
    
    NSLog(@"testo received %c", input);
    
}


@end