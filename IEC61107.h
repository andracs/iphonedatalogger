//
//  IEC61107.h
//  SoftModemRemote
//
//  Created by johannes on 5/5/14.
//  Copyright (c) 2014 9Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceSampleDataObject.h"
#import "NewSampleViewController.h"
#import "Protocols.h"
#import "SamplesEntity.h"
//#import "KMP.h"

#define PROTO_IEC61107		(@"fc")

@class IEC61107;

@interface IEC61107 : UIViewController <NewSampleViewControllerReceivedChar,UITextFieldDelegate,UITableViewDelegate, UITableViewDataSource>{

}
- (void)sendIEC61107Request:(NSOperation *)theOperation;

@property (nonatomic, assign) id<DeviceViewControllerSendRequest> sendRequestDelegate;

@property (weak, nonatomic) IBOutlet UIProgressView *receiveDataProgressView;

@property NSTimer *receiveDataProgressTimer;

@end
