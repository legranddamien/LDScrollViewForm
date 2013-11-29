//
//  LDViewController.m
//  LDScrollViewForm
//
//  Created by Damien Legrand on 27/11/2013.
//  Copyright (c) 2013 Damien Legrand. All rights reserved.
//

#import "LDViewController.h"

#import "LDNoAutoLayoutViewController.h"

@interface LDViewController ()

@end

@implementation LDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = @"Auto Layout";
    [self setForm:self.scrollView];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"No Autolayout" style:UIBarButtonItemStylePlain target:self action:@selector(noautolayout)];
    self.navigationItem.rightBarButtonItem = rightButton;
}

- (void)noautolayout
{
    LDNoAutoLayoutViewController *vc = [[LDNoAutoLayoutViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
