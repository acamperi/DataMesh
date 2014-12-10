//
//  ViewController.m
//  DataMesh
//
//  Created by Myles Novick on 11/30/14.
//  Copyright (c) 2014 Myles Novick. All rights reserved.
//

#import "ViewController.h"

#define PROVIDER_PASSCODE_KEY @"ProviderPasscodeKey"
#define IS_PROVIDER_KEY @"IsProviderKey"
#define ACCOUNT_CREDIT_KEY @"AccountCreditKey"

#define REQUEST_HEADER @"REQUEST:"

#define ADVERTISEMENT_DISTANCE @"AdDist"
#define MAX_ADVERTISEMENT_DISTANCE 10

static NSString * const dataProviderServiceType = @"DM-provider";


@interface ViewController ()

@end

@implementation ViewController
{
    UILabel *providerLabel;
    UISwitch *providerSwitch;
    UITextField *providerPasscode;
    UILabel *connectionLabel;
    UIView *browseButton;
    UILabel *accountCreditLabel;
    MCPeerID *localPeerID;
    
    MCNearbyServiceBrowser *peerBrowser;
    MCNearbyServiceAdvertiser *peerAdvertiser;
    NSMutableDictionary *validProviders;
    
    NSString *goalContentURLString;
    MCSession *_session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    validProviders = [NSMutableDictionary dictionary];//[NSMutableSet set];
    
//    NSMutableDictionary *foo = [NSMutableDictionary dictionary];
//    [foo removeObjectForKey:@"foo"];
//    [foo setObject:@"1" forKey:@"foo"];
//    NSLog(@"%lu", (unsigned long)foo.count);
////    [foo removeObjectForKey:@"foo"];
////    NSLog(@"%lu", (unsigned long)foo.count);
//    for (NSString *key in foo.keyEnumerator) {
//        NSLog(@"%@", key);
//        NSLog(@"%@", foo[key]);
//    }
//    return;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:@{PROVIDER_PASSCODE_KEY: @"", IS_PROVIDER_KEY: @(NO), ACCOUNT_CREDIT_KEY: @(1000000)}];
    
    CGFloat inset = 10.;
    CGFloat verticalSpacing = 15.;
    CGFloat horizontalSpacing = 5.;
    providerLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, inset, (CGRectGetWidth(self.view.bounds) - inset * 2.) / 1.5, 100.)];
    providerLabel.font = [UIFont boldSystemFontOfSize:20.];
    providerLabel.textAlignment = NSTextAlignmentCenter;
    providerLabel.textColor = [UIColor darkGrayColor];
    providerLabel.text = @"Provider:";
    providerSwitch = [[UISwitch alloc] initWithFrame:
                            CGRectMake(CGRectGetMaxX(providerLabel.frame) + horizontalSpacing, inset, CGRectGetWidth(self.view.bounds) - inset - CGRectGetMaxX(providerLabel.frame) - horizontalSpacing, 100.)];
    providerSwitch.center = CGPointMake(CGRectGetMidX(providerSwitch.frame), CGRectGetMidY(providerLabel.frame));
    providerSwitch.on = [userDefaults boolForKey:IS_PROVIDER_KEY];
    [providerSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    providerPasscode = [[UITextField alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(providerLabel.frame) + verticalSpacing, CGRectGetWidth(self.view.bounds) - inset * 2., 50.)];
    providerPasscode.borderStyle = UITextBorderStyleRoundedRect;
    providerPasscode.textAlignment = NSTextAlignmentCenter;
    providerPasscode.placeholder = @"Passcode For Free Tethering";
    providerPasscode.font = [UIFont boldSystemFontOfSize:20.];
    providerPasscode.textColor = [UIColor darkGrayColor];
//    [providerPasscode sizeToFit];
//    providerPasscode.frame = CGRectOffset(providerPasscode.frame, -10., -10.);
    providerPasscode.center = CGPointMake(self.view.center.x, CGRectGetMidY(providerPasscode.frame));
    providerPasscode.delegate = (id <UITextFieldDelegate>) self;
    
    if ([[userDefaults objectForKey:PROVIDER_PASSCODE_KEY] length] > 0)
        providerPasscode.text = [userDefaults objectForKey:PROVIDER_PASSCODE_KEY];
    
    connectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(providerPasscode.frame) + verticalSpacing, CGRectGetWidth(self.view.bounds) - inset * 2., 50.)];
    connectionLabel.font = [UIFont systemFontOfSize:20.];
    connectionLabel.textAlignment = NSTextAlignmentCenter;
    connectionLabel.textColor = [UIColor darkGrayColor];
    connectionLabel.text = @"Searching for Providers...";
    
    browseButton = [[UIView alloc] initWithFrame:connectionLabel.frame];
    browseButton.layer.cornerRadius = 5.;
    browseButton.layer.borderWidth = 1.;
    browseButton.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    UILabel *browseButtonLabel = [[UILabel alloc] initWithFrame:browseButton.bounds];
    browseButtonLabel.font = [UIFont boldSystemFontOfSize:20.];
    browseButtonLabel.textAlignment = NSTextAlignmentCenter;
    browseButtonLabel.textColor = [UIColor darkGrayColor];
    browseButtonLabel.text = @"Browse";
    [browseButton addSubview:browseButtonLabel];
    [browseButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(browseButtonTapped)]];
    
    accountCreditLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(browseButton.frame) + verticalSpacing, CGRectGetWidth(self.view.bounds) - inset * 2., 50.)];
    accountCreditLabel.font = [UIFont systemFontOfSize:20.];
    accountCreditLabel.textAlignment = NSTextAlignmentCenter;
    accountCreditLabel.textColor = [UIColor darkGrayColor];
    accountCreditLabel.text = [NSString stringWithFormat:@"Credit: %ld", [userDefaults integerForKey:ACCOUNT_CREDIT_KEY]];
    
    [self.view addSubview:providerLabel];
    [self.view addSubview:providerSwitch];
    [self.view addSubview:providerPasscode];
    [self.view addSubview:connectionLabel];
    [self.view addSubview:browseButton];
    [self.view addSubview:accountCreditLabel];
    
    browseButton.hidden = YES;
    
    // network code starts
    localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    [self refreshMySession];
    [self startAdvertising];
    [self startBrowsing];
}

