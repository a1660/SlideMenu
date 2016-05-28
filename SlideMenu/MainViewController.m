//
//  MainViewController.m
//  SlideMenu
//
//  Created by 肖伟华 on 16/5/28.
//  Copyright © 2016年 XWH. All rights reserved.
//

#import "MainViewController.h"
#import "SlideMenuController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Main";
    UIImageView *imageBg = [[UIImageView alloc]initWithFrame:self.view.bounds];
    imageBg.image = [UIImage imageNamed:@"mainBg.jpg"];
    [self.view addSubview:imageBg];
    //operatedSlideMenuVC

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"展示" style:UIBarButtonItemStylePlain target:self action:@selector(onActionShow:)];
    
//    SlideMenuController *slideMenuVC = [[SlideMenuController alloc]init];
}
- (void)onActionShow:(UIBarButtonItem *)sender
{
    [[NSNotificationCenter defaultCenter]postNotificationName:@"operatedSlideMenuVC" object:@"Show"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
