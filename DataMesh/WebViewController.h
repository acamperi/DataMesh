//
//  WebViewController.h
//  DataMesh
//
//  Created by Myles Novick on 12/1/14.
//  Copyright (c) 2014 Myles Novick. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WebViewController;

@protocol WebViewControllerDelegate
- (void)webViewControllerDidFinish:(WebViewController *)controller;
- (void)loadContentForURL:(NSString *)urlString;
@end

@interface WebViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) id<WebViewControllerDelegate> delegate;

//- (void)renderData:(NSData *)data;
- (void)renderHTML:(NSString *)HTML withBaseURL:(NSURL *)baseURL;

@end
