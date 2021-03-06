//
//  Testo.m
//  SoftModemRemote
//
//  Created by johannes on 5/5/14.
//  Copyright (c) 2014 Johannes Gaardsted Jørgensen <johannesgj@gmail.com> + Kristoffer Ek <stoffer@skulp.net>. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License

#import "Testo.h"
#import "KeyLabelValueTextfieldCell.h"

#define TESTO_DATA_LENGTH (712.0f)

#define RECEIVE_DATA_TIME (40.0f)
#define RECEIVE_DATA_PROGRESS_TIMER_UPDATE_INTERVAL (1.0f) // every second

@interface Testo ()
@property DeviceSampleDataObject *myDataObject;
@property NSArray *orderedNames;
@property NSMutableString *data;
@property BOOL state;

@property (weak, nonatomic) IBOutlet UITableView *detailsTableView;

@end

@implementation Testo
@synthesize sendRequestDelegate;
@synthesize receiveDataProgressTimer;
@synthesize myDataObject;
@synthesize detailsTableView;
@synthesize state;
@synthesize orderedNames;

@synthesize data;

-(id)init
{
    self = [super init];
    return self;
}

//inits with a dictionary holding a viewcontroller to be set as delegate for sendrequest stuff
-(id)initWithDictionary:(NSDictionary *)dictionary ;//= /* parse the JSON response to a dictionary */;
{
    NSLog(@"sensor init with dictionary");
    [self setSendRequestDelegate:dictionary[@"delegate"]];
    
    // set myDataObject to the one passed in dictionary key dataObject
    [self setMyDataObject:dictionary[@"dataObject"]];
    self.state = NO;
    
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

//new stuff
-(id)respondWithReceiveCharDelegate
{
    return self;//fordi vi selv vil lytte :-)
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    if([self.myDataObject.sampleDataDict count] != 0)
    {
        // details view
        NSString *devicePlistString=[NSString stringWithFormat:@"%@PropertyList",myDataObject.deviceName];
        NSString *devicePlist = [[NSBundle mainBundle] pathForResource:devicePlistString ofType:@"plist"];
        NSArray *deviceKeys = [NSArray arrayWithContentsOfFile:devicePlist];
        self.orderedNames=[[NSArray alloc]initWithArray:deviceKeys];
    }
    else
    {
        //set momentary data object
        self.data =[@"" mutableCopy];

        // if there is no data saved init sampleDataDict empty
        // load keys from property list

        NSString *devicePlistString=[NSString stringWithFormat:@"%@PropertyList",myDataObject.deviceName];
        NSString *devicePlist = [[NSBundle mainBundle] pathForResource:devicePlistString ofType:@"plist"];
        NSArray *deviceKeys = [NSArray arrayWithContentsOfFile:devicePlist];
        
        NSMutableArray *deviceValues = [[NSMutableArray alloc] init];
        
        for(int i=0; i<[deviceKeys count]; i++){
            
            NSString *newString = @"";
            
            [deviceValues addObject: newString];
        }
        
        self.orderedNames=[[NSArray alloc]initWithArray:deviceKeys];

        NSMutableDictionary *deviceDict = [[NSMutableDictionary alloc] initWithObjects:deviceValues forKeys:deviceKeys];
        
        
        self.myDataObject.sampleDataDict = deviceDict;

        // new sample view
        NSLog(@"mydataobject is empty");
        // start progress bar
        [self.receiveDataProgressView setHidden:NO];
        [self.receiveDataProgressView setProgress:0.0 animated:YES];
        // and start a timer to update it
        self.receiveDataProgressTimer = [NSTimer scheduledTimerWithTimeInterval:RECEIVE_DATA_PROGRESS_TIMER_UPDATE_INTERVAL
                                                                         target:self
                                                                       selector:@selector(updateProgressBar)
                                                                       userInfo:nil
                                                                        repeats:YES];
        
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];  // dont lock
        
        [self.sendRequestDelegate sendRequest:PROTO_TESTO];
        [NSThread sleepForTimeInterval:0.04];           // This will sleep for 40 millis
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)receivedChar:(unsigned char)input;
{
    // save incoming data do our sampleDataDict
    [self.data appendFormat:@"%c", input];
    
    NSLog(@"Testo received %c", input);
    [self.receiveDataProgressView setProgress:(0.5 + [self.data length]/(float)TESTO_DATA_LENGTH/2) animated:YES];

    if (self.receiveDataProgressTimer) {
        // stop it
        [self.receiveDataProgressTimer invalidate];
        self.receiveDataProgressTimer = nil;        // let it be deallocated
        // and start a new timer
        self.receiveDataProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(doneReceiving) userInfo:nil repeats:NO];
    }
    else {
        // if its not running start a new one
        self.receiveDataProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(doneReceiving) userInfo:nil repeats:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];  // allow lock again
    [self.receiveDataProgressTimer invalidate];
    self.receiveDataProgressTimer = nil;
}

