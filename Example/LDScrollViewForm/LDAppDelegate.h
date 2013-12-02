//
//  LDAppDelegate.h
//  LDScrollViewForm
//
//  Created by Damien Legrand on 27/11/2013.
//  Copyright (c) 2013 Damien Legrand. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LDNoAutoLayoutViewController.h"

@interface LDAppDelegate : UIResponder <UIApplicationDelegate> {
    LDNoAutoLayoutViewController *vc;
}

@property (strong, nonatomic) UIWindow *window;

@end
