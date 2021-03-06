//
//  Kamstrup.m
//  SoftModemRemote
//
//  Created by johannes on 5/5/14.
//  Copyright (c) 2014 Johannes Gaardsted Jørgensen <johannesgj@gmail.com> + Kristoffer Ek <stoffer@skulp.net>. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License

#import "Kamstrup.h"
#import "KMP.h"
#import "KeyLabelValueTextfieldCell.h"
#import "KamstrupRequest.h"

//#define KAMSTRUP_DATA_LENGTH (285.0f)

#define RECEIVE_DATA_TIME (16.0f)
#define RECEIVE_DATA_PROGRESS_TIMER_UPDATE_INTERVAL (1.0f) // every second

@interface Kamstrup ()
@property KamstrupRequest * kamstrupRequest;
@property NSOperationQueue *sendKMPRequestOperationQueue;
@property BOOL readyToSend;
@property unsigned char framesToSend;
@property unsigned char framesReceived;
@property DeviceSampleDataObject *myDataObject;
@property NSArray *orderedNames;
@property NSMutableData *data;
@property BOOL state;

@property (weak, nonatomic) IBOutlet UITableView *detailsTableView;

@property KMP *kmp;

@end


@implementation Kamstrup
//@synthesize sendRequestDelegate;
@synthesize receiveDataProgressTimer;
@synthesize sendKMPRequestOperationQueue;
@synthesize readyToSend;
@synthesize framesToSend;
@synthesize framesReceived;
@synthesize myDataObject;
@synthesize orderedNames;
@synthesize data;
@synthesize state;
@synthesize detailsTableView;
@synthesize kmp;

-(id)init
{
    self = [super init];
    return self;
}

//inits with a dictionary holding a viewcontroller to be set as delegate for sendrequest stuff
-(id)initWithDictionary:(NSDictionary *)dictionary ;//= /* parse the JSON response to a dictionary */;
{
    NSLog(@"sensor init with dictionary");

   // [self setSendRequestDelegate:dictionary[@"delegate"]];
    
    // set myDataObject to the one passed in dictionary key dataObject
    [self setMyDataObject:dictionary[@"dataObject"]];
    self.state = NO;

    // set up kmp protocol
    self.kmp = [[KMP alloc] init];
    
    self.kamstrupRequest = [[KamstrupRequest alloc] init];
    [self.kamstrupRequest setSendRequestDelegate:dictionary[@"delegate"]];//new
    
    self.framesReceived = 0;
    self.framesToSend = 0;
    self.readyToSend = YES;
    
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
  //  return self;//fordi vi selv vil lytte :-)
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    KMP *myData = [[KMP alloc] init];
    [myData getType];
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
        // new sample view
        // set momentary data object
        self.data = [[NSMutableData alloc] init];

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

        NSLog(@"mydataobject is empty");
        // start progress bar
        [self.receiveDataProgressView setHidden:NO];
        [self.receiveDataProgressView setProgress:0.0 animated:YES];
        // and start a timer to update it
        /*
        self.receiveDataProgressTimer = [NSTimer scheduledTimerWithTimeInterval:RECEIVE_DATA_PROGRESS_TIMER_UPDATE_INTERVAL
                                                                         target:self
                                                                       selector:@selector(updateProgressBar)
                                                                       userInfo:nil
                                                                        repeats:YES];
         */
        
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];  // dont lock

        // start sendKMPRequest in a operation queue, so it can be canceled
        self.sendKMPRequestOperationQueue = [[NSOperationQueue alloc] init];

        NSInvocationOperation *operation = [NSInvocationOperation alloc];
        operation = [operation initWithTarget:self
                                     selector:@selector(sendKMPRequest:)
                                       object:operation];
        
        [self.sendKMPRequestOperationQueue addOperation:operation];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sendKMPRequest:(NSOperation *)theOperation {
    // read KamstrupPropertyList.plist to get rid's to send
    NSString *kamstrupPlist = [[NSBundle mainBundle] pathForResource:@"KamstrupPropertyList" ofType:@"plist"];
    NSArray *registerNameArray = [NSArray arrayWithContentsOfFile:kamstrupPlist];
    
    // get rid's
    NSMutableArray *ridArray = [NSMutableArray array];
    for (NSString *registerName in registerNameArray) {
        NSNumber *rid = [[self.kmp.registerIDTable allKeysForObject:registerName] lastObject];
        if (rid) {
            NSLog(@"rid %@ value \"%@\"", rid, registerName);
            if (![ridArray containsObject:rid]) {
                // add unique rid's to rids
                [ridArray addObject:rid];
            }
        }
    }
    self.framesToSend = (unsigned int)ceil(ridArray.count / 8.0);
    
    // request 8 registers at a time
    for (unsigned int i = 0; i < self.framesToSend; i++) {
        unsigned int remainingRidCount = ridArray.count - i * 8;
        
        NSArray *registerOctet;
        if (remainingRidCount >= 8) {
            NSRange range = NSMakeRange(8 * i, 8);
            registerOctet = [ridArray subarrayWithRange:range];
        }
        else {
            NSRange range = NSMakeRange(8 * i, remainingRidCount);
            registerOctet = [ridArray subarrayWithRange:range];
        }
        
        self.readyToSend = NO;
        [self.sendRequestDelegate sendRequest:PROTO_KAMSTRUP];
        [NSThread sleepForTimeInterval:0.04];           // This will sleep for 40 millis
        [self.kmp prepareFrameWithRegistersFromArray:registerOctet];
        [self.sendRequestDelegate sendRequest:[self dataToHexString:self.kmp.frame]];
        self.kmp.frame = [[NSMutableData alloc] initWithBytes:NULL length:0];    // free the frame
        
        // wait for end of data
        while(!self.readyToSend ){
            if ([theOperation isCancelled]) {
                return;
            }
            [NSThread sleepForTimeInterval:0.01];
        }
    }
}

