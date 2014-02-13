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
    NSMutableDictionary *limitedTextViews;
    NSMutableDictionary *limitedTextField;
    UIView *currentSelectedView;
}

@property (nonatomic) CGFloat heightAboveKeyboard;
@property (strong, nonatomic) NSArray *unsupportedViews;
@property (strong, nonatomic) NSArray *unsupportedTextViews;

/**
 *  This method start to buid your form 
 *  If your form is an edit form, before filling your fields, call this method
 *
 *  @param view The scroll view of your form
 */
- (void)setForm:(UIScrollView *)view;

/**
 *  Call This method when your form is an edit form and you already filled your fields
 */
- (void)updateForm;

/**
 *  This method help you to add a limit of characters in a UITextView
 *
 *  @param textView  The text view to limit
 *  @param maxLength the maximum length of the field
 */
- (void)textView:(UITextView *)textView limitedToMaxLength:(int)maxLength;

/**
 *  This method help you to add a limit of characters in a UITextField
 *
 *  @param textFiled  The text field to limit
 *  @param maxLength the maximum length of the field
 */
- (void)textField:(UITextField *)textField limitedToMaxLength:(int)maxLength;

/**
 *  Unsuported view are not considered when the contentSize is calculated
 *
 *  @param view the unsuported view
 */
- (void)addUnsuportedView:(UIView *)view;

/**
 *  To add text views that will not update the height to fit with the content
 *
 *  @param textView a text view in the form
 */
- (void)addUnsuportedResizingTextView:(UITextView *)textView;

/**
 *  Sometime, when a field or text view is added after on the form,
 *  you can call this method to restore delegates
 */
- (void)updateViewsObserver;

/**
 *  Find the first responder on the view and give it back
 *
 *  @param v the parent view, it will search in childs
 *
 *  @return the first responder view or nil
 */
- (UIView *)findFirstResponderWithView:(UIView *)v;

@end
