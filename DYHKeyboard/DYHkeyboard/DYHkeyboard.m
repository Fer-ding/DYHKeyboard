//
//  DYHkeyboard.m
//  DYHKeyboard
//
//  Created by YueHui on 16/11/16.
//  Copyright © 2016年 LeapDing. All rights reserved.
//

#import "DYHkeyboard.h"

#define DYHKBH                           216.0
#define DYHCHAR_CORNER                   8
#define DYHKBFontSize                    18
#define DYHKBFont(s)                        [UIFont systemFontOfSize:s]
#define DYHFormat(format, ...)           [NSString stringWithFormat:format, ##__VA_ARGS__]
#ifndef DYHSCREEN_WIDTH
#define DYHSCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#endif

// 颜色
#define DYHColorFromRGB(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]

#define DYHColorFromHex(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 \
alpha:1.0]

#define Characters @[@"q",@"w",@"e",@"r",@"t",@"y",@"u",@"i",@"o",@"p",@"a",@"s",@"d",@"f",@"g",@"h",@"j",@"k",@"l",@"z",@"x",@"c",@"v",@"b",@"n",@"m"]
#define Symbols  @[@"!",@"@",@"#",@"$",@"%",@"^",@"&",@"*",@"(",@")",@"'",@"\"",@"=",@"_",@":",@";",@"?",@"~",@"|",@"•",@"+",@"-",@"\\",@"/",@"[",@"]",@"{",@"}",@",",@".",@"<",@">",@"€",@"£",@"¥"]

#pragma mark - UIImage category

@interface UIImage (PureColor)
/*
 *  //纯色转化图片
 */
+ (UIImage *)imageWithPureColor:(UIColor *)pureColor;

@end

@implementation UIImage (PureColor)

+ (UIImage *)imageWithPureColor:(UIColor *)pureColor
{
    CGSize imageSize = CGSizeMake(2.0, 2.0);
    UIGraphicsBeginImageContextWithOptions(imageSize, 0, [UIScreen mainScreen].scale);
    [pureColor set];
    UIRectFill(CGRectMake(0, 0, imageSize.width, imageSize.height));
    UIImage *pureImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return pureImage;
}

@end

#pragma mark - Custom Char Button

@interface DYHCharButton : UIButton

@property (nonatomic, assign) BOOL isShift;
@property (nonatomic, copy) NSString *chars;

- (void)shift:(BOOL)shift;

- (void)updateChar:(nullable NSString *)chars;

@end

@implementation DYHCharButton

- (void)updateChar:(nullable NSString *)chars {
    if (chars.length > 0) {
        self.chars = [chars copy];
        [self updateTitleState];
    }
}

- (void)shift:(BOOL)shift {
    if (shift == self.isShift) {
        return;
    }
    self.isShift = shift;
    [self updateTitleState];
}

- (void)updateTitleState {
    NSString *tmp = self.isShift ? [self.chars uppercaseString]:[self.chars lowercaseString];
    if ([[NSThread currentThread] isMainThread]) {
        [self setTitle:tmp forState:UIControlStateNormal];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setTitle:tmp forState:UIControlStateNormal];
        });
    }
}


@end


#pragma mark - DYHkeyboard

@interface DYHkeyboard ()

@property (nonatomic, strong) UIView *inputView;
@property (nonatomic, strong) UIView *inputAccessoryBGView;

@property (nonatomic, assign) DYHkeyboardType keyboardType;

@property (nonatomic, assign) BOOL shiftEnable;

@end

@implementation DYHkeyboard

+ (instancetype)keyboardWithType:(DYHkeyboardType)type {
    return [[DYHkeyboard alloc] initWithFrame:CGRectZero keyboardType:type];
}

