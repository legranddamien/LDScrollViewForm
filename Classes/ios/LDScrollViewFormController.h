//
//  LDScrollViewFormController.h
//  LDScrollViewForm
//
//  Created by Damien Legrand on 27/11/2013.
//  Copyright (c) 2013 Damien Legrand. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LDScrollViewFormController : UIViewController <UITextFieldDelegate, UITextViewDelegate> {
    UIScrollView *_form;
    CGFloat _initalBottomInset;
    BOOL _isAnimating;
    BOOL _enableObserver;
    BOOL _isKeyboardOnScreen;
    BOOL _animatingRotation;
    NSMutableDictionary *textViewHeights;
}

@property (nonatomic) CGFloat heightAboveKeyboard;

- (void)setForm:(UIScrollView *)view;


@end
