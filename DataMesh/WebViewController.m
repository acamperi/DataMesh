//
//  WebViewController.m
//  DataMesh
//
//  Created by Myles Novick on 12/1/14.
//  Copyright (c) 2014 Myles Novick. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@property (strong, nonatomic) UITextField *searchBar;
@property (strong, nonatomic) UIWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat statusHeight = 20., barHeight = 50.;
    self.view.backgroundColor = [UIColor grayColor];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    doneButton.frame = CGRectMake(0, statusHeight, barHeight, barHeight);
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:doneButton];
    
    self.searchBar = [[UITextField alloc] initWithFrame:CGRectMake(barHeight, statusHeight, self.view.frame.size.width - barHeight, barHeight)];
    self.searchBar.returnKeyType = UIReturnKeyGo;
    self.searchBar.delegate = self;
    self.searchBar.layer.borderWidth = 1.;
    [self.view addSubview:self.searchBar];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, barHeight + statusHeight, self.view.frame.size.width, self.view.frame.size.height - barHeight)];
    [self.view addSubview:self.webView];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    NSLog(@"SENDING REQUEST TO LOAD CONTENT");
    [self.delegate loadContentForURL:textField.text];
    return YES;
}

- (void)renderHTML:(NSString *)HTML withBaseURL:(NSURL *)baseURL
{
    NSLog(@"RENDERING HTML");
    [self.webView loadHTMLString:HTML baseURL:baseURL];
}

- (void)done {
    [self.delegate webViewControllerDidFinish:self];
}

@end
