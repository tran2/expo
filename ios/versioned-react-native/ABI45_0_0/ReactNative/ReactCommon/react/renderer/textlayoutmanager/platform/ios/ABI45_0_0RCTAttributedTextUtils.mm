/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI45_0_0RCTAttributedTextUtils.h"

#include <ABI45_0_0React/ABI45_0_0renderer/core/LayoutableShadowNode.h>
#include <ABI45_0_0React/ABI45_0_0renderer/textlayoutmanager/ABI45_0_0RCTFontProperties.h>
#include <ABI45_0_0React/ABI45_0_0renderer/textlayoutmanager/ABI45_0_0RCTFontUtils.h>
#include <ABI45_0_0React/ABI45_0_0renderer/textlayoutmanager/ABI45_0_0RCTTextPrimitivesConversions.h>
#include <ABI45_0_0React/ABI45_0_0utils/ManagedObjectWrapper.h>

using namespace ABI45_0_0facebook::ABI45_0_0React;

@implementation ABI45_0_0RCTWeakEventEmitterWrapper {
  std::weak_ptr<const EventEmitter> _weakEventEmitter;
}

- (void)setEventEmitter:(SharedEventEmitter)eventEmitter
{
  _weakEventEmitter = eventEmitter;
}

- (SharedEventEmitter)eventEmitter
{
  return _weakEventEmitter.lock();
}

- (void)dealloc
{
  _weakEventEmitter.reset();
}

@end

inline static UIFontWeight ABI45_0_0RCTUIFontWeightFromInteger(NSInteger fontWeight)
{
  assert(fontWeight > 50);
  assert(fontWeight < 950);

  static UIFontWeight weights[] = {
      /* ~100 */ UIFontWeightUltraLight,
      /* ~200 */ UIFontWeightThin,
      /* ~300 */ UIFontWeightLight,
      /* ~400 */ UIFontWeightRegular,
      /* ~500 */ UIFontWeightMedium,
      /* ~600 */ UIFontWeightSemibold,
      /* ~700 */ UIFontWeightBold,
      /* ~800 */ UIFontWeightHeavy,
      /* ~900 */ UIFontWeightBlack};
  // The expression is designed to convert something like 760 or 830 to 7.
  return weights[(fontWeight + 50) / 100 - 1];
}

inline static UIFont *ABI45_0_0RCTEffectiveFontFromTextAttributes(const TextAttributes &textAttributes)
{
  NSString *fontFamily = [NSString stringWithCString:textAttributes.fontFamily.c_str() encoding:NSUTF8StringEncoding];

  ABI45_0_0RCTFontProperties fontProperties;
  fontProperties.family = fontFamily;
  fontProperties.size = textAttributes.fontSize;
  fontProperties.style = textAttributes.fontStyle.hasValue()
      ? ABI45_0_0RCTFontStyleFromFontStyle(textAttributes.fontStyle.value())
      : ABI45_0_0RCTFontStyleUndefined;
  fontProperties.variant = textAttributes.fontVariant.hasValue()
      ? ABI45_0_0RCTFontVariantFromFontVariant(textAttributes.fontVariant.value())
      : ABI45_0_0RCTFontVariantUndefined;
  fontProperties.weight = textAttributes.fontWeight.hasValue()
      ? ABI45_0_0RCTUIFontWeightFromInteger((NSInteger)textAttributes.fontWeight.value())
      : NAN;
  fontProperties.sizeMultiplier = textAttributes.fontSizeMultiplier;

  return ABI45_0_0RCTFontWithFontProperties(fontProperties);
}

inline static CGFloat ABI45_0_0RCTEffectiveFontSizeMultiplierFromTextAttributes(const TextAttributes &textAttributes)
{
  return textAttributes.allowFontScaling.value_or(true) && !isnan(textAttributes.fontSizeMultiplier)
      ? textAttributes.fontSizeMultiplier
      : 1.0;
}

