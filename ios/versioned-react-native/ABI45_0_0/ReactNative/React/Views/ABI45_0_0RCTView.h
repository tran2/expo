/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <ABI45_0_0React/ABI45_0_0RCTBorderStyle.h>
#import <ABI45_0_0React/ABI45_0_0RCTComponent.h>
#import <ABI45_0_0React/ABI45_0_0RCTPointerEvents.h>

extern const UIAccessibilityTraits SwitchAccessibilityTrait;

@protocol ABI45_0_0RCTAutoInsetsProtocol;

@interface ABI45_0_0RCTView : UIView

/**
 * Accessibility event handlers
 */
@property (nonatomic, copy) ABI45_0_0RCTDirectEventBlock onAccessibilityAction;
@property (nonatomic, copy) ABI45_0_0RCTDirectEventBlock onAccessibilityTap;
@property (nonatomic, copy) ABI45_0_0RCTDirectEventBlock onMagicTap;
@property (nonatomic, copy) ABI45_0_0RCTDirectEventBlock onAccessibilityEscape;

/**
 * Used to control how touch events are processed.
 */
@property (nonatomic, assign) ABI45_0_0RCTPointerEvents pointerEvents;

+ (void)autoAdjustInsetsForView:(UIView<ABI45_0_0RCTAutoInsetsProtocol> *)parentView
                 withScrollView:(UIScrollView *)scrollView
                   updateOffset:(BOOL)updateOffset;

/**
 * Layout direction of the view.
 * This is inherited from UIView+React, but we override it here
 * to improve performance and make subclassing/overriding possible/easier.
 */
@property (nonatomic, assign) UIUserInterfaceLayoutDirection ABI45_0_0ReactLayoutDirection;

/**
 * This is an optimization used to improve performance
 * for large scrolling views with many subviews, such as a
 * list or table. If set to YES, any clipped subviews will
 * be removed from the view hierarchy whenever -updateClippedSubviews
 * is called. This would typically be triggered by a scroll event
 */
@property (nonatomic, assign) BOOL removeClippedSubviews;

/**
 * Hide subviews if they are outside the view bounds.
 * This is an optimisation used predominantly with RKScrollViews
 * but it is applied recursively to all subviews that have
 * removeClippedSubviews set to YES
 */
- (void)updateClippedSubviews;

/**
 * Border radii.
 */
@property (nonatomic, assign) CGFloat borderRadius;
@property (nonatomic, assign) CGFloat borderTopLeftRadius;
@property (nonatomic, assign) CGFloat borderTopRightRadius;
@property (nonatomic, assign) CGFloat borderTopStartRadius;
@property (nonatomic, assign) CGFloat borderTopEndRadius;
@property (nonatomic, assign) CGFloat borderBottomLeftRadius;
@property (nonatomic, assign) CGFloat borderBottomRightRadius;
@property (nonatomic, assign) CGFloat borderBottomStartRadius;
@property (nonatomic, assign) CGFloat borderBottomEndRadius;

/**
 * Border colors (actually retained).
 */
@property (nonatomic, strong) UIColor *borderTopColor;
@property (nonatomic, strong) UIColor *borderRightColor;
@property (nonatomic, strong) UIColor *borderBottomColor;
@property (nonatomic, strong) UIColor *borderLeftColor;
@property (nonatomic, strong) UIColor *borderStartColor;
@property (nonatomic, strong) UIColor *borderEndColor;
@property (nonatomic, strong) UIColor *borderColor;

/**
 * Border widths.
 */
@property (nonatomic, assign) CGFloat borderTopWidth;
@property (nonatomic, assign) CGFloat borderRightWidth;
@property (nonatomic, assign) CGFloat borderBottomWidth;
@property (nonatomic, assign) CGFloat borderLeftWidth;
@property (nonatomic, assign) CGFloat borderStartWidth;
@property (nonatomic, assign) CGFloat borderEndWidth;
@property (nonatomic, assign) CGFloat borderWidth;

/**
 * Border styles.
 */
@property (nonatomic, assign) ABI45_0_0RCTBorderStyle borderStyle;

/**
 *  Insets used when hit testing inside this view.
 */
@property (nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;

@end
