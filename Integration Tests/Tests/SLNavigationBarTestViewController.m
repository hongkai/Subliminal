//
//  SLNavigationBarTestViewController.m
//  Subliminal
//
//  Created by Jeffrey Wear on 5/26/14.
//  Copyright (c) 2014 Inkling. All rights reserved.
//

#import "SLTestCaseViewController.h"

#import <Subliminal/SLTestController+AppHooks.h>

@interface SLNavigationBarTestViewController : SLTestCaseViewController

@end

@implementation SLNavigationBarTestViewController

- (void)loadViewForTestCase:(SEL)testCase {
    [self loadGenericView];
}

- (instancetype)initWithTestCaseWithSelector:(SEL)testCase {
    self = [super initWithTestCaseWithSelector:testCase];
    if (self) {
        SLTestController *testController = [SLTestController sharedTestController];
        [testController registerTarget:self forAction:@selector(navigationBarFrameValue)];
        [testController registerTarget:self forAction:@selector(removeLeftButton)];
        [testController registerTarget:self forAction:@selector(addRightButtonWithTitle:)];
    }
    return self;
}

- (void)dealloc {
    [[SLTestController sharedTestController] deregisterTarget:self];
}

#pragma mark - App hooks

- (NSValue *)navigationBarFrameValue {
    return [NSValue valueWithCGRect:[self.navigationController.navigationBar accessibilityFrame]];
}

- (void)removeLeftButton {
    self.navigationItem.hidesBackButton = YES;
}

- (void)addRightButtonWithTitle:(NSString *)title {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:title
                                                                              style:UIBarButtonItemStylePlain target:nil action:NULL];
}

@end
