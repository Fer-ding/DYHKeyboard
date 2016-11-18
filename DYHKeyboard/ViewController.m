//
//  ViewController.m
//  DYHKeyboard
//
//  Created by YueHui on 16/11/16.
//  Copyright © 2016年 LeapDing. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"

#import "DYHkeyboard.h"

@interface ViewController ()

@property (nonatomic, strong) UITextField *fd;
@property (nonatomic, strong) DYHkeyboard *kb;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //纯数字随机键盘
    UITextField *tfd = [[UITextField alloc] init];
    tfd.font = [UIFont systemFontOfSize:15];
    tfd.placeholder = @"input numbers";
    [self.view addSubview:tfd];
    [tfd mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(50);
        make.leading.equalTo(self.view).offset(30);
        make.trailing.equalTo(self.view).offset(-30);
        make.height.mas_greaterThanOrEqualTo(@30);
    }];
    self.fd = tfd;
    DYHkeyboard *kb = [DYHkeyboard keyboardWithType:DYHKeyboardTypeASCIICapable];
    self.fd.inputView = kb;
    kb.inputSource = tfd;
    self.kb = kb;
    
    //字符键盘
    UITextField *tfd2 = [[UITextField alloc] init];
    tfd2.font = [UIFont systemFontOfSize:15];
    tfd2.placeholder = @"say somthing";
    //tfd.delegate = self;
    tfd2.borderStyle = UITextBorderStyleBezel;
    [self.view addSubview:tfd2];
    [tfd2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfd.mas_bottom).offset(10);
        make.leading.equalTo(self.view).offset(30);
        make.trailing.equalTo(self.view).offset(-30);
        make.height.mas_greaterThanOrEqualTo(@30);
    }];
    kb = [DYHkeyboard keyboardWithType:DYHKeyboardTypeDefault];
    tfd2.inputView = kb;
    kb.inputSource = tfd2;
    
    //约束要写在kb.inputAccessoryView = extView;  不然会crash
//    UIView *extView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
//    extView.backgroundColor = [UIColor redColor];
//    kb.inputAccessoryView = extView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:true];
}

@end