inline static UIColor *ABI45_0_0RCTEffectiveForegroundColorFromTextAttributes(const TextAttributes &textAttributes)
{
  UIColor *effectiveForegroundColor = ABI45_0_0RCTUIColorFromSharedColor(textAttributes.foregroundColor) ?: [UIColor blackColor];

  if (!isnan(textAttributes.opacity)) {
    effectiveForegroundColor = [effectiveForegroundColor
        colorWithAlphaComponent:CGColorGetAlpha(effectiveForegroundColor.CGColor) * textAttributes.opacity];
  }

  return effectiveForegroundColor;
}

inline static UIColor *ABI45_0_0RCTEffectiveBackgroundColorFromTextAttributes(const TextAttributes &textAttributes)
{
  UIColor *effectiveBackgroundColor = ABI45_0_0RCTUIColorFromSharedColor(textAttributes.backgroundColor);

  if (effectiveBackgroundColor && !isnan(textAttributes.opacity)) {
    effectiveBackgroundColor = [effectiveBackgroundColor
        colorWithAlphaComponent:CGColorGetAlpha(effectiveBackgroundColor.CGColor) * textAttributes.opacity];
  }

  return effectiveBackgroundColor ?: [UIColor clearColor];
}

NSDictionary<NSAttributedStringKey, id> *ABI45_0_0RCTNSTextAttributesFromTextAttributes(TextAttributes const &textAttributes)
{
  NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionaryWithCapacity:10];

  // Font
  UIFont *font = ABI45_0_0RCTEffectiveFontFromTextAttributes(textAttributes);
  if (font) {
    attributes[NSFontAttributeName] = font;
  }

  // Colors
  UIColor *effectiveForegroundColor = ABI45_0_0RCTEffectiveForegroundColorFromTextAttributes(textAttributes);

  if (textAttributes.foregroundColor || !isnan(textAttributes.opacity)) {
    attributes[NSForegroundColorAttributeName] = effectiveForegroundColor;
  }

  if (textAttributes.backgroundColor || !isnan(textAttributes.opacity)) {
    attributes[NSBackgroundColorAttributeName] = ABI45_0_0RCTEffectiveBackgroundColorFromTextAttributes(textAttributes);
  }

  // Kerning
  if (!isnan(textAttributes.letterSpacing)) {
    attributes[NSKernAttributeName] = @(textAttributes.letterSpacing);
  }

  // Paragraph Style
  NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
  BOOL isParagraphStyleUsed = NO;
  if (textAttributes.alignment.hasValue()) {
    TextAlignment textAlignment = textAttributes.alignment.value_or(TextAlignment::Natural);
    if (textAttributes.layoutDirection.value_or(LayoutDirection::LeftToRight) == LayoutDirection::RightToLeft) {
      if (textAlignment == TextAlignment::Right) {
        textAlignment = TextAlignment::Left;
      } else if (textAlignment == TextAlignment::Left) {
        textAlignment = TextAlignment::Right;
      }
    }

    paragraphStyle.alignment = ABI45_0_0RCTNSTextAlignmentFromTextAlignment(textAlignment);
    isParagraphStyleUsed = YES;
  }

  if (textAttributes.baseWritingDirection.hasValue()) {
    paragraphStyle.baseWritingDirection =
        ABI45_0_0RCTNSWritingDirectionFromWritingDirection(textAttributes.baseWritingDirection.value());
    isParagraphStyleUsed = YES;
  }

  if (!isnan(textAttributes.lineHeight)) {
    CGFloat lineHeight = textAttributes.lineHeight * ABI45_0_0RCTEffectiveFontSizeMultiplierFromTextAttributes(textAttributes);
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    isParagraphStyleUsed = YES;
  }

  if (isParagraphStyleUsed) {
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;
  }

  // Decoration
  if (textAttributes.textDecorationLineType.value_or(TextDecorationLineType::None) != TextDecorationLineType::None) {
    auto textDecorationLineType = textAttributes.textDecorationLineType.value();

    NSUnderlineStyle style = ABI45_0_0RCTNSUnderlineStyleFromTextDecorationStyle(
        textAttributes.textDecorationStyle.value_or(TextDecorationStyle::Solid));

    UIColor *textDecorationColor = ABI45_0_0RCTUIColorFromSharedColor(textAttributes.textDecorationColor);

    // Underline
    if (textDecorationLineType == TextDecorationLineType::Underline ||
        textDecorationLineType == TextDecorationLineType::UnderlineStrikethrough) {
      attributes[NSUnderlineStyleAttributeName] = @(style);

      if (textDecorationColor) {
        attributes[NSUnderlineColorAttributeName] = textDecorationColor;
      }
    }

    // Strikethrough
    if (textDecorationLineType == TextDecorationLineType::Strikethrough ||
        textDecorationLineType == TextDecorationLineType::UnderlineStrikethrough) {
      attributes[NSStrikethroughStyleAttributeName] = @(style);

      if (textDecorationColor) {
        attributes[NSStrikethroughColorAttributeName] = textDecorationColor;
      }
    }
  }

  // Shadow
  if (textAttributes.textShadowOffset.hasValue()) {
    auto textShadowOffset = textAttributes.textShadowOffset.value();
    NSShadow *shadow = [NSShadow new];
    shadow.shadowOffset = CGSize{textShadowOffset.width, textShadowOffset.height};
    shadow.shadowBlurRadius = textAttributes.textShadowRadius;
    shadow.shadowColor = ABI45_0_0RCTUIColorFromSharedColor(textAttributes.textShadowColor);
    attributes[NSShadowAttributeName] = shadow;
  }

  // Special
  if (textAttributes.isHighlighted) {
    attributes[ABI45_0_0RCTAttributedStringIsHighlightedAttributeName] = @YES;
  }

  if (textAttributes.accessibilityRole.hasValue()) {
    auto accessibilityRole = textAttributes.accessibilityRole.value();
    switch (accessibilityRole) {
      case AccessibilityRole::None:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("none");
        break;
      case AccessibilityRole::Button:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("button");
        break;
      case AccessibilityRole::Link:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("link");
        break;
      case AccessibilityRole::Search:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("search");
        break;
      case AccessibilityRole::Image:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("image");
        break;
      case AccessibilityRole::Imagebutton:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("imagebutton");
        break;
      case AccessibilityRole::Keyboardkey:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("keyboardkey");
        break;
      case AccessibilityRole::Text:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("text");
        break;
      case AccessibilityRole::Adjustable:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("adjustable");
        break;
      case AccessibilityRole::Summary:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("summary");
        break;
      case AccessibilityRole::Header:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("header");
        break;
      case AccessibilityRole::Alert:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("alert");
        break;
      case AccessibilityRole::Checkbox:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("checkbox");
        break;
      case AccessibilityRole::Combobox:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("combobox");
        break;
      case AccessibilityRole::Menu:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("menu");
        break;
      case AccessibilityRole::Menubar:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("menubar");
        break;
      case AccessibilityRole::Menuitem:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("menuitem");
        break;
      case AccessibilityRole::Progressbar:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("progressbar");
        break;
      case AccessibilityRole::Radio:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("radio");
        break;
      case AccessibilityRole::Radiogroup:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("radiogroup");
        break;
      case AccessibilityRole::Scrollbar:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("scrollbar");
        break;
      case AccessibilityRole::Spinbutton:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("spinbutton");
        break;
      case AccessibilityRole::Switch:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("switch");
        break;
      case AccessibilityRole::Tab:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("tab");
        break;
      case AccessibilityRole::TabBar:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("tabbar");
        break;
      case AccessibilityRole::Tablist:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("tablist");
        break;
      case AccessibilityRole::Timer:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("timer");
        break;
      case AccessibilityRole::Toolbar:
        attributes[ABI45_0_0RCTTextAttributesAccessibilityRoleAttributeName] = @("toolbar");
        break;
    };
  }

  return [attributes copy];
}

