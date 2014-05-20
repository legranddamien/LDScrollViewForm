//
//  LDScrollViewFormController.m
//  LDScrollViewForm
//
//  Created by Damien Legrand on 27/11/2013.
//  Copyright (c) 2013 Damien Legrand. All rights reserved.
//

#import "LDScrollViewFormController.h"

@interface LDScrollViewFormController ()

- (void)setupForm;
- (void)defineContentSize;

- (void)observeViews:(NSArray *)views;
- (void)observeKeyboard;
- (void)removeViewsObservers:(NSArray *)views;
- (void)removeKeyboardObservers;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

- (void)avoidKeyboard;
- (void)avoidKeyboardForView:(UIView *)v;
- (void)avoidKeyboardForTextViewSelection:(UITextView *)v;

- (UIView *)findFirstResponderWithView:(UIView *)v;

- (void)touche:(UITapGestureRecognizer *)gesture;

- (void)nextView;

- (UIView *)findNextViewWithCurrentView:(UIView *)currentView inForm:(UIView *)form;

- (void)updateHeightForTextView:(UITextView *)textView withAnimated:(BOOL)animation;
- (BOOL)moveAllViewsUnderView:(UIView *)currentView withDistance:(CGFloat)distance inView:(UIView *)view;

- (void)updateFormWithView:(UIView *)view;

- (BOOL)isViewNotOk:(UIView *)view;

@end

@implementation LDScrollViewFormController






#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(_form != nil)
    {
        [self observeViews:_form.subviews];
        [self observeKeyboard];
        [self updateForm];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if(_form != nil)
    {
        [self removeViewsObservers:_form.subviews];
        textViewHeights = nil;
        [self removeKeyboardObservers];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}






#pragma mark - Public Methods

- (void)setForm:(UIScrollView *)view
{
    _form = view;
    [self setupForm];
}

- (void)textView:(UITextView *)textView limitedToMaxLength:(int)maxLength
{
    if(_form == nil) return;
    
    if(limitedTextViews == nil)
    {
        limitedTextViews = [NSMutableDictionary dictionary];
    }
    
    NSValue *key = [NSValue valueWithNonretainedObject:textView];
    
    if ([limitedTextViews objectForKey:key] != nil)
    {
        [limitedTextViews removeObjectForKey:key];
    }
    
    [limitedTextViews setObject:[NSNumber numberWithInt:maxLength] forKey:key];
}

- (void)textField:(UITextField *)textField limitedToMaxLength:(int)maxLength
{
    if(_form == nil) return;
    
    if(limitedTextField == nil)
    {
        limitedTextField = [NSMutableDictionary dictionary];
    }
    
    NSValue *key = [NSValue valueWithNonretainedObject:textField];
    
    if ([limitedTextField objectForKey:key] != nil)
    {
        [limitedTextField removeObjectForKey:key];
    }
    
    [limitedTextField setObject:[NSNumber numberWithInt:maxLength] forKey:key];
}

- (void)updateForm
{
    if(_form == nil) return;
    
    [self updateFormWithView:_form];
    
    [self defineContentSize];
}

- (void)addUnsuportedView:(UIView *)view
{
    NSMutableArray *array =  [NSMutableArray arrayWithObject:view];
    [array addObjectsFromArray:_unsupportedViews];
    _unsupportedViews = array;
}

- (void)addUnsuportedResizingTextView:(UITextView *)textView
{
    if(textView == nil) return;
    NSMutableArray *array =  [NSMutableArray arrayWithObject:textView];
    [array addObjectsFromArray:_unsupportedTextViews];
    _unsupportedTextViews = array;
}

- (void)updateViewsObserver
{
    if(_form == nil)
    {
        return;
    }
    
    [self removeViewsObservers:_form.subviews];
    [self removeKeyboardObservers];
    
    [self observeViews:_form.subviews];
    [self observeKeyboard];
}






#pragma mark - Private Methods

/**
 *  Call when the form is set
 *  add the gesture to close the keyboard
 *  and define the content size automatically
 */
- (void)setupForm
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touche:)];
    [_form addGestureRecognizer:tap];
    
    _enableObserver = NO;
    _isKeyboardOnScreen = NO;
    _animatingRotation = NO;
    
    [self defineContentSize];
}

