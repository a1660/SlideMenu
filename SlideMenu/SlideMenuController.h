//
//  SlideMenuController.h
//  SlideMenu
//
//  Created by 肖伟华 on 16/5/28.
//  Copyright © 2016年 XWH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SlideMenuController : UIViewController

@property (nonatomic,strong) UIViewController *leftMenuViewController;
@property (nonatomic,strong) UIViewController *mainViewController;
@property (nonatomic,strong) UIImage *backgroundImage;

/**
 *  菜单打开时原来内容页露在侧边的最大宽，注意是指缩放完成之后的
 */
@property (nonatomic,assign) CGFloat mainViewVisibleWidth;

- (id)initWithContentViewController:(UIViewController *)mainViewController leftMenuViewController:(UIViewController *)leftMenuViewController;

- (void)showViewController:(UIViewController *)viewController;
- (void)hideMenu;
- (void)showMenu;

@end