- (void)doneReceiving {
    NSLog(@"Done receiving %@", self.data);
    
    [self.receiveDataProgressView setHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];  // allow lock again
    
    NSRegularExpression *regex;
    NSString *str;
    NSTextCheckingResult *match;
    NSString *testoValue;
    
    //datastring is set
    str = self.data;

    // match CO2
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+CO2\\s" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"CO2"] = testoValue;

    // match O2
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+O2" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"O2"] = testoValue;

    // match CO
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+CO\\s" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"CO"] = testoValue;

    // match Fluegas temp
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+Fluegas temp" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"FlueGasTemp"] = testoValue;

    // match Excess air
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+Excess air" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"ExcessAir"] = testoValue;

    // match Draught
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+Draught" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"Draught"] = testoValue;

    // match EFF net
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+EFF net" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"EffNet"] = testoValue;

    // match Ambient CO
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+Ambient CO" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"AmbientCO"] = testoValue;

    // match EFF gross
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+EFF gross" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"EffGross"] = testoValue;

    // match Diff. press.
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+Diff. press." options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"DiffPress"] = testoValue;

    // match Ambient temp
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+Ambient temp" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"AmbientTemp"] = testoValue;

    // match Undiluted CO
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(.*?)\\s+Undiluted CO" options:0 error:NULL];
    match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    testoValue = [str substringWithRange:[match rangeAtIndex:1]];
    self.myDataObject.sampleDataDict[@"UndilutedCO"] = testoValue;

    //update table view
    self.state = YES;
    [self.detailsTableView reloadData];
}

- (DeviceSampleDataObject *)getDataObject
{
    NSIndexPath *myIP = [NSIndexPath indexPathForRow:0 inSection:0];
    id placeCell=[self.detailsTableView cellForRowAtIndexPath:myIP];
    UITextField *placeTextfield = (UITextField *)[placeCell viewWithTag:100];
    
    myIP = [NSIndexPath indexPathForRow:1 inSection:0];
    id effectCell=[self.detailsTableView cellForRowAtIndexPath:myIP];
    UITextField *effectTextfield = (UITextField *)[effectCell viewWithTag:100];

    self.myDataObject.placeName = placeTextfield.text;
    self.myDataObject.sampleDataDict[@"Effect"] = effectTextfield.text;
    

    return self.myDataObject;
}

//table view stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section==0)
    {
        return @" ";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return [self.myDataObject.sampleDataDict count]-2;
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        static NSString *CellIdentifier = @"KeyLabelValueTextfieldCellIdentifier";
        KeyLabelValueTextfieldCell *cell = (KeyLabelValueTextfieldCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            NSArray* topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"KeyLabelValueTextfieldCell" owner:self options:nil];
            for (id currentObject in topLevelObjects) {
                if ([currentObject isKindOfClass:[UITableViewCell class]]) {
                    cell = (KeyLabelValueTextfieldCell *)currentObject;
                    break;
                }
            }
        }
    // Configure the cell.
//    NSArray* keys = [self.myDataObject.sampleDataDict allKeys];

    NSLog(@"%d, %d",indexPath.row,indexPath.section);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
//    lol+=10;

    //real keys is from sel.orderednames and value is from dict[self.orderednames[0]]
    NSInteger row=indexPath.row;

    if(indexPath.section==1)
    {
        row+=2;
    }
    NSString * key=self.orderedNames[row];
    NSString * value=self.myDataObject.sampleDataDict[key];
    
    cell.keyLabel.text = key;//   objectAtIndex:indexPath.section];

    if (indexPath.section==0 && [value length]==0 && [self.myDataObject.placeName length]==0)//place
    {
        cell.valueTextfield.userInteractionEnabled=YES;
    }else{
        if([key isEqualToString:@"Place"])
        {
            value=self.myDataObject.placeName;
        }
        cell.valueTextfield.text = value;
    }
    return cell;
}

// progress bar stuff
- (void)updateProgressBar {
    [self.receiveDataProgressView setProgress:
        self.receiveDataProgressView.progress + 0.5 / RECEIVE_DATA_TIME * RECEIVE_DATA_PROGRESS_TIMER_UPDATE_INTERVAL animated:YES];
    if (self.receiveDataProgressView.progress >= 0.5) {
        // stop the timer - updating is done in receivedChar from there
        [self.receiveDataProgressTimer invalidate];
        self.receiveDataProgressTimer = nil;
    }
}


@end
