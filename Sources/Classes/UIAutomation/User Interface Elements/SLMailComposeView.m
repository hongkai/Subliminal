//
//  SLMailComposeView.m
//  Subliminal
//
//  Created by Jeffrey Wear on 5/25/14.
//  Copyright (c) 2014 Inkling. All rights reserved.
//

#import "SLMailComposeView.h"
#import "SLUIAElement+Subclassing.h"

#import "SLTerminal+ConvenienceFunctions.h"
#import "SLGeometry.h"
#import "SLKeyboard.h"
#import "SLNavigationBar.h"
#import "SLActionSheet.h"

typedef NS_ENUM(NSUInteger, SLMailComposeViewChildType) {
    SLMailComposeViewChildTypeToField,
    SLMailComposeViewChildTypeCcBccLabel,
    SLMailComposeViewChildTypeCcField,
    SLMailComposeViewChildTypeBccField,
    SLMailComposeViewChildTypeSubjectField,
    SLMailComposeViewChildTypeBodyView
};

@implementation SLMailComposeView {
    SLStaticElement *_toField;
    SLStaticElement *_ccBccLabel, *_ccField, *_bccField;
    SLStaticElement *_subjectField;
    SLStaticElement *_bodyView;
}

+ (NSString *)UIAChildSelectorForChildOfType:(SLMailComposeViewChildType)type {
    switch (type) {
        case SLMailComposeViewChildTypeToField:
            return @"textFields()['toField']";
        case SLMailComposeViewChildTypeCcBccLabel:
            return @"staticTexts()['Cc/Bcc:']";
        case SLMailComposeViewChildTypeCcField:
            return @"textFields()['ccField']";
        case SLMailComposeViewChildTypeBccField:
            return @"textFields()['bccField']";
        case SLMailComposeViewChildTypeSubjectField:
            return @"textFields()['subjectField']";
        case SLMailComposeViewChildTypeBodyView:
            return @"textViews()['Message body']";
    }
}

+ (instancetype)currentComposeView {
    // UIAutomation does not provide an interface to the compose view
    // (e.g. on `UIAApplication`, like other system views).
    // We identify a view as the compose view if it has the children of a compose view.
    return [[self alloc] initWithUIARepresentation:[NSString stringWithFormat:@"\
                (function(){\
                    var candidateView = UIATarget.localTarget().frontMostApp().mainWindow().scrollViews()[0];\
                    if (candidateView.isValid() &&\
                        candidateView.%@.isValid() &&\
                        candidateView.%@.isValid() &&\
                        candidateView.%@.isValid() &&\
                        candidateView.%@.isValid() &&\
                        candidateView.%@.isValid() &&\
                        candidateView.%@.isValid()) {\
                        return candidateView;\
                    } else {"
                        // return `UIAElementNil`
                        // I don't know how to create it,
                        // so get a reference to it by attempting to retrieve an element guaranteed not to exist
                        @"return UIATarget.localTarget().frontMostApp().elements()['%@: %p'];\
                    }\
                })()",
                [self UIAChildSelectorForChildOfType:SLMailComposeViewChildTypeToField],
                [self UIAChildSelectorForChildOfType:SLMailComposeViewChildTypeCcBccLabel],
                [self UIAChildSelectorForChildOfType:SLMailComposeViewChildTypeCcField],
                [self UIAChildSelectorForChildOfType:SLMailComposeViewChildTypeBccField],
                [self UIAChildSelectorForChildOfType:SLMailComposeViewChildTypeSubjectField],
                [self UIAChildSelectorForChildOfType:SLMailComposeViewChildTypeBodyView],
                NSStringFromClass(self), self]];
}

- (instancetype)initWithUIARepresentation:(NSString *)UIARepresentation {
    self = [super initWithUIARepresentation:UIARepresentation];
    if (self) {
        NSString *(^UIARepresentationForChildOfType)(SLMailComposeViewChildType) = ^(SLMailComposeViewChildType type) {
            return [UIARepresentation stringByAppendingFormat:@".%@", [[self class] UIAChildSelectorForChildOfType:type]];
        };
        
        _toField = [[SLStaticElement alloc] initWithUIARepresentation:UIARepresentationForChildOfType(SLMailComposeViewChildTypeToField)];
        _ccBccLabel = [[SLStaticElement alloc] initWithUIARepresentation:UIARepresentationForChildOfType(SLMailComposeViewChildTypeCcBccLabel)];
        _ccField = [[SLStaticElement alloc] initWithUIARepresentation:UIARepresentationForChildOfType(SLMailComposeViewChildTypeCcField)];
        _bccField = [[SLStaticElement alloc] initWithUIARepresentation:UIARepresentationForChildOfType(SLMailComposeViewChildTypeBccField)];
        _subjectField = [[SLStaticElement alloc] initWithUIARepresentation:UIARepresentationForChildOfType(SLMailComposeViewChildTypeSubjectField)];
        _bodyView = [[SLStaticElement alloc] initWithUIARepresentation:UIARepresentationForChildOfType(SLMailComposeViewChildTypeBodyView)];
    }
    return self;
}

