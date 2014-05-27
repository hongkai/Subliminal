//
//  SLNavigationBarTest.m
//  Subliminal
//
//  Created by Jeffrey Wear on 5/26/14.
//  Copyright (c) 2014 Inkling. All rights reserved.
//

#import "SLIntegrationTest.h"

@interface SLNavigationBarTest : SLIntegrationTest

@end

@implementation SLNavigationBarTest {
    NSString *_rightButtonTitle;
}

+ (NSString *)testCaseViewControllerClassName {
    return @"SLNavigationBarTestViewController";
}

- (void)setUpTestCaseWithSelector:(SEL)testCaseSelector {
    [super setUpTestCaseWithSelector:testCaseSelector];

    if (testCaseSelector == @selector(testLeftButtonIsInvalidIfThereIsNoLeftButton)) {
        // The left button is the automatic "Back" button.
        // It's ok to remove it because the app will programmatically
        // pop the current view controller.
        SLAskApp(removeLeftButton);
    } else if (testCaseSelector == @selector(testCanMatchRightButton)) {
        _rightButtonTitle = @"Test";
        SLAskApp1(addRightButtonWithTitle:, _rightButtonTitle);
    }
}

- (void)testCanMatchNavigationBar {
    CGRect navigationBarRect, expectedNavigationBarRect = [SLAskApp(navigationBarFrameValue) CGRectValue];
    SLAssertNoThrow(navigationBarRect = [[SLNavigationBar currentNavigationBar] rect],
                    @"The navigation bar should exist.");
    SLAssertTrue(CGRectEqualToRect(navigationBarRect, expectedNavigationBarRect),
                 @"The navigation bar's frame does not match the expected navigation bar frame.");
}

- (void)testCanReadTitle {
    NSString *expectedNavigationBarTitle = NSStringFromSelector(_cmd);
    NSString *actualNavigationBarTitle = [[SLNavigationBar currentNavigationBar] title];
    SLAssertTrue([actualNavigationBarTitle isEqualToString:expectedNavigationBarTitle],
                 @"The navigation bar's title was not equal to the expected value.");
}

- (void)testCanMatchLeftButton {
    NSString *actualLeftButtonTitle, *expectedLeftButtonTitle = @"Back";
    SLAssertNoThrow(actualLeftButtonTitle = [[[SLNavigationBar currentNavigationBar] leftButton] label],
                    @"Should have been able to retrieve the title of the navigation bar's left button.");
    SLAssertTrue([actualLeftButtonTitle isEqualToString:expectedLeftButtonTitle],
                 @"The navigation bar's left button did not have the expected title.");
}

- (void)testLeftButtonIsInvalidIfThereIsNoLeftButton {
    BOOL leftButtonIsValid = NO;
    SLAssertNoThrow(leftButtonIsValid = [[[SLNavigationBar currentNavigationBar] leftButton] isValid],
                    @"It should have been safe to access the navigation bar's left button even though the button doesn't exist.");
    SLAssertFalse(leftButtonIsValid,
                  @"The navigation bar's left button should be invalid.");
}

- (void)testCanMatchRightButton {
    NSString *actualRightButtonTitle, *expectedRightButtonTitle = _rightButtonTitle;
    SLAssertNoThrow(actualRightButtonTitle = [[[SLNavigationBar currentNavigationBar] rightButton] label],
                    @"Should have been able to retrieve the title of the navigation bar's right button.");
    SLAssertTrue([actualRightButtonTitle isEqualToString:expectedRightButtonTitle],
                 @"The navigation bar's right button did not have the expected title.");
}

- (void)testRightButtonIsInvalidIfThereIsNoRightButton {
    BOOL rightButtonIsValid = NO;
    SLAssertNoThrow(rightButtonIsValid = [[[SLNavigationBar currentNavigationBar] rightButton] isValid],
                    @"It should have been safe to access the navigation bar's right button even though the button doesn't exist.");
    SLAssertFalse(rightButtonIsValid,
                  @"The navigation bar's right button should be invalid.");
}

@end