- (id)initWithFrame:(CGRect)frame keyboardType:(DYHkeyboardType)type {
    self = [super initWithFrame:frame];
    if (self) {
        self.keyboardType = type;
        [self initSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.keyboardType = DYHKeyboardTypeDefault;
        [self initSetup];
    }
    return self;
}

- (void)initSetup {
    
    UIColor *norColor = DYHColorFromHex(0x2c3c4c);
    self.backgroundColor = norColor;
    
    UIView *tempInputAccessoryBGView = [[UIView alloc] init];
    tempInputAccessoryBGView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:tempInputAccessoryBGView];
    self.inputAccessoryBGView = tempInputAccessoryBGView;
    
    UIView *tempInputView = [[UIView alloc] init];
    tempInputView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:tempInputView];
    self.inputView = tempInputView;
    
    NSArray *hVFL = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[inputView(width)]" options:0 metrics:@{@"width":@(DYHSCREEN_WIDTH)} views:@{@"inputView":self.inputView}];
    
    NSArray *vVFL = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[inputAccessoryBGView]-[inputView(inputViewHeight)]|" options:NSLayoutFormatAlignAllRight | NSLayoutFormatAlignAllLeft metrics:@{@"inputViewHeight":@(DYHKBH)} views:@{@"inputView":self.inputView,@"inputAccessoryBGView":self.inputAccessoryBGView}];
    
    [self addConstraints:hVFL];
    [self addConstraints:vVFL];
    
    CGRect bounds = self.bounds;
    bounds.size.height = DYHKBH;
    self.bounds = bounds;
    
    //创建键盘
    if (self.keyboardType == DYHkeyboardTypeNumberPad) {
        [self setupNumberPad];
    } else if (self.keyboardType == DYHKeyboardTypeASCIICapable) {
        [self setupASCIICapable];
    } else if (self.keyboardType == DYHkeyboardTypeSymbol){
        [self setupSymbol];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    //NSLog(@"%s--%@",__FUNCTION__,newWindow);
    if (!newWindow) {
        switch (self.keyboardType) {
            case DYHkeyboardTypeSymbol:
                [self toSymbolKeyboard];
                break;
            case DYHkeyboardTypeNumberPad:
                [self toNumberKeyboard];
                break;
            case DYHKeyboardTypeASCIICapable:
                [self toCharKeyboard];
                break;
            default:
                break;
        }
    }
}

#pragma mark - 创建数字键盘
- (void)setupNumberPad {
    int cols = 3;
    int rows = 4;
    UIColor *lineColor = DYHColorFromHex(0x17242c);
    UIColor *titleColor = DYHColorFromRGB(250, 250, 250);
    UIColor *heightLightColor = DYHColorFromHex(0x213953);
    UIFont  *titleFont = DYHKBFont(DYHKBFontSize);
    CGFloat itemH = DYHKBH * 0.25;
    CGFloat itemW = DYHSCREEN_WIDTH/cols;
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            CGRect bounds = CGRectMake(j*itemW, i*itemH, itemW, itemH);
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
            btn.layer.borderWidth = 1;
            btn.layer.borderColor = lineColor.CGColor;
            btn.frame = bounds;
            btn.titleLabel.font = titleFont;
            btn.titleLabel.textAlignment = NSTextAlignmentCenter;
            btn.titleLabel.textColor = titleColor;
            [btn setTitleColor:titleColor forState:UIControlStateNormal];
            [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
            [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
            SEL selector;
            
            if (i*(rows-1)+j == (rows*cols-3)) {
                selector = @selector(toCharKeyboard);
            } else if (i*(rows-1)+j == (rows*cols-1)){
                selector = @selector(deleteAction:);
            } else {
                selector = @selector(numberAction:);
            }
            NSInteger tag = i*(rows-1)+j;
            btn.tag = tag;
            [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
            [self.inputView addSubview:btn];
            
        }
    }
    
    [self loadRandomNumber];

}

- (void)loadRandomNumber {
    
    NSArray *titles = [self generateRandomNumber];
    NSArray *subviews = self.inputView.subviews;
    [subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            UIButton *tmp = (UIButton *)obj;
            NSInteger tempTag = tmp.tag;
            NSString *title;
            if (tempTag == 9) {
                title = @"ABC";
                [tmp setTitle:title forState:UIControlStateNormal];
            } else if (tempTag == 10) {
                title = titles.lastObject;
                [tmp setTitle:title forState:UIControlStateNormal];
            } else if (tempTag == 11) {
                [tmp setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
            } else {
                title = titles[tempTag];
                [tmp setTitle:title forState:UIControlStateNormal];
            }
        }
    }];

}

// 选择一个n以下的随机整数
// 计算m, 2的幂略高于n, 然后采用 random() 模数m,
// 如果在n和m之间就扔掉随机数
// (更多单纯的方法, 比如采用random()模数n, 介绍一个偏置)
// 倾向范围内较小的数字
static int random_below(int n) {
    int m = 1;
    //计算比n更大的两个最小的幂
    do {
        m <<= 1;
    } while(m < n);
    
    int ret;
    do {
        ret = random() % m;
    } while(ret >= n);
    return ret;
}