- (void)updateCreditWithChange:(NSInteger)change
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger newAmount = [userDefaults integerForKey:ACCOUNT_CREDIT_KEY] + change;
    [userDefaults setObject:@(newAmount) forKey:ACCOUNT_CREDIT_KEY];
    dispatch_async(dispatch_get_main_queue(), ^{
            accountCreditLabel.text = [NSString stringWithFormat:@"Credit: %ld", newAmount];
    });
}

#pragma mark - Network Code

- (void)resetMyMesh
{
    [peerAdvertiser stopAdvertisingPeer];
    peerAdvertiser = nil;
    [self startAdvertising];
    [self refreshMySession];
}

- (void)refreshMySession
{
    [_session disconnect];
    _session = nil;
    _session = [[MCSession alloc] initWithPeer:localPeerID];
    _session.delegate = self;
}

- (void)startBrowsing
{
    NSLog(@"STARTING BROWSING");
    peerBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:localPeerID serviceType:dataProviderServiceType];
    peerBrowser.delegate = self;
    [peerBrowser startBrowsingForPeers];
}

- (void)startAdvertising
{
    if (!peerAdvertiser)
    {
        NSLog(@"STARTING ADVERTISING");
        MCPeerID *closestDistributingPeer = [self closestDistributingPeerID];
        int distance = providerSwitch.on ? 0 : closestDistributingPeer ? [(validProviders[closestDistributingPeer][ADVERTISEMENT_DISTANCE]) intValue] + 1 : -1;
        if (distance < 0 || distance > MAX_ADVERTISEMENT_DISTANCE)
            return;
        peerAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:localPeerID discoveryInfo:@{ADVERTISEMENT_DISTANCE: @(distance)}
                                                             serviceType:dataProviderServiceType];
        peerAdvertiser.delegate = self;
        [peerAdvertiser startAdvertisingPeer];
    }
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context
 invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"RECIEVED INVITATION");
    // to ignore/reject call: invitationHandler(NO, nil);
    [self refreshMySession];
    invitationHandler(YES, _session);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"FOUND PEER: %@", peerID);
    @synchronized(validProviders)
    {
        [validProviders setObject:info forKey:peerID];
//        [validProviders addObject:peerID];
        if (validProviders.count)
        {
            connectionLabel.hidden = YES;
            browseButton.hidden = NO;
        }
        else
        {
            connectionLabel.hidden = NO;
            browseButton.hidden = YES;
        }
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"LOST PEER: %@", peerID);
    @synchronized(validProviders)
    {
//        [validProviders removeObject:peerID];
        [validProviders removeObjectForKey:peerID];
        if (validProviders.count)
        {
            connectionLabel.hidden = YES;
            browseButton.hidden = NO;
        }
        else
        {
            connectionLabel.hidden = NO;
            browseButton.hidden = YES;
        }
    }
}