NSAttributedString *ABI45_0_0RCTNSAttributedStringFromAttributedString(const AttributedString &attributedString)
{
  static UIImage *placeholderImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    placeholderImage = [UIImage new];
  });

  NSMutableAttributedString *nsAttributedString = [NSMutableAttributedString new];

  [nsAttributedString beginEditing];

  for (auto fragment : attributedString.getFragments()) {
    NSMutableAttributedString *nsAttributedStringFragment;

    if (fragment.isAttachment()) {
      auto layoutMetrics = fragment.parentShadowView.layoutMetrics;
      CGRect bounds = {
          .origin = {.x = layoutMetrics.frame.origin.x, .y = layoutMetrics.frame.origin.y},
          .size = {.width = layoutMetrics.frame.size.width, .height = layoutMetrics.frame.size.height}};

      NSTextAttachment *attachment = [NSTextAttachment new];
      attachment.image = placeholderImage;
      attachment.bounds = bounds;

      nsAttributedStringFragment = [[NSMutableAttributedString attributedStringWithAttachment:attachment] mutableCopy];
    } else {
      NSString *string = [NSString stringWithCString:fragment.string.c_str() encoding:NSUTF8StringEncoding];

      if (fragment.textAttributes.textTransform.hasValue()) {
        auto textTransform = fragment.textAttributes.textTransform.value();
        string = ABI45_0_0RCTNSStringFromStringApplyingTextTransform(string, textTransform);
      }

      nsAttributedStringFragment = [[NSMutableAttributedString alloc]
          initWithString:string
              attributes:ABI45_0_0RCTNSTextAttributesFromTextAttributes(fragment.textAttributes)];
    }

    if (fragment.parentShadowView.componentHandle) {
      ABI45_0_0RCTWeakEventEmitterWrapper *eventEmitterWrapper = [ABI45_0_0RCTWeakEventEmitterWrapper new];
      eventEmitterWrapper.eventEmitter = fragment.parentShadowView.eventEmitter;

      NSDictionary<NSAttributedStringKey, id> *additionalTextAttributes =
          @{ABI45_0_0RCTAttributedStringEventEmitterKey : eventEmitterWrapper};

      [nsAttributedStringFragment addAttributes:additionalTextAttributes
                                          range:NSMakeRange(0, nsAttributedStringFragment.length)];
    }

    [nsAttributedString appendAttributedString:nsAttributedStringFragment];
  }

  [nsAttributedString endEditing];

  return nsAttributedString;
}

NSAttributedString *ABI45_0_0RCTNSAttributedStringFromAttributedStringBox(AttributedStringBox const &attributedStringBox)
{
  switch (attributedStringBox.getMode()) {
    case AttributedStringBox::Mode::Value:
      return ABI45_0_0RCTNSAttributedStringFromAttributedString(attributedStringBox.getValue());
    case AttributedStringBox::Mode::OpaquePointer:
      return (NSAttributedString *)unwrapManagedObject(attributedStringBox.getOpaquePointer());
  }
}

AttributedStringBox ABI45_0_0RCTAttributedStringBoxFromNSAttributedString(NSAttributedString *nsAttributedString)
{
  return nsAttributedString.length ? AttributedStringBox{wrapManagedObject(nsAttributedString)} : AttributedStringBox{};
}

NSString *ABI45_0_0RCTNSStringFromStringApplyingTextTransform(NSString *string, TextTransform textTransform)
{
  switch (textTransform) {
    case TextTransform::Uppercase:
      return [string uppercaseString];
    case TextTransform::Lowercase:
      return [string lowercaseString];
    case TextTransform::Capitalize:
      return [string capitalizedString];
    default:
      return string;
  }
}