/**
 *  Call for the setup to add the good contentSize on the scrollview
 */
- (void)defineContentSize
{
    CGFloat maxHeight = 0.0;
    
    for (UIView *subview in _form.subviews)
    {
        //avoid unsupported views
        //Add scrollbars in unsupported views
        //It may change in iOS future updates (userInteractionEnabled to NO)
        if([self isViewNotOk:subview])
        {
            continue;
        }
        
        //Find the height of the content
        CGFloat bottomPosition = subview.frame.origin.y + subview.frame.size.height;
        if(maxHeight < bottomPosition)
        {
            maxHeight = bottomPosition;
        }
    }
    
    _form.contentSize = CGSizeMake(_form.frame.size.width, maxHeight);
}

/**
 *  This method add observers on views for the key "firstResponder"
 *  so when a new view become firstResponder, we can define a new offset
 * 
 *  This method is recursive to go in subviews
 *
 *  @param views Normally only the form
 */
- (void)observeViews:(NSArray *)views
{
    for (UIView *v in views)
    {
        if([self isViewNotOk:v])
        {
            continue;
        }
        
        if([v isKindOfClass:[UITextField class]] || [v isKindOfClass:[UITextView class]])
        {
            [v addObserver:self forKeyPath:@"firstResponder" options:NSKeyValueObservingOptionNew context:nil];
            if ([v isKindOfClass:[UITextField class]])
            {
                ((UITextField *)v).delegate = self;
            }
            if ([v isKindOfClass:[UITextView class]])
            {
                ((UITextView *)v).delegate = self;
                
                if(textViewHeights == nil)
                {
                    textViewHeights = [NSMutableDictionary dictionary];
                }
                
                NSValue *key = [NSValue valueWithNonretainedObject:((UITextView *)v)];
                if([textViewHeights objectForKey:((UITextView *)v)] == nil)
                {
                    CGFloat h = ((UITextView *)v).frame.size.height;
                    CGFloat h2 = ((UITextView *)v).contentSize.height;
                    [textViewHeights setObject:[NSNumber numberWithFloat:MAX(h, h2)] forKey:key];
                }
            }
        }
        
        if([v.subviews count] > 0) [self observeViews:v.subviews];
    }
}

/**
 *  Observe when the keyboard show and hide
 */
- (void)observeKeyboard
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

/**
 *  Remove the observers on view
 *
 *  This method is recursive
 *
 *  @param views Normally the scrollView
 */
- (void)removeViewsObservers:(NSArray *)views
{
    for (UIView *v in views)
    {
        [self removeViewsObservers:v.subviews];
        if([v respondsToSelector:@selector(isFirstResponder)])
        {
            @try {
                [v removeObserver:self forKeyPath:@"firstResponder"];
            }
            @catch (NSException *exception) {
                
            }
        }
    }
}

/**
 *  Remove the keyboard show and hide observers
 */
- (void)removeKeyboardObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

/**
 *  This method is called when the keyboard will show
 *  So we define the new bottom inset of the scroll view, so the content is not hidden by the keyboard
 *
 *  @param notification Keyboard Notification
 */
- (void)keyboardWillShow:(NSNotification *)notification
{
    if(_isKeyboardOnScreen) return;
    
    CGRect end;
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&end];
    
    CGRect keyboardFrame = [self.view convertRect:end fromView:self.view.window];
    
    double duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    int curve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    _initalBottomInset = _form.contentInset.bottom;
    
    UIEdgeInsets inset = _form.contentInset;
    inset.bottom = _initalBottomInset + keyboardFrame.size.height + _heightAboveKeyboard;
    
    if(!_animatingRotation)
    {
        _isAnimating = YES;
        
        [UIView animateWithDuration:duration delay:0.0 options:curve animations:^{
            _form.contentInset = inset;
        } completion:^(BOOL finished) {
            _isAnimating = NO;
            _enableObserver = YES;
            _isKeyboardOnScreen = YES;
            [self avoidKeyboard];
        }];
    }
    else
    {
        _form.contentInset = inset;
        _enableObserver = YES;
    }
}