- (MCPeerID *)closestDistributingPeerID
{
    if (validProviders.count)
    {
        int lowestDistance = MAX_ADVERTISEMENT_DISTANCE + 1;
        MCPeerID *peer = nil;
        for (MCPeerID *key in validProviders.keyEnumerator)
        {
            int distance = [(validProviders[key][ADVERTISEMENT_DISTANCE]) intValue];
            if (distance < lowestDistance)
            {
                peer = key;
                lowestDistance = distance;
            }
        }
        return peer;
    }
    return nil;
}

- (void)loadContentForURL:(NSString *)urlString
{
    @synchronized(validProviders)
    {
        if (validProviders.count)
        {
            NSLog(@"ATTEMPTING TO CREATE SESSION");
            goalContentURLString = urlString;
            [self refreshMySession];
            [peerBrowser invitePeer:[self closestDistributingPeerID] toSession:_session withContext:nil timeout:30.];
        }
        else
        {
            NSLog(@"NO PEERS FOUND");
        }
    }
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateNotConnected)
    {
        [self resetMyMesh];
    }
    else if (goalContentURLString && state == MCSessionStateConnected)
    {
        if ([session sendData:[[NSString stringWithFormat:@"%@%@", REQUEST_HEADER, goalContentURLString] dataUsingEncoding:NSASCIIStringEncoding] toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil])
        {
            // successful request, waiting for response
            NSLog(@"Request was sent");
        }
        else
        {
            // failure to request
            NSLog(@"Request failed to send");
            [session disconnect];
            session = nil;
        }
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString *stringInterpretation = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if (stringInterpretation && [stringInterpretation hasPrefix:REQUEST_HEADER])
    {
        NSString *requestString = [stringInterpretation substringFromIndex:REQUEST_HEADER.length];
        if (providerSwitch.on)
        {
            NSError *error;
            NSString *loadedHTMLString = [NSString stringWithContentsOfURL:[NSURL URLWithString:requestString] encoding:NSASCIIStringEncoding error:nil];
            [self updateCreditWithChange:loadedHTMLString.length];
            NSData *HTMLData = [loadedHTMLString dataUsingEncoding:NSUTF8StringEncoding];
            if ([session sendData:HTMLData toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error])
            {
                // successful reply with web content
                NSLog(@"Web content was sent");
            }
            else
            {
                // failure to reply with web content
                NSLog(@"%@", loadedHTMLString);
                NSLog(@"%@", HTMLData);
                NSLog(@"%@", stringInterpretation);
                NSLog(@"%@", session);
                NSLog(@"%@", peerID);
                NSLog(@"%@", error);
                NSLog(@"Web content failed to send");
                [session disconnect];
                session = nil;
            }
        }
    }
    else
    {
        NSLog(@"%@", stringInterpretation);
        NSLog(@"RECIEVED WEB CONTENT");
        [self refreshMySession];
        [self.webViewController renderHTML:stringInterpretation withBaseURL:[[NSURL URLWithString:goalContentURLString] baseURL]];
        [self updateCreditWithChange:-stringInterpretation.length];
    }
}

#pragma mark - UI Code

- (void)browseButtonTapped
{
    NSLog(@"BROWSE BUTTON TAPPED");
    if (!self.webViewController) {
        WebViewController *controller = [[WebViewController alloc] init];
        controller.delegate = self;
        controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        self.webViewController = controller;
    }
    [self presentViewController:self.webViewController animated:YES completion:nil];
}

- (void)switchValueChanged:(UISwitch *)theSwitch
{
    [[NSUserDefaults standardUserDefaults] setObject:@(theSwitch.on) forKey:IS_PROVIDER_KEY];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.text.length > 0)
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:PROVIDER_PASSCODE_KEY];
    else
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:PROVIDER_PASSCODE_KEY];
}

- (void)webViewControllerDidFinish:(WebViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end