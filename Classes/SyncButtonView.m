//
//  SyncButtonView.m
//  PassDrop
//
//  Created by Rudis Muiznieks on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SyncButtonView.h"

@implementation SyncButtonView

@synthesize delegate;

- (id)init {
    return [self initWithTitle:nil inView:nil];
}

- (id)initWithTitle:(NSString*)theTitle inView:(UIView*)view {
    CGRect frame = view.frame;
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        titleLabel = [UILabel new];
        titleLabel.text = theTitle;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = UITextAlignmentCenter;
        [self addSubview:titleLabel];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGRect contentFrame = [self beveledBoxFrame];
    contentFrame.origin.x += kPadding;
    contentFrame.origin.y += kPadding;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat fillColor[] = { 0, 0, 0, 128.0/255 };
    CGContextSetFillColor(context, fillColor);
    CGFloat radius = 6;
    CGContextMoveToPoint(context, contentFrame.origin.x + radius, contentFrame.origin.y);
    CGContextAddArcToPoint(context, 
                           CGRectGetMaxX(contentFrame), contentFrame.origin.y, 
                           CGRectGetMaxX(contentFrame), CGRectGetMaxY(contentFrame), radius);
    CGContextAddArcToPoint(context, 
                           CGRectGetMaxX(contentFrame), CGRectGetMaxY(contentFrame), 
                           contentFrame.origin.x, CGRectGetMaxY(contentFrame), radius);
    CGContextAddArcToPoint(context, 
                           contentFrame.origin.x, CGRectGetMaxY(contentFrame), 
                           contentFrame.origin.x, contentFrame.origin.y, radius);
    CGContextAddArcToPoint(context, 
                           contentFrame.origin.x, contentFrame.origin.y, 
                           CGRectGetMaxX(contentFrame), contentFrame.origin.y, radius);
    CGContextClosePath(context);
    CGContextFillPath(context);
}



- (void)layoutSubviews {
    CGRect contentFrame = [self beveledBoxFrame];
    CGFloat titleLeading = titleLabel.font.leading;
    CGRect titleFrame = CGRectMake(
                                   contentFrame.origin.x + kPadding, 
                                   CGRectGetMaxY(contentFrame) - titleLeading, 
                                   contentFrame.size.width, titleLeading);
    titleLabel.frame = titleFrame;
}

- (void)dealloc {
    [titleLabel release];
    [super dealloc];
}

- (void)show {
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    self.frame = [self beveledBoxFrame];
    [window addSubview:self];
}

- (void)finishDismiss {
    [self removeFromSuperview];
}

- (void)dismissAnimated:(BOOL)animated {
    if (!animated) {
        [self finishDismiss];
    } else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.8];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(finishDismiss)];
        
        self.alpha = 0;
        
        [UIView commitAnimations];
    }
}

- (CGRect)beveledBoxFrame {
    CGSize contentSize = self.bounds.size;
    CGSize boxSize = CGSizeMake(80, 40);
    return CGRectMake(
                      floor(contentSize.width - boxSize.width - kPadding),
                      floor(contentSize.height - boxSize.height - kPadding),
                      boxSize.width, boxSize.height);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [delegate syncButtonClicked];
}

@end