/**
 *  This method is called when the keyboard will disapear
 *  So we set back the default bottom inset
 *
 *  @param notification Keyboard Notification
 */
- (void)keyboardWillHide:(NSNotification *)notification
{
    double duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    int curve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    _enableObserver = NO;
    
    UIEdgeInsets inset = _form.contentInset;
    inset.bottom = _initalBottomInset;
    
    if(!_animatingRotation)
    {
        _isAnimating = YES;
        [UIView animateWithDuration:duration delay:0.0 options:curve animations:^{
            _form.contentInset = inset;
        } completion:^(BOOL finished) {
            _isAnimating = NO;
            _isKeyboardOnScreen = NO;
        }];
    }
    else
    {
        _form.contentInset = inset;
    }
}

/**
 *  Change the offset of the scroll view to show the current firstResponder
 */
- (void)avoidKeyboard
{
    UIView *currentView = [self findFirstResponderWithView:_form];
    if(currentView == nil)
    {
        return;
    }
    else if([currentView isKindOfClass:[UITextView class]])
    {
        [self avoidKeyboardForTextViewSelection:(UITextView *)currentView];
    }
    else
    {
        [self avoidKeyboardForView:[self findFirstResponderWithView:_form]];
    }
}

/**
 *  Change the offset of the scroll view to show the view
 *
 *  @param v a view in the scroll view
 */
- (void)avoidKeyboardForView:(UIView *)v
{
    CGFloat visibleSpace = _form.bounds.size.height - _form.contentInset.top - _form.contentInset.bottom;
    
    CGFloat offset = _form.contentOffset.y;
    
    CGRect subviewRect = [v convertRect:v.bounds toView:_form];
    
    if(subviewRect.origin.y - _form.contentOffset.y < _form.contentInset.top)
    {
        offset = subviewRect.origin.y - _form.contentInset.top;
    }
    
    if ((subviewRect.origin.y + subviewRect.size.height) - _form.contentOffset.y > visibleSpace + _form.contentInset.top)
    {
        offset = (subviewRect.origin.y + subviewRect.size.height) - (visibleSpace + _form.contentInset.top);
    }
    
    [_form setContentOffset:CGPointMake(0, offset) animated:YES];
}

/**
 *  Change the offset of the scroll view to show the current selection in a text view
 *
 *  @param v a text view in the scroll view
 */
- (void)avoidKeyboardForTextViewSelection:(UITextView *)v
{
    if(v.selectedTextRange == nil)
    {
        [self avoidKeyboardForView:v];
        return;
    }
    
    CGFloat visibleSpace = _form.bounds.size.height - _form.contentInset.top - _form.contentInset.bottom;
    
    CGFloat offset = _form.contentOffset.y;
    
    CGRect subviewRect = [v convertRect:v.bounds toView:_form];
    
    CGPoint cursorPositionStart = [v caretRectForPosition:v.selectedTextRange.start].origin;
    CGPoint cursorPositionEnd = (!v.selectedTextRange.empty) ? [v caretRectForPosition:v.selectedTextRange.end].origin : cursorPositionStart;
    
    if( (subviewRect.origin.y + cursorPositionStart.y) - _form.contentOffset.y < _form.contentInset.top)
    {
        offset = (subviewRect.origin.y + cursorPositionStart.y) - _form.contentInset.top;
    }
    
    if ((subviewRect.origin.y + cursorPositionEnd.y + v.font.lineHeight) - MAX(0, _form.contentOffset.y) > visibleSpace)
    {
        offset = (subviewRect.origin.y + cursorPositionEnd.y + v.font.lineHeight) - (visibleSpace + _form.contentInset.top);
    }
    
    //If the textview does not resize
    if(_unsupportedTextViews != nil && [_unsupportedTextViews containsObject:v])
    {
        if (offset > subviewRect.origin.y + subviewRect.size.height + _heightAboveKeyboard - (visibleSpace + _form.contentInset.top))
        {
            offset = subviewRect.origin.y + subviewRect.size.height + _heightAboveKeyboard - (visibleSpace + _form.contentInset.top);
        }
    }
    
    [_form setContentOffset:CGPointMake(0, offset) animated:YES];
}

