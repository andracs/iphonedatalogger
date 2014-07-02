//
//  MulticalRequest.h
//  MeterLogger
//
//  Created by stoffer on 23/06/14.
//  Copyright (c) 2014 Johannes Gaardsted Jørgensen <johannesgj@gmail.com> + Kristoffer Ek <stoffer@skulp.net>. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License

#import <Foundation/Foundation.h>
#import "Protocols.h"
#import "IEC62056-21.h"

@interface MulticalRequest : NSObject <NewSampleViewControllerSendToDeviceRequest>

@property IEC62056_21 *iec62056_21;

- (void)sendRequest;

- (void)sendIEC62056_21Request:(NSOperation *)theOperation;
@property (nonatomic, assign) id<DeviceRequestSendToNewSampleViewController> deviceRequestSendToNewSampleViewControllerDelegate;
@property (nonatomic, assign) id<DeviceRequestSendToDeviceViewController> deviceRequestSendToDeviceViewControllerDelegate;

@property NSOperationQueue *sendIEC62056_21RequestOperationQueue;

@end
