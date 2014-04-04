//
//  IconPicker.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IconPickerDelegate;

@interface IconPicker : UIViewController {
    id<IconPickerDelegate> delegate;
    UIScrollView *scrollView;
}

@property (assign, nonatomic) id<IconPickerDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)buttonPressed:(id)sender;
- (void)cancelIconPicker;

@end

@protocol IconPickerDelegate<NSObject>

- (void)iconSelected:(UIImage*)icon withId:(uint32_t)iconId;

@end