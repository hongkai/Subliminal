//
//  SLNavigationBar.m
//  Subliminal
//
//  Created by Jeffrey Wear on 5/26/14.
//  Copyright (c) 2014 Inkling. All rights reserved.
//

#import "SLNavigationBar.h"

#import "SLUIAElement+Subclassing.h"

@implementation SLNavigationBar {
    SLStaticElement *_titleLabel;
    SLStaticElement *_leftButton, *_rightButton;
}

+ (instancetype)currentNavigationBar {
    return [[self alloc] initWithUIARepresentation:@"UIATarget.localTarget().frontMostApp().navigationBar()"];
}

- (instancetype)initWithUIARepresentation:(NSString *)UIARepresentation {
    self = [super initWithUIARepresentation:UIARepresentation];
    if (self) {
        _titleLabel = [[SLStaticElement alloc] initWithUIARepresentation:[UIARepresentation stringByAppendingString:@".staticTexts()[0]"]];
        _leftButton = [[SLStaticElement alloc] initWithUIARepresentation:[UIARepresentation stringByAppendingString:@".leftButton()"]];
        _rightButton = [[SLStaticElement alloc] initWithUIARepresentation:[UIARepresentation stringByAppendingString:@".rightButton()"]];
    }
    return self;
}

- (NSString *)title {
    NSString *__block title;

    // Use this as convenience to perform the waiting and, if necessary, exception throwing
    [self waitUntilTappable:NO thenPerformActionWithUIARepresentation:^(NSString *UIARepresentation) {
        // The title label will not exist unless the view controller has a non-empty title.
        // The default value of `-[UIViewController title]` is `nil`.
        title = [_titleLabel isValid] ? [_titleLabel label] : nil;
    } timeout:[[self class] defaultTimeout]];

    return title;
}

- (SLUIAElement *)leftButton {
    SLUIAElement *__block leftButton;

    // Use this as convenience to perform the waiting and, if necessary, exception throwing
    [self waitUntilTappable:NO thenPerformActionWithUIARepresentation:^(NSString *UIARepresentation) {
        leftButton = _leftButton;
    } timeout:[[self class] defaultTimeout]];

    return leftButton;
}

- (SLUIAElement *)rightButton {
    SLUIAElement *__block rightButton;

    // Use this as convenience to perform the waiting and, if necessary, exception throwing
    [self waitUntilTappable:NO thenPerformActionWithUIARepresentation:^(NSString *UIARepresentation) {
        rightButton = _rightButton;
    } timeout:[[self class] defaultTimeout]];

    return rightButton;
}

@end
