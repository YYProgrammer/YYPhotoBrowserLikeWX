//
//  YYPhotoBrowserMainScrollView.h
//  YYPhotoBrowserLikeWX
//
//  Created by yuyou on 2017/12/5.
//  Copyright © 2017年 yy. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  这个控件的核心是：把所有图片的包装进一个大的scrollview，
 *                 这样才能实现左右滑动查看图片
 */

@protocol YYPhotoBrowserMainScrollViewDelegate <NSObject>

/** 单击 */
- (void)YYPhotoBrowserMainScrollViewDoSingleTapWithImageFrame:(CGRect)imageFrame;
/** 翻页 */
- (void)YYPhotoBrowserMainScrollViewChangeCurrentIndex:(int)currentIndex;
/** 向下拖拽 */
- (void)YYPhotoBrowserMainScrollViewDoingDownDrag:(CGFloat)dragProportion;
/** 需要退回页面 */
- (void)YYPhotoBrowserMainScrollViewNeedBackWithImageFrame:(CGRect)imageFrame;

@end

@interface YYPhotoBrowserMainScrollView : UIView

@property (nonatomic,weak) id<YYPhotoBrowserMainScrollViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame imageNameArray:(NSArray *)imageNameArray currentImageIndex:(int)index;

@end