#pragma mark - Reading and Setting Mail Fields

/**
 A general note on error handling in the mail field setters and getters:
 these methods, like all of `SLMailComposeView`'s interface (save `+currentComposeView`),
 require that the compose view be valid.
 
 However, it is not necessary to check `-[self isValid]` in these methods because
 the mail fields are derived from the compose view--that is, their UIAutomation
 representations are derived from that of the compose view. This causes them to
 be valid if and only if the compose view is valid, and attempting to manipulate
 the fields will cause suitable exceptions to be thrown if the compose view is not valid.
 */

/**
 When the recipient fields contain multiple recipients and don't have keyboard
 focus, they collapse and truncate the display of the secondary recipients
 (e.g. read "foo@example.com & 1 more...").
 
 To read all recipients, a field must first be given the keyboard focus (so that
 it will expand). But even when expanded, the `value()` of a field with multiple
 recipients will still be truncated. So, the recipients must be read as the `name()`s
 of the "recipient buttons" within the field.
 
 Note that the effective _rect_ of a recipient field is *not* the `rect()` of the field
 itself--that rect will occupy only the first row of buttons. The effective rect
 occupies the area from the top of the field, to the top of the next field.
 */
- (NSArray *)recipientsInFieldWithRect:(CGRect)rect {
    NSString *recipientsJSONString = [[SLTerminal sharedTerminal] evalFunctionWithName:@"SLMailComposeViewNamesOfRecipientButtonsInRect"
                                                                                params:@[ @"rect" ]
                                                                                  body:[NSString stringWithFormat:@"\
                                                                                        var names = [];\
                                                                                        var mailButtons = %@.buttons().toArray();\
                                                                                        mailButtons.forEach(function(button) {\
                                                                                            var buttonName = button.name();\
                                                                                            if (%@.%@(rect, button.rect()) &&\
                                                                                                (buttonName !== 'Add Contact')) {\
                                                                                                names.push(buttonName);\
                                                                                            }\
                                                                                        });\
                                                                                        return JSON.stringify(names);\
                                                                                        ", _UIARepresentation, [[SLTerminal sharedTerminal] scriptNamespace], SLUIARectContainsRectFunctionName()]
                                                                              withArgs:@[ SLUIARectFromCGRect(rect) ]];
    NSData *recipientsJSONData = [recipientsJSONString dataUsingEncoding:NSUTF8StringEncoding];
    if (!recipientsJSONData) return nil;

    return [NSJSONSerialization JSONObjectWithData:recipientsJSONData options:0 error:NULL];
}

- (void)setContentsOfField:(SLUIAElement *)field toRecipients:(NSArray *)recipients {
    // Bring up the keyboard
    if (![field hasKeyboardFocus]) [field tap];

    // Clear the contents of the field
    [field waitUntilTappable:YES thenSendMessage:@"setValue('')"];

    // Add the recipients
    for (NSString *recipient in recipients) {
        [[SLKeyboard keyboard] typeString:recipient];
        // Hitting enter confirms the recipient, turning it into a button (see `-recipientsInFieldWithRect:`)
        // The need to confirm is also why we can't use `setValue()`.
        [[SLKeyboard keyboard] typeString:@"\n"];
    }
}

/// See comment on `recipientsInFieldWithRect:` for explanation.
- (NSArray *)toRecipients {
    if (![_toField hasKeyboardFocus]) [_toField tap];

    CGRect toFieldRect = [_toField rect], ccFieldRect = [_ccField rect];
    toFieldRect.size.height = CGRectGetMinY(ccFieldRect) - CGRectGetMinY(toFieldRect);

    return [self recipientsInFieldWithRect:toFieldRect];
}

- (void)setToRecipients:(NSArray *)toRecipients {
    [self setContentsOfField:_toField toRecipients:toRecipients];
}

/// See comment on `recipientsInFieldWithRect:` for explanation.
- (NSArray *)ccRecipients {
    // The "Cc/Bcc:" label is visible iff the "Cc:" and "Bcc:" fields are empty
    // (the label is shown next to a unified (collapsed) field).
    // This is the fastest way to determine if the "Cc:" field is empty,
    // plus we shouldn't rely on the field being tappable when collapsed (though it is, weirdly).
    if ([_ccBccLabel isValidAndVisible]) return @[];

    if (![_ccField hasKeyboardFocus]) [_ccField tap];

    CGRect ccFieldRect = [_ccField rect], bccFieldRect = [_bccField rect];
    ccFieldRect.size.height = CGRectGetMinY(bccFieldRect) - CGRectGetMinY(ccFieldRect);

    return [self recipientsInFieldWithRect:ccFieldRect];
}

- (void)setCcRecipients:(NSArray *)ccRecipients {
    // If the "cc" and "bcc" fields are collapsed, we need to show the "bcc" field
    // before we can tap it to bring up the keyboard (in `-setContentsOfField:toRecipients:`).
    // Tapping the "bcc" field expands the "cc" and "bcc" fields.
    // (The "cc" field is not tappable if collapsed, fyi.)
    if ([_ccBccLabel isValidAndVisible]) [_bccField tap];

    [self setContentsOfField:_ccField toRecipients:ccRecipients];
}

