//
//  LDNoAutoLayoutViewController.m
//  LDScrollViewForm
//
//  Created by Damien Legrand on 29/11/2013.
//  Copyright (c) 2013 Damien Legrand. All rights reserved.
//

#import "LDNoAutoLayoutViewController.h"

@interface LDNoAutoLayoutViewController ()

@end

@implementation LDNoAutoLayoutViewController

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
    // Do any additional setup after loading the view from its nib.
    self.title = @"No Auto Layout";
    [self setForm:self.scrollView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
