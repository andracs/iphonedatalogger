//
//  KamstrupMultical.h
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

#define PROTO_KAMSTRUP_MULTICAL		(@"fc")

@class KamstrupMultical;

@interface KamstrupMultical : UIViewController <NewSampleViewControllerReceivedChar,UITextFieldDelegate,UITableViewDelegate, UITableViewDataSource>{

}
- (void)sendMulticalRequest:(NSOperation *)theOperation;

@property (nonatomic, assign) id<DeviceViewControllerSendRequest> sendRequestDelegate;

@property (weak, nonatomic) IBOutlet UIProgressView *receiveDataProgressView;

@property NSTimer *receiveDataProgressTimer;

@end