static inline int random_int(int low, int high) {
    return (arc4random() % (high-low+1)) + low;
}

- (NSArray *)generateRandomNumber {
    NSMutableArray *tmp = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        NSString *c = DYHFormat(@"%d",i);
        [tmp addObject:c];
    }

    int len = (int)[tmp count];
    int max = random_below(len);
    for (int i = 0; i < max; i++) {
        int t = random_int(0, len-1);
        int index = (t+max)%len;
        [tmp exchangeObjectAtIndex:t withObjectAtIndex:index];
    }
    return [tmp copy];

}

#pragma mark - 字符键盘

- (void)setupASCIICapable {
    
    UIColor *lineColor = DYHColorFromHex(0x17242c);
    UIColor *titleColor = DYHColorFromRGB(250, 250, 250);
    UIColor *heightLightColor = DYHColorFromHex(0x213953);
    UIFont  *titleFont = DYHKBFont(DYHKBFontSize);
    CGFloat itemW = (DYHSCREEN_WIDTH - 2) / 10;//左右margin为2
    CGFloat itemH = DYHKBH * 0.25;//row为4
    
    NSArray *title1s = [Characters subarrayWithRange:NSMakeRange(0, 10)];
    NSArray *title2s = [Characters subarrayWithRange:NSMakeRange(title1s.count, 9)];
    NSArray *title3s = [Characters subarrayWithRange:NSMakeRange(title1s.count + title2s.count, 7)];
    
    //第一排length = 10
    for (int i = 0; i < 10; i++) {
        CGRect bounds = CGRectMake(i*itemW + 1, 0, itemW, itemH);
        DYHCharButton *btn = [DYHCharButton buttonWithType:UIButtonTypeCustom];
        btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = lineColor.CGColor;
        btn.layer.cornerRadius = 4;
        btn.frame = bounds;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn updateChar:title1s[i]];
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
        [self.inputView addSubview:btn];
        [btn addTarget:self action:@selector(numberAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    //第二排length = 10
    CGFloat firstX = (DYHSCREEN_WIDTH - itemW * 9) * 0.5;
    for (int i = 0; i < 9; i++) {
        CGRect bounds = CGRectMake(i*itemW + firstX, itemH, itemW, itemH);
        DYHCharButton *btn = [DYHCharButton buttonWithType:UIButtonTypeCustom];
        btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = lineColor.CGColor;
        btn.layer.cornerRadius = 4;
        btn.frame = bounds;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn updateChar:title2s[i]];
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
        [self.inputView addSubview:btn];
        [btn addTarget:self action:@selector(numberAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //第三排length = 9
    for (int i = 0; i < 9; i++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        CGFloat item4W = (DYHSCREEN_WIDTH - 7 * itemW - 2) * 0.5;
        CGRect bounds;
        SEL selector;
        
        if (i == 0) {
            bounds = CGRectMake(1, 2*itemH, item4W, itemH);
            selector = @selector(shiftAction:);
            [btn setImage:[UIImage imageNamed:@"shift_Nor"] forState:UIControlStateNormal];
        } else if (i == 8) {
            bounds = CGRectMake(item4W + (i - 1)*itemW + 1, 2*itemH, item4W, itemH);
            selector = @selector(deleteAction:);
            [btn setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
        }
        else {
            
            btn = [DYHCharButton buttonWithType:UIButtonTypeCustom];
            
            bounds = CGRectMake(item4W + (i - 1)*itemW + 1, 2*itemH, itemW, itemH);
            selector = @selector(numberAction:);
            [(DYHCharButton *)btn updateChar:title3s[i-1]];
        }
        
        btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = lineColor.CGColor;
        btn.layer.cornerRadius = 4;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
        
        btn.frame = bounds;
        [self.inputView addSubview:btn];
        [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    //第四排length = 9
    for (int i = 0; i < 3; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = lineColor.CGColor;
        btn.layer.cornerRadius = 4;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
        
        CGFloat item4W = (DYHSCREEN_WIDTH - 7 * itemW - 2) * 0.5;
        CGRect bounds;
        SEL selector;
        
        if (i == 0) {
            bounds = CGRectMake(1, 3*itemH, item4W, itemH);
            selector = @selector(toNumberKeyboard);
            [btn setTitle:@"123" forState:UIControlStateNormal];
        } else if (i == 1) {
            bounds = CGRectMake(item4W + 1, 3*itemH, 7 * itemW, itemH);
            [btn setImage:[UIImage imageNamed:@"space"] forState:UIControlStateNormal];
            selector = @selector(spaceKeyAction:);
        }
        else {
            bounds = CGRectMake(item4W + 7*itemW + 1, 3*itemH, item4W, itemH);
            selector = @selector(toSymbolKeyboard);
            [btn setTitle:@"符" forState:UIControlStateNormal];
        }
        btn.frame = bounds;
        [self.inputView addSubview:btn];
        [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    }

}

#pragma mark - 符号键盘
- (void)setupSymbol {
    
    UIColor *lineColor = DYHColorFromHex(0x17242c);
    UIColor *titleColor = DYHColorFromRGB(250, 250, 250);
    UIColor *heightLightColor = DYHColorFromHex(0x213953);
    UIFont  *titleFont = DYHKBFont(DYHKBFontSize);
    CGFloat itemW = (DYHSCREEN_WIDTH - 2) / 10;//左右margin为2
    CGFloat itemH = DYHKBH * 0.25;//row为4
    
    NSArray *title1s = [Symbols subarrayWithRange:NSMakeRange(0, 10)];
    NSArray *title2s = [Symbols subarrayWithRange:NSMakeRange(title1s.count, 10)];
    NSArray *title3s = [Symbols subarrayWithRange:NSMakeRange(title1s.count + title2s.count, 8)];
    NSArray *title4s = [Symbols subarrayWithRange:NSMakeRange(title1s.count + title2s.count + title3s.count, 7)];
    
    NSMutableArray *temp_arr = [NSMutableArray arrayWithArray:title4s];
    [temp_arr insertObject:@"123" atIndex:0];
    [temp_arr insertObject:@"ABC" atIndex:temp_arr.count];
    title4s = [temp_arr copy];
    
    //第一排length = 10
    for (int i = 0; i < 10; i++) {
        CGRect bounds = CGRectMake(i*itemW + 1, 2, itemW, itemH);
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = lineColor.CGColor;
        btn.layer.cornerRadius = 4;
        btn.frame = bounds;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitle:title1s[i] forState:UIControlStateNormal];
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
        [self.inputView addSubview:btn];
        [btn addTarget:self action:@selector(numberAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    //第二排length = 10
    for (int i = 0; i < 10; i++) {
        CGRect bounds = CGRectMake(i*itemW + 1, itemH, itemW, itemH);
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = lineColor.CGColor;
        btn.layer.cornerRadius = 4;
        btn.frame = bounds;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitle:title2s[i] forState:UIControlStateNormal];
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
        [self.inputView addSubview:btn];
        [btn addTarget:self action:@selector(numberAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //第三排length = 9
    for (int i = 0; i < 9; i++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = lineColor.CGColor;
        btn.layer.cornerRadius = 4;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
        
        SEL selector;
        CGFloat item3W = itemW;
        if (i == 8) {
            item3W = DYHSCREEN_WIDTH - 8 * itemW - 2;
            [btn setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
            selector = @selector(deleteAction:);
        } else {
            [btn setTitle:title3s[i] forState:UIControlStateNormal];
            selector = @selector(numberAction:);
        }
        CGRect bounds = CGRectMake(i*itemW + 1, 2*itemH, item3W, itemH);
        btn.frame = bounds;
        [self.inputView addSubview:btn];
        [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    //第四排length = 9
    for (int i = 0; i < 9; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.exclusiveTouch = true;//避免在一个界面上同时点击多个button
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = lineColor.CGColor;
        btn.layer.cornerRadius = 4;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitle:title4s[i] forState:UIControlStateNormal];
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageWithPureColor:heightLightColor] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[UIImage imageWithPureColor:[UIColor clearColor]] forState:UIControlStateNormal];
        
        CGFloat item4W = (DYHSCREEN_WIDTH - 7 * itemW - 2) * 0.5;
        CGRect bounds;
        SEL selector;
        
        if (i == 0) {
            bounds = CGRectMake(1, 3*itemH, item4W, itemH);
            selector = @selector(toNumberKeyboard);
        } else if (i == 8) {
            bounds = CGRectMake(item4W + (i - 1)*itemW + 1, 3*itemH, item4W, itemH);
            selector = @selector(toCharKeyboard);
        }
        else {
            bounds = CGRectMake(item4W + (i - 1)*itemW + 1, 3*itemH, itemW, itemH);
            selector = @selector(numberAction:);
        }
        btn.frame = bounds;
        [self.inputView addSubview:btn];
        [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    }

}
#pragma mark - Event

- (void)deleteAction:(UIButton *)btn {
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            [tmp deleteBackward];
        }
    } else if ([self.inputSource isKindOfClass:[UITextView class]]) {
        UITextView *tmp = (UITextView *)self.inputSource;
        [tmp deleteBackward];
    } else if ([self.inputSource isKindOfClass:[UISearchBar class]]) {
        UISearchBar *tmp = (UISearchBar *)self.inputSource;
        NSMutableString *info = [NSMutableString stringWithString:tmp.text];
        if (info.length > 0) {
            NSString *s = [info substringToIndex:info.length-1];
            [tmp setText:s];
        }
    }
}

- (void)numberAction:(UIButton *)btn {
    NSString *title = [btn titleLabel].text;
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textField:tmp shouldChangeCharactersInRange:range replacementString:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textView:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            NSMutableString *info = [NSMutableString stringWithString:tmp.text];
            [info appendString:title];
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate searchBar:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp setText:[info copy]];
                }
            }else{
                [tmp setText:[info copy]];
            }
        }
    }
}

//大小写切换
- (void)shiftAction:(UIButton *)btn {
    self.shiftEnable = !self.shiftEnable;
    NSArray *subChars = [self.inputView subviews];
    [btn setImage:self.shiftEnable ? [UIImage imageNamed:@"shift_Nor"] : [UIImage imageNamed:@"shift_Light"] forState:UIControlStateNormal];
    [subChars enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[DYHCharButton class]]) {
            DYHCharButton *tmp = (DYHCharButton *)obj;
            [tmp shift:self.shiftEnable];
        }
    }];
}

/*
 *  空格键点击事件
 */
- (void)spaceKeyAction:(UIButton *)btn {
    NSString *title = @" ";
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textField:tmp shouldChangeCharactersInRange:range replacementString:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textView:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            NSMutableString *info = [NSMutableString stringWithString:tmp.text];
            [info appendString:title];
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate searchBar:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp setText:[info copy]];
                }
            }else{
                [tmp setText:[info copy]];
            }
        }
    }
}