- (void)receivedChar:(unsigned char)input;
{
    //NSLog(@"Kamstrup received %02x", input);
    // save incoming data do our sampleDataDict
    NSData *inputData = [NSData dataWithBytes:(unsigned char[]){input} length:1];
    [self.data appendData:inputData];
    
    [self.receiveDataProgressView setProgress:(self.receiveDataProgressView.progress + 0.0075) animated:YES];

    if ((input == 0x0d) || (input == 0x06)) {   // last character from kamstrup
        [self doneReceiving];
    }
}

- (void)doneReceiving {
    NSLog(@"Done receiving %@", self.data);
    self.framesReceived++;
    // decode kmp frame
    [self.kmp decodeFrame:self.data];
    
    if (self.kmp.frameReceived) {
        for (NSNumber *rid in self.kmp.registerIDTable) {
            if (self.kmp.responseData[rid] && self.myDataObject.sampleDataDict[self.kmp.registerIDTable[rid]]) {
                //NSLog(@"doneReceiving: updating %@", self.kmp.registerIDTable[rid]);
                
                // format as number
                NSMutableString *valueString = [[[self.kmp numberForKmpNumber:self.kmp.responseData[rid][@"value"] andSiEx:self.kmp.responseData[rid][@"siEx"]] stringValue] mutableCopy];

                float valueFloat = atof([valueString UTF8String]);
                // localized number format
                
                valueString = [[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:valueFloat] numberStyle:NSNumberFormatterDecimalStyle] mutableCopy];
                NSString *unit = kmp.registerUnitsTable[kmp.responseData[rid][@"unit"]];
                if (unit && (![unit isEqualToString:@"number"])) {
                    [valueString appendString:@" "];
                    [valueString appendString:unit];
                }
                NSLog(@"valueString %@", valueString);
                self.myDataObject.sampleDataDict[self.kmp.registerIDTable[rid]] = valueString;
            }
        }
        self.data = [[NSMutableData alloc] init];       // clear data after use
        self.kmp.responseData = [[NSMutableDictionary alloc] init];
        
        //update table view
        self.state = YES;
        [self.detailsTableView reloadData];

        self.readyToSend = YES;
    }
    
    if (self.kmp.errorReceiving) {
        NSLog(@"Retransmit");
        self.framesReceived = 0;
        self.data = [[NSMutableData alloc] init];       // clear data after use
        self.kmp.responseData = [[NSMutableDictionary alloc] init];
        // stop all already running sendKMPRequests
        [self.sendKMPRequestOperationQueue cancelAllOperations];
        
        // restart progress bar
        [self.receiveDataProgressView setProgress:0.0];
        
        // and start a new one
        NSInvocationOperation *operation = [NSInvocationOperation alloc];
        operation = [operation initWithTarget:self
                                     selector:@selector(sendKMPRequest:)
                                       object:operation];
        
        [self.sendKMPRequestOperationQueue addOperation:operation];
        
    }
    
    if (self.framesReceived == self.framesToSend) {
        // last frame received
        [self.receiveDataProgressView setHidden:YES];
        [[UIApplication sharedApplication] setIdleTimerDisabled: NO];  // allow lock again
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];  // allow lock again
    [self.receiveDataProgressTimer invalidate];
    self.receiveDataProgressTimer = nil;
    [self.sendKMPRequestOperationQueue cancelAllOperations];
    self.sendKMPRequestOperationQueue = nil;
    NSLog(@"viewDidDisappear");
}

- (DeviceSampleDataObject *)getDataObject
{
    NSIndexPath *myIP = [NSIndexPath indexPathForRow:0 inSection:0];
    id placeCell=[self.detailsTableView cellForRowAtIndexPath:myIP];
    UITextField *placeTextfield = (UITextField *)[placeCell viewWithTag:100];
    
    myIP = [NSIndexPath indexPathForRow:1 inSection:0];
    id commentCell=[self.detailsTableView cellForRowAtIndexPath:myIP];
    UITextField *commentTextfield = (UITextField *)[commentCell viewWithTag:100];

    self.myDataObject.placeName = placeTextfield.text;
    self.myDataObject.sampleDataDict[@"Comment"] = commentTextfield.text;
    

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

    //NSLog(@"%d, %d",indexPath.row,indexPath.section);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
//    lol+=10;

    //real keys is from sel.orderednames and value is from dict[self.orderednames[0]]
    NSInteger row=indexPath.row;

    if(indexPath.section == 1)
    {
        row+=2;
    }
    NSString *key = self.orderedNames[row];
    NSString *value = self.myDataObject.sampleDataDict[key];
    
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
    NSLog(@"updateProgressBar %f", self.receiveDataProgressView.progress);
    [self.receiveDataProgressView setProgress:
        self.receiveDataProgressView.progress + 0.5 / RECEIVE_DATA_TIME * RECEIVE_DATA_PROGRESS_TIMER_UPDATE_INTERVAL animated:YES];
    if (self.receiveDataProgressView.progress >= 0.5) {
        // stop the timer - updating is done in receivedChar from there
        [self.receiveDataProgressTimer invalidate];
        self.receiveDataProgressTimer = nil;
    }
}

#pragma mark - Stupid redundant code

-(NSString *) dataToHexString:(NSData *) theData {
    NSString *result = [[theData description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    result = [result substringWithRange:NSMakeRange(1, [result length] - 2)];
    return result;
}


@end
