//
//  SyncButtonView.h
//  PassDrop
//
//  Created by Rudis Muiznieks on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define kPadding 10

#import <UIKit/UIKit.h>

@protocol SyncButtonViewDelegate;

@interface SyncButtonView : UIView {
    UILabel* titleLabel;
    id<SyncButtonViewDelegate> delegate;
}

@property (retain, nonatomic) id<SyncButtonViewDelegate> delegate;

- (id)initWithTitle:(NSString*)title inView:(UIView*)view;
- (void)show;
- (void)dismissAnimated:(BOOL)animated;
- (CGRect)beveledBoxFrame;

@end

@protocol SyncButtonViewDelegate <NSObject>

- (void)syncButtonClicked;

@end