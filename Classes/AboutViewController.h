//
//  AboutViewController.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController {
    IBOutlet UIButton *twitter;
    IBOutlet UIButton *homepage;
}

@property (nonatomic, retain) UIButton *twitter;
@property (nonatomic, retain) UIButton *homepage;

-(IBAction)handleEvent:(id)sender;

@end
