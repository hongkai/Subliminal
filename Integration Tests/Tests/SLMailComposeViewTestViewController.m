//
//  SLMailComposeViewTestViewController.m
//  Subliminal
//
//  Created by Jeffrey Wear on 5/24/14.
//  Copyright (c) 2014 Inkling. All rights reserved.
//

#import "SLTestCaseViewController.h"

#import <Subliminal/SLTestController+AppHooks.h>
#import <MessageUI/MessageUI.h>

@interface SLMailComposeViewTestViewController : SLTestCaseViewController <MFMailComposeViewControllerDelegate>
@end

@implementation SLMailComposeViewTestViewController {
    MFMailComposeViewController *_composeViewController;
    MFMailComposeResult _composeViewControllerFinishResult;
}

- (void)loadViewForTestCase:(SEL)testCase {
    // Since we're testing the mail compose view,
    // we don't need any particular view.
    [self loadGenericView];
}

- (instancetype)initWithTestCaseWithSelector:(SEL)testCase {
    self = [super initWithTestCaseWithSelector:testCase];
    if (self) {
        SLTestController *testController = [SLTestController sharedTestController];
        [testController registerTarget:self forAction:@selector(composeViewControllerIsPresented)];
        [testController registerTarget:self forAction:@selector(presentComposeViewControllerWithInfo:)];
        [testController registerTarget:self forAction:@selector(composeViewControllerFinishResult)];
        [testController registerTarget:self forAction:@selector(dismissComposeViewController)];
    }
    return self;
}

- (void)dealloc {
    [[SLTestController sharedTestController] deregisterTarget:self];
}

#pragma mark - App hooks

- (NSNumber *)composeViewControllerIsPresented {
    return @(_composeViewController != nil);
}

- (void)presentComposeViewControllerWithInfo:(NSDictionary *)info {
    MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
    composeViewController.mailComposeDelegate = self;

    if (info[@"toRecipients"])  [composeViewController setToRecipients:info[@"toRecipients"]];
    if (info[@"ccRecipients"])  [composeViewController setCcRecipients:info[@"ccRecipients"]];
    if (info[@"bccRecipients"]) [composeViewController setBccRecipients:info[@"bccRecipients"]];
    if (info[@"subject"])       [composeViewController setSubject:info[@"subject"]];
    if (info[@"body"])          [composeViewController setMessageBody:info[@"body"] isHTML:NO];

    // Present the controller without animation just for parity with dismissal.
    [self presentViewController:composeViewController animated:NO completion:^{
        _composeViewController = composeViewController;
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    _composeViewControllerFinishResult = result;
    [self dismissComposeViewController];
}

- (NSValue *)composeViewControllerFinishResult {
    return [NSValue valueWithBytes:&_composeViewControllerFinishResult
                          objCType:@encode(__typeof(_composeViewControllerFinishResult))];
}

- (void)dismissComposeViewController {
    if (!_composeViewController) return;

    // Dismiss the controller without animation because sometimes it fails with animation
    // --the controller just doesn't dismiss.
    [self dismissViewControllerAnimated:NO completion:^{
        _composeViewController = nil;
    }];
}

@end
