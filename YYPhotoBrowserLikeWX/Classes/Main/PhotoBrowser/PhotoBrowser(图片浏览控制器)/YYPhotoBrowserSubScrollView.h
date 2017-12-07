//
//  YYPhotoBrowserSubScrollView.h
//  YYPhotoBrowserLikeWX
//
//  Created by yuyou on 2017/12/5.
//  Copyright © 2017年 yy. All rights reserved.
//


/**
 *  这个控件的核心是：把每一张图片包装进一个scrollview，
 *                这样才能实现图片的放大等功能。
 */

#import <UIKit/UIKit.h>
@class YYPhotoBrowserSubScrollView;

@protocol YYPhotoBrowserSubScrollViewDelegate <NSObject>

/** 单击回调 */
- (void)YYPhotoBrowserSubScrollViewDoSingleTapWithImageFrame:(CGRect)imageFrame;
/** 开始或结束向下拖拽（外部需要隐藏其它图片，否则左右滑时会看到），needBack页面是否需要退回，imageFrame退回时用来做动画，不退回时可以不传 */
- (void)YYPhotoBrowserSubScrollViewDoDownDrag:(BOOL)isBegin view:(YYPhotoBrowserSubScrollView *)subScrollView needBack:(BOOL)needBack imageFrame:(CGRect)imageFrame;
/** 拖拽进行中额回调，把拖拽进度发下去，以设置透明度 */
- (void)YYPhotoBrowserSubScrollViewDoingDownDrag:(CGFloat)dragProportion;

@end

@interface YYPhotoBrowserSubScrollView : UIView

@property (nonatomic,weak) id<YYPhotoBrowserSubScrollViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame imageNamed:(NSString *)imageNamed;

@end
