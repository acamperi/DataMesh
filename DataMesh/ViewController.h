//
//  ViewController.h
//  DataMesh
//
//  Created by Myles Novick on 11/30/14.
//  Copyright (c) 2014 Myles Novick. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "WebViewController.h"

@interface ViewController : UIViewController <MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, MCNearbyServiceBrowserDelegate, WebViewControllerDelegate>

@property (strong, nonatomic) WebViewController *webViewController;

@end

