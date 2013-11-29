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
- (BOOL)moveAllViewUnderView:(UIView *)currentView withDistance:(CGFloat)distance inView:(UIView *)view;

@end

@implementation LDScrollViewFormController

#pragma mark - Controller Life

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
    if(_form != nil)
    {
        [self observeViews:_form.subviews];
        [self observeKeyboard];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    if(_form != nil)
    {
        [self removeViewsObservers:_form.subviews];
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

#pragma mark - Private Methods

- (void)setupForm
{
    _form.delegate = self;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touche:)];
    [_form addGestureRecognizer:tap];
    
    _enableObserver = NO;
    _isKeyboardOnScreen = NO;
    _animatingRotation = NO;
    
    [self defineContentSize];
}

- (void)defineContentSize
{
    CGFloat maxHeight = 0.0;
    
    for (UIView *subview in _form.subviews)
    {
        //Find the height of the content
        CGFloat bottomPosition = subview.frame.origin.y + subview.frame.size.height;
        if(maxHeight < bottomPosition)
        {
            maxHeight = bottomPosition;
        }
    }
    
    _form.contentSize = CGSizeMake(_form.frame.size.width, maxHeight);
}

- (void)observeViews:(NSArray *)views
{
    for (UIView *v in views)
    {
        if([v respondsToSelector:@selector(isFirstResponder)])
        {
            [v addObserver:self forKeyPath:@"firstResponder" options:NSKeyValueObservingOptionNew context:nil];
            if ([v isKindOfClass:[UITextField class]])
            {
                ((UITextField *)v).delegate = self;
            }
            if ([v isKindOfClass:[UITextView class]])
            {
                ((UITextView *)v).delegate = self;
            }
        }
        
        [self observeViews:v.subviews];
    }
}

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

- (void)removeKeyboardObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
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
        
        [UIView animateKeyframesWithDuration:duration delay:0.0 options:curve animations:^{
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
        [UIView animateKeyframesWithDuration:duration delay:0.0 options:curve animations:^{
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

- (void)avoidKeyboardForTextViewSelection:(UITextView *)v
{
    CGFloat visibleSpace = _form.bounds.size.height - _form.contentInset.top - _form.contentInset.bottom;
    
    CGFloat offset = _form.contentOffset.y;
    
    CGRect subviewRect = [v convertRect:v.bounds toView:_form];
    
    CGPoint cursorPositionStart = [v caretRectForPosition:v.selectedTextRange.start].origin;
    CGPoint cursorPositionEnd = (!v.selectedTextRange.empty) ? [v caretRectForPosition:v.selectedTextRange.end].origin : cursorPositionStart;
    
    if( (subviewRect.origin.y + cursorPositionStart.y) - _form.contentOffset.y < _form.contentInset.top)
    {
        offset = (subviewRect.origin.y + cursorPositionStart.y) - _form.contentInset.top;
    }
    
    if ((subviewRect.origin.y + cursorPositionEnd.y + v.font.lineHeight) - _form.contentOffset.y > visibleSpace)
    {
        offset = (subviewRect.origin.y + cursorPositionEnd.y + v.font.lineHeight) - (visibleSpace + _form.contentInset.top);
    }
    
    [_form setContentOffset:CGPointMake(0, offset) animated:YES];
}

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

- (void)touche:(UITapGestureRecognizer *)gesture
{
    if(_isKeyboardOnScreen)[[self findFirstResponderWithView:_form] resignFirstResponder];
}

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

- (void)updateHeightForTextView:(UITextView *)textView withAnimated:(BOOL)animation
{
    if(textViewHeights == nil)
    {
        textViewHeights = [NSMutableDictionary dictionary];
    }
    
    NSValue *key = [NSValue valueWithNonretainedObject:textView];
    if([textViewHeights objectForKey:textView] == nil)
    {
        [textViewHeights setObject:[NSNumber numberWithFloat:textView.frame.size.height] forKey:key];
    }
    
    CGFloat height = textView.contentSize.height;
    if(height < [((NSNumber *)[textViewHeights objectForKey:key]) floatValue])
    {
        height = [((NSNumber *)[textViewHeights objectForKey:key]) floatValue];
    }
    
    CGFloat diff = height - textView.frame.size.height;
    
    if(diff == 0)
    {
        [self avoidKeyboardForTextViewSelection:textView];
        return;
    }
    
    [UIView animateWithDuration:(animation ? 0.25 : 0.0)
                     animations:^{
                         
                         //Change the content size of the scrollView
                         CGSize contentSize = _form.contentSize;
                         contentSize.height += diff;
                         _form.contentSize = contentSize;
                         
                         //Change the position of every views under the current view
                         [self moveAllViewUnderView:textView withDistance:diff inView:_form];
                         
                         //Change the size of the current view
                         CGRect currentFrame = textView.frame;
                         currentFrame.size.height += diff;
                         textView.frame = currentFrame;
                     }
                     completion:^(BOOL finished) {
                         [self avoidKeyboardForTextViewSelection:textView];
                     }];
}

- (BOOL)moveAllViewUnderView:(UIView *)currentView withDistance:(CGFloat)distance inView:(UIView *)view
{
    if([view.subviews containsObject:currentView])
    {
        for (UIView *v in view.subviews)
        {
            if(v.frame.origin.y > currentView.frame.origin.y + currentView.frame.size.height)
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
            if([self moveAllViewUnderView:currentView withDistance:distance inView:v])
            {
                return YES;
            }
        }
    }
    
    return NO;
}

#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(!_enableObserver) return;
    
    if([object isKindOfClass:[UIView class]] && ((UIView *)object).isFirstResponder)
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
    [self nextView];
    return NO;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    [self updateHeightForTextView:textView withAnimated:YES];
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
