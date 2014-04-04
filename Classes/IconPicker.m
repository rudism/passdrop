//
//  IconPicker.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IconPicker.h"


@implementation IconPicker

@synthesize delegate;
@synthesize scrollView;

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Choose Icon";
    }
    return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotate{
    return YES;
}

- (void) drawIcons {
    for(int i = 0; i < 69; i++){
        CGRect rect = CGRectMake(0, 0, 37, 37);
        UIButton *icon = [[UIButton alloc] initWithFrame:rect];
        [icon addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        icon.tag = i;
        [icon setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.png", i]] forState:UIControlStateNormal];
        [scrollView addSubview:icon];
        [icon release];
    }
    [self positionIconsForOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
}

- (void) positionIconsForOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    int iconsPerRow;
    bool portrait = UIInterfaceOrientationIsPortrait(orientation) || [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    if(portrait){
        [scrollView setContentSize:CGSizeMake(320, 600)];
        iconsPerRow = 6;
    } else {
        [scrollView setContentSize:CGSizeMake(480, 400)];
        iconsPerRow = 9;
    }
    if(duration > 0){
        [UIView beginAnimations:nil context:NULL];
    }
    for(int i = 0; i < 69; i++){
        int col = i % iconsPerRow;
        int row = floor(i / iconsPerRow);
        
        UIButton *icon = (UIButton*)[scrollView viewWithTag:i];
        CGRect rect = CGRectMake(20 + (col * 48), 17 + (row * 48), 37, 37);
        [icon setFrame:rect];
    }
    if(duration > 0){
        [UIView setAnimationDuration:duration];
        [UIView commitAnimations];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self positionIconsForOrientation:toInterfaceOrientation duration:duration];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelIconPicker)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    [self drawIcons];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Actions

- (void)buttonPressed:(id)sender {
    [delegate iconSelected:[[(UIButton*)sender imageView] image] withId:((UIButton*)sender).tag];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)cancelIconPicker {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [super dealloc];
}


@end