/**
 *  Find the current firstResponder
 *
 *  This method is recursive
 *
 *  @param v Normally the scroll view
 *
 *  @return The current first responder view
 */
- (UIView *)findFirstResponderWithView:(UIView *)v
{
    UIView *firstResponder = nil;
    for (UIView *view in v.subviews)
    {
        if([view respondsToSelector:@selector(isFirstResponder)] && view.isFirstResponder)
        {
            return view;
        }
        else
        {
            firstResponder = [self findFirstResponderWithView:view];
        }
        
        if(firstResponder != nil) return firstResponder;
    }
    
    return firstResponder;
}

/**
 *  This method is called when the scroll view is touched
 *
 *  @param gesture The tap gesture
 */
- (void)touche:(UITapGestureRecognizer *)gesture
{
    if(_isKeyboardOnScreen)[[self findFirstResponderWithView:_form] resignFirstResponder];
}

/**
 *  Go to the next view in the scroll view
 */
- (void)nextView
{
    UIView *nextView = [self findNextViewWithCurrentView:[self findFirstResponderWithView:_form] inForm:_form];
    
    if(nextView == nil)
    {
        [[self findFirstResponderWithView:_form] resignFirstResponder];
    }
    else
    {
        [nextView becomeFirstResponder];
    }
}

/**
 *  Will find the next view in the scroll view directly after the current view
 *
 *  This method is recursive
 *
 *  @param currentView the current view (first responder)
 *  @param form        Normally the scroll
 *
 *  @return The next view
 */
- (UIView *)findNextViewWithCurrentView:(UIView *)currentView inForm:(UIView *)form
{
    //Here the goal is to find the view under the current view (origin.y)
    //The view to find has to be on the same level as currentView
    
    UIView *viewFound = nil;
    
    if([form.subviews containsObject:currentView])
    {
        CGRect currentViewRect = [currentView convertRect:currentView.bounds toView:_form];
        
        for (UIView *view in form.subviews)
        {
            if([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UITextView class]])
            {
                CGRect subviewRect = [view convertRect:view.bounds toView:_form];
                if(subviewRect.origin.y > currentViewRect.origin.y)
                {
                    if(viewFound == nil)
                    {
                        viewFound = view;
                    }
                    else
                    {
                        CGRect foundSubviewRect = [viewFound convertRect:viewFound.bounds toView:_form];
                        
                        if(subviewRect.origin.y < foundSubviewRect.origin.y)
                        {
                            viewFound = view;
                        }
                    }
                }
            }
        }
        
        return viewFound;
    }
    else
    {
        for (UIView *view in form.subviews)
        {
            viewFound = [self findNextViewWithCurrentView:currentView inForm:view];
            
            if(viewFound != nil) return viewFound;
        }
    }
    
    return nil;
}

/**
 *  Will update the height of the text view depending on her content size
 *  and translate all views under
 *
 *  @param textView  The current Text View
 *  @param animation With or without animation
 */
- (void)updateHeightForTextView:(UITextView *)textView withAnimated:(BOOL)animation
{
    if(_unsupportedTextViews != nil && [_unsupportedTextViews containsObject:textView])
    {
        [self avoidKeyboardForTextViewSelection:textView];
        return;
    }
    
    NSValue *key = [NSValue valueWithNonretainedObject:textView];
    
    CGFloat height = textView.frame.size.height;
    
    CGSize s = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, MAXFLOAT)];
    height = ceil(s.height);
    
    height += textView.contentInset.top + textView.contentInset.bottom;
    
    if(height < textView.contentSize.height)
    {
        height = textView.contentSize.height;
    }
    
    if(height < [((NSNumber *)[textViewHeights objectForKey:key]) floatValue])
    {
        height = [((NSNumber *)[textViewHeights objectForKey:key]) floatValue];
    }
    
    CGFloat diff = height - textView.frame.size.height;
    
    if(diff == 0)
    {
        if(animation) [self avoidKeyboardForTextViewSelection:textView];
        return;
    }
    
    [UIView animateWithDuration:(animation ? 0.25 : 0.0)
                     animations:^{
                         
                         //Change the content size of the scrollView
                         CGSize contentSize = _form.contentSize;
                         contentSize.height += diff;
                         _form.contentSize = contentSize;
                         
                         //Change the position of every views under the current view
                         [self moveAllViewsUnderView:textView withDistance:diff inView:_form];
                         
                         //Change the size of the current view
                         CGRect currentFrame = textView.frame;
                         currentFrame.size.height += diff;
                         textView.frame = currentFrame;
                     }
                     completion:^(BOOL finished) {
                         if(animation)[self avoidKeyboardForTextViewSelection:textView];
                     }];
}

