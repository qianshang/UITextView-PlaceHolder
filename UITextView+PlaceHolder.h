//
//  UITextView+PlaceHolder.h
//  USKID
//
//  Created by mac on 2017/2/10.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (PlaceHolder)

@property (nonatomic, copy) IBInspectable NSString *placeholder;
@property (nonatomic, copy) IBInspectable UIColor *placeholderTextColor;

@end