- (void)toCharKeyboard {
    //移除所有的子视图
    [self.inputView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setupASCIICapable];
}

- (void)toNumberKeyboard {
    //移除所有的子视图
    [self.inputView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setupNumberPad];
}

- (void)toSymbolKeyboard {
    //移除所有的子视图
    [self.inputView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setupSymbol];
}

#pragma mark - setter
- (void)setInputAccessoryView:(UIView *)inputAccessoryView {
    _inputAccessoryView = inputAccessoryView;
    
    inputAccessoryView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputAccessoryBGView addSubview:inputAccessoryView];
    
    NSArray *bgViewhVFL = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[inputAccessoryView]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"inputAccessoryView":inputAccessoryView}];
    NSArray *bgViewvVFL = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[inputAccessoryView]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"inputAccessoryView":inputAccessoryView}];
    
    NSArray *vVFL = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[inputAccessoryBGView]-[inputView(inputViewHeight)]|" options:NSLayoutFormatAlignAllRight | NSLayoutFormatAlignAllLeft metrics:@{@"inputViewHeight":@(DYHKBH)} views:@{@"inputView":self.inputView,@"inputAccessoryBGView":self.inputAccessoryBGView}];
    [self removeConstraints:vVFL];
    
    NSArray *vVFL2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[inputAccessoryBGView(inputAccessoryBGViewHeight)]-[inputView(inputViewHeight)]|" options:NSLayoutFormatAlignAllRight | NSLayoutFormatAlignAllLeft metrics:@{@"inputAccessoryBGViewHeight":@(inputAccessoryView.bounds.size.height) ,@"inputViewHeight":@(DYHKBH)} views:@{@"inputView":self.inputView,@"inputAccessoryBGView":self.inputAccessoryBGView}];
    
    [self addConstraints:bgViewhVFL];
    [self addConstraints:bgViewvVFL];
    [self addConstraints:vVFL2];
    
    CGRect bounds = self.bounds;
    bounds.size.height = DYHKBH + inputAccessoryView.bounds.size.height;
    self.bounds = bounds;
}

@end