/**
 *  Will move all views under the current text view
 *
 *  This method is recursive
 *
 *  @param currentView The current view
 *  @param distance    The Distance to move
 *  @param view        Normally the scroll view
 *
 *  @return Return Yes when all views on the same level as the current view have been moved
 */
- (BOOL)moveAllViewsUnderView:(UIView *)currentView withDistance:(CGFloat)distance inView:(UIView *)view
{
    if([view.subviews containsObject:currentView])
    {
        for (UIView *v in view.subviews)
        {
            if(v.frame.origin.y >= currentView.frame.origin.y + currentView.frame.size.height)
            {
                CGRect currentFrame = v.frame;
                currentFrame.origin.y += distance;
                v.frame = currentFrame;
            }
        }
        
        return YES;
    }
    else
    {
        for (UIView *v in view.subviews)
        {
            if([self moveAllViewsUnderView:currentView withDistance:distance inView:v])
            {
                return YES;
            }
        }
    }
    
    return NO;
}

/**
 *  Update all text views size depending on their contents
 *
 *  @param view Normally the scroll view
 */
- (void)updateFormWithView:(UIView *)view
{
    for (UIView *v in view.subviews)
    {
        if([v isKindOfClass:[UITextView class]])
        {
            [self updateHeightForTextView:(UITextView *)v withAnimated:NO];
        }
        else
        {
            [self updateFormWithView:v];
        }
    }
}

- (BOOL)isViewNotOk:(UIView *)view
{
    return ([view isKindOfClass:[UIImageView class]] && view.isUserInteractionEnabled == NO)
    || (_unsupportedViews != nil && [_unsupportedViews containsObject:view]);
}







#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(!_enableObserver) return;
    
    if([object isKindOfClass:[UIView class]] && ((UIView *)object).isFirstResponder && ![object isEqual:currentSelectedView])
    {
        if([object isKindOfClass:[UITextView class]])
        {
            [self avoidKeyboardForTextViewSelection:object];
        }
        else
        {
            [self avoidKeyboardForView:object];
        }
    }
}






#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Go to the next item in the form
    currentSelectedView = textField;
    [self nextView];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text
{
    //Limit the number of chars in UITextFields
    NSValue *key = [NSValue valueWithNonretainedObject:textField];
    return ([limitedTextField objectForKey:key] == nil) ? YES : textField.text.length + (text.length - range.length) <= [(NSNumber *)[limitedTextField objectForKey:key] intValue];
}




#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    currentSelectedView = textView;
    if (textView.contentSize.height > textView.frame.size.height)
    {
        CGPoint offset = CGPointMake(0, textView.contentSize.height - textView.frame.size.height);
        [textView setContentOffset:offset animated:YES];
    }
    [self updateHeightForTextView:textView withAnimated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    //Limit the number of chars in UITextViews
    NSValue *key = [NSValue valueWithNonretainedObject:textView];
    return ([limitedTextViews objectForKey:key] == nil) ? YES : textView.text.length + (text.length - range.length) <= [(NSNumber *)[limitedTextViews objectForKey:key] intValue];
}





#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    _animatingRotation = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    _animatingRotation = NO;
    if(_isKeyboardOnScreen)
    {
        [self avoidKeyboard];
    }
}






@end
