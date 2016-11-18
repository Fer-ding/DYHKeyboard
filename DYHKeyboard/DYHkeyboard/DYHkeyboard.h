//
//  DYHkeyboard.h
//  DYHKeyboard
//
//  Created by YueHui on 16/11/16.
//  Copyright © 2016年 LeapDing. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,DYHkeyboardType) {
    DYHKeyboardTypeDefault,
    DYHkeyboardTypeNumberPad = DYHKeyboardTypeDefault,//random number 0 - 9
    DYHKeyboardTypeASCIICapable, // Displays a keyboard which can enter ASCII characters
    DYHkeyboardTypeSymbol//符号
};
@interface DYHkeyboard : UIView

+ (nonnull instancetype)keyboardWithType:(DYHkeyboardType)type;

/*
 *  @brief such as UITextField,UITextView,UISearchBar
 */
@property (nonatomic, nullable, strong) UIView *inputSource;

/*
 *  @brif custom headerView
 */
@property (nonatomic, nullable, strong) UIView *inputAccessoryView;

@end