/// See comment on `recipientsInFieldWithRect:` for explanation.
- (NSArray *)bccRecipients {
    // The "Cc/Bcc:" label is visible iff the "Cc:" and "Bcc:" fields are empty
    // (the label is shown next to a unified (collapsed) field).
    // This is the fastest way to determine if the "Bcc:" field is empty,
    // plus we shouldn't rely on the field being tappable when collapsed (though it is, weirdly).
    if ([_ccBccLabel isValidAndVisible]) return @[];

    if (![_bccField hasKeyboardFocus]) [_bccField tap];

    CGRect bccFieldRect = [_bccField rect], subjectFieldRect = [_subjectField rect];
    bccFieldRect.size.height = CGRectGetMinY(subjectFieldRect) - CGRectGetMinY(bccFieldRect);

    return [self recipientsInFieldWithRect:bccFieldRect];
}

- (void)setBccRecipients:(NSArray *)bccRecipients {
    // If the "cc" and "bcc" fields are collapsed, we need to show the "bcc" field
    // before we can tap it to bring up the keyboard (in `-setContentsOfField:toRecipients:`).
    // Tapping the "bcc" field expands the "cc" and "bcc" fields.
    if ([_ccBccLabel isValidAndVisible]) [_bccField tap];

    [self setContentsOfField:_bccField toRecipients:bccRecipients];
}

- (NSString *)subject {
    return [_subjectField value];
}

- (void)setSubject:(NSString *)subject {
    // We don't need to use the keyboard to type the value here (as normal),
    // but can rather use the faster and more robust `setValue()`,
    // because the subject field is a private subview of the mail compose view,
    // so the application can't observe the text changing. It's also ok to violate
    // our "test like a user" mantra because we're not responsible for testing system views.
    [_subjectField waitUntilTappable:YES thenSendMessage:@"setValue('%@')", [subject slStringByEscapingForJavaScriptLiteral]];
}

- (NSString *)body {
    return [_bodyView value];
}

- (void)setBody:(NSString *)body {
    // We don't need to use the keyboard to type the value here (as normal),
    // but can rather use the faster and more robust `setValue()`,
    // because the body view is a private subview of the mail compose view,
    // so the application can't observe the text changing. It's also ok to violate
    // our "test like a user" mantra because we're not responsible for testing system views.
    [_bodyView waitUntilTappable:YES thenSendMessage:@"setValue('%@')", [body slStringByEscapingForJavaScriptLiteral]];
}

#pragma mark - Sending Mail

- (BOOL)sendMessage {
    __block BOOL didSendMessage = NO;
    
    // Use this as convenience to perform the waiting and, if necessary, exception throwing
    // the sheet itself doesn't technically need to be tappable,
    // but as the user is "acting upon the sheet", we pass `YES` for _waitUntilTappable_
    [self waitUntilTappable:YES thenPerformActionWithUIARepresentation:^(NSString *UIARepresentation) {
        SLUIAElement *sendButton = [[SLNavigationBar currentNavigationBar] rightButton];
        if (![sendButton isEnabled]) return;
        
        [sendButton tap];
        didSendMessage = YES;
    } timeout:[[self class] defaultTimeout]];
    
    return didSendMessage;
}

- (BOOL)cancelAndDeleteDraft:(BOOL)deleteDraft {
    __block BOOL draftWasInProgress = NO;
    
    // Use this as convenience to perform the waiting and, if necessary, exception throwing
    // the sheet itself doesn't technically need to be tappable,
    // but as the user is "acting upon the sheet", we pass `YES` for _waitUntilTappable_
    [self waitUntilTappable:YES thenPerformActionWithUIARepresentation:^(NSString *UIARepresentation) {
        SLUIAElement *cancelButton = [[SLNavigationBar currentNavigationBar] leftButton];
        [cancelButton tap];
        
        // Wait for the action sheet to show up if it will (i.e. if there was a draft in progress)
        [NSThread sleepForTimeInterval:0.3];
        
        SLActionSheet *draftActionSheet = [SLActionSheet currentActionSheet];
        if ([draftActionSheet isValidAndVisible]) {
            draftWasInProgress = YES;
            
            NSArray *draftActionButtons = [draftActionSheet buttons];
            
            NSString *buttonTitle = deleteDraft ? @"Delete Draft" : @"Save Draft";
            NSUInteger buttonIndex = [draftActionButtons indexOfObjectPassingTest:^BOOL(SLUIAElement *button, NSUInteger idx, BOOL *stop) {
                return [[button label] isEqualToString:buttonTitle];
            }];
            NSAssert(buttonIndex != NSNotFound,
                     @"Option to %@ draft not found.", deleteDraft ? @"delete" : @"cancel");
            [draftActionButtons[buttonIndex] tap];
        }
    } timeout:[[self class] defaultTimeout]];
    
    return draftWasInProgress;
}

@end
