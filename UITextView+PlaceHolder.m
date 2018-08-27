//
//  UITextView+PlaceHolder.m
//  USKID
//
//  Created by mac on 2017/2/10.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "UITextView+PlaceHolder.h"
#import <objc/runtime.h>

static const void *kPlaceholderKey      = &kPlaceholderKey;
static const void *kPlaceholderLabelKey = &kPlaceholderLabelKey;
static const void *kPlaceholderFrameKey = &kPlaceholderFrameKey;

static inline BOOL isEmptyString(NSString *originString) {
    if (originString == nil ||
        [originString isEqual:[NSNull null]]) {
        return YES;
    }
    if ([originString isKindOfClass:[NSString class]]) {
        return [originString length] <= 0 || [originString isEqualToString:@"(null)"];
    }
    return YES;
}

@implementation UITextView (PlaceHolder)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self jr_swizzleMethod:@selector(initWithFrame:) withMethod:@selector(ph_initWithFrame:) error:nil];
        [self jr_swizzleMethod:@selector(awakeFromNib) withMethod:@selector(ph_awakeFromNib) error:nil];
        [self jr_swizzleMethod:@selector(layoutSubviews) withMethod:@selector(ph_layoutSubviews) error:nil];
        [self jr_swizzleMethod:@selector(setText:) withMethod:@selector(ph_setText:) error:nil];
        [self jr_swizzleMethod:@selector(setFont:) withMethod:@selector(ph_setFont:) error:nil];
        [self jr_swizzleMethod:NSSelectorFromString(@"dealloc") withMethod:@selector(ph_dealloc) error:nil];
        [self jr_swizzleMethod:@selector(setTextContainerInset:) withMethod:@selector(ph_setTextContainerInset:) error:nil];
    });
}

+ (BOOL)jr_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_
{
    Method origMethod = class_getInstanceMethod(self, origSel_);
    if (!origMethod) {
        return NO;
    }
    Method altMethod = class_getInstanceMethod(self, altSel_);
    if (!altMethod) {
        return NO;
    }
    
    class_addMethod(self,
                    origSel_,
                    class_getMethodImplementation(self, origSel_),
                    method_getTypeEncoding(origMethod));
    class_addMethod(self,
                    altSel_,
                    class_getMethodImplementation(self, altSel_),
                    method_getTypeEncoding(altMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(self, origSel_), class_getInstanceMethod(self, altSel_));
    
    return YES;
}

- (void)ph_dealloc {
    [self ph_dealloc];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
}

- (instancetype)ph_initWithFrame:(CGRect)frame {
    id __self = [self ph_initWithFrame:frame];
    
    [__self instance];
    
    return __self;
}

- (void)ph_awakeFromNib {
    [self ph_awakeFromNib];
    
    [self instance];
}

- (void)ph_layoutSubviews {
    [self ph_layoutSubviews];
    
    [self resetPlaceHolderLabelFrame];
}

- (void)instance {
    self.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.textContainer.lineFragmentPadding = 0.0f;
    self.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
    self.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textViewTextChange)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
}

- (void)resetPlaceHolderLabelFrame {
    [self updatePlaceholderIfNeeded];
    
    if ([self placeHolderLabel].isHidden) {
        return;
    }
    
    if (!isEmptyString([self placeHolderLabel].text) &&
        [[self placeHolderLabel].text isEqualToString:self.placeholder]) {
        
        NSString *frameString = objc_getAssociatedObject(self, &kPlaceholderFrameKey);
        [[self placeHolderLabel] setFrame:CGRectFromString(frameString)];
        
        return;
    }
    
    [[self placeHolderLabel] setText:self.placeholder];
    
    CGFloat left   = self.textContainerInset.left;
    CGFloat top    = self.textContainerInset.top;
    CGFloat right  = self.textContainerInset.right;
    CGFloat bottom = self.textContainerInset.bottom;
    
    CGFloat x = left;
    CGFloat y = top;
    CGFloat w = CGRectGetWidth(self.bounds) - left - right;
    CGFloat h = [self.placeholder boundingRectWithSize:CGSizeMake(w, CGRectGetHeight(self.bounds) - top - bottom)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{ NSFontAttributeName: self.font }
                                               context:nil].size.height;
    h = MAX(h, [self.font lineHeight]);
    CGRect frame = CGRectMake(x, y, w, h);
    objc_setAssociatedObject(self, &kPlaceholderFrameKey, NSStringFromCGRect(frame), OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [[self placeHolderLabel] setFrame:frame];
}


- (void)textViewTextChange {
    [self updatePlaceholderIfNeeded];
}

- (void)updatePlaceholderIfNeeded {
    BOOL isVisible = isEmptyString(self.text) && !isEmptyString(self.placeholder);
    [[self placeHolderLabel] setHidden:!isVisible];
}



- (void)setPlaceholder:(NSString *)placeholder {
    objc_setAssociatedObject(self, kPlaceholderKey, placeholder, OBJC_ASSOCIATION_COPY);
}

- (NSString *)placeholder {
    return objc_getAssociatedObject(self, kPlaceholderKey);
}

- (void)ph_setText:(NSString *)text {
    [self ph_setText:text];
    
    [self updatePlaceholderIfNeeded];
}

- (void)ph_setFont:(UIFont *)font {
    [self ph_setFont:font];
    
    [[self placeHolderLabel] setFont:font];
}

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor {
    [[self placeHolderLabel] setTextColor:placeholderTextColor];
}

- (UIColor *)placeholderTextColor {
    return [[self placeHolderLabel] textColor];
}

- (void)ph_setTextContainerInset:(UIEdgeInsets)insert {
    [self ph_setTextContainerInset:insert];
    
    [self resetPlaceHolderLabelFrame];
}

- (UILabel *)placeHolderLabel {
    UILabel *label = objc_getAssociatedObject(self, kPlaceholderLabelKey);
    if (!label) {
        label = [UILabel new];
        label.textColor = [UIColor colorWithRed:203 / 255.0 green:203 / 255.0 blue:220 / 255.0 alpha:1];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        [self insertSubview:label atIndex:0];
        
        objc_setAssociatedObject(self, kPlaceholderLabelKey, label, OBJC_ASSOCIATION_RETAIN);
    }
    return label;
}

@end
