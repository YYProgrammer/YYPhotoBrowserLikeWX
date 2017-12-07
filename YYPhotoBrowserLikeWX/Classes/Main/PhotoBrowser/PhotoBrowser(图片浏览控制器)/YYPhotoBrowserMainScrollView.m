//
//  YYPhotoBrowserMainScrollView.m
//  YYPhotoBrowserLikeWX
//
//  Created by yuyou on 2017/12/5.
//  Copyright © 2017年 yy. All rights reserved.
//

#import "YYPhotoBrowserMainScrollView.h"
#import "YYPhotoBrowserSubScrollView.h"

//图片间的间距
#define MARGIN_BETWEEN_IMAGE 20

@interface YYPhotoBrowserMainScrollView () <UIScrollViewDelegate, YYPhotoBrowserSubScrollViewDelegate>

@property (nonatomic,strong) NSArray *imageNameArray;//图片名数组
@property (nonatomic,assign) int currentIndex;//当前的图片索引
@property (nonatomic,strong) UIScrollView *mainScrollView;//主滚动控件

@property (nonatomic,assign) BOOL scrollDoEvent;
@property (nonatomic,assign) CGPoint currentPoint;
@property (nonatomic,strong) UIEvent *currentEvent;

@end

@implementation YYPhotoBrowserMainScrollView

- (instancetype)initWithFrame:(CGRect)frame imageNameArray:(NSArray *)imageNameArray currentImageIndex:(int)index
{
    if (self = [super initWithFrame:frame])
    {
        self.imageNameArray = [imageNameArray copy];
        self.currentIndex = index;
        
        [self createUI];
    }
    return self;
}

- (void)createUI
{
    self.backgroundColor = [UIColor clearColor];//注意，背景是clearcolor
    
    /**
     *  滚动控件，包含所有图片，每一页是一张图片(但其实每个图片本身还包装了个scrollview用于缩放)
     */
    UIScrollView *mainScrollView = [[UIScrollView alloc] init];
    [self addSubview:mainScrollView];
    self.mainScrollView = mainScrollView;
    mainScrollView.frame = CGRectMake(0, 0, self.yy_width + MARGIN_BETWEEN_IMAGE, self.yy_height);// frame中的size指UIScrollView的可视范围
    mainScrollView.layer.masksToBounds = NO;
    mainScrollView.contentSize = CGSizeMake(self.imageNameArray.count * (self.yy_width + MARGIN_BETWEEN_IMAGE), 0);// 设置UIScrollView的滚动范围（内容大小）
    mainScrollView.delegate = self;
    mainScrollView.backgroundColor = [UIColor clearColor];//注意，背景是clearcolor
    mainScrollView.showsHorizontalScrollIndicator = NO;
    mainScrollView.pagingEnabled = YES;//分页
    if (@available(iOS 11.0, *))//表示只在ios11以上的版本执行
    {
        mainScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    //添加图片
    for (int i = 0; i < self.imageNameArray.count; i++)
    {
        YYPhotoBrowserSubScrollView *subScrollView = [[YYPhotoBrowserSubScrollView alloc] initWithFrame:CGRectMake(i * (self.yy_width + MARGIN_BETWEEN_IMAGE), 0, self.yy_width, self.yy_height) imageNamed:self.imageNameArray[i]];
        [mainScrollView addSubview:subScrollView];
        subScrollView.delegate = self;
        subScrollView.tag = i + 1;
    }
    
    //设置偏移量，即滚到当前用户选择的图片
    mainScrollView.contentOffset = CGPointMake(self.currentIndex * (self.yy_width + MARGIN_BETWEEN_IMAGE), 0);
    
}

#pragma mark - uiscrollview代理
/** 减速完毕 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //计算当前滚到了哪个index
    self.currentIndex  = scrollView.contentOffset.x / self.mainScrollView.yy_width;
    
    //通知代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(YYPhotoBrowserMainScrollViewChangeCurrentIndex:)])
    {
        [self.delegate YYPhotoBrowserMainScrollViewChangeCurrentIndex:self.currentIndex];
    }
}

#pragma mark - 单个图片的控件的代理
- (void)YYPhotoBrowserSubScrollViewDoSingleTapWithImageFrame:(CGRect)imageFrame
{
    //继续向下通知代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(YYPhotoBrowserMainScrollViewDoSingleTapWithImageFrame:)])
    {
        [self.delegate YYPhotoBrowserMainScrollViewDoSingleTapWithImageFrame:imageFrame];
    }
}

- (void)YYPhotoBrowserSubScrollViewDoDownDrag:(BOOL)isBegin view:(YYPhotoBrowserSubScrollView *)subScrollView needBack:(BOOL)needBack imageFrame:(CGRect)imageFrame
{
    if (needBack)//需要退回页面时，向下通知代理
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(YYPhotoBrowserMainScrollViewNeedBackWithImageFrame:)])
        {
            [self.delegate YYPhotoBrowserMainScrollViewNeedBackWithImageFrame:imageFrame];
        }
    }
    else
    {
        for (UIView *subView in self.mainScrollView.subviews)
        {
            if ([subView isKindOfClass:[YYPhotoBrowserSubScrollView class]])
            {
                if (subView.tag == subScrollView.tag)
                {
                    continue;
                }
                subView.hidden = isBegin;
            }
        }
    }
    
}

- (void)YYPhotoBrowserSubScrollViewDoingDownDrag:(CGFloat)dragProportion
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(YYPhotoBrowserMainScrollViewDoingDownDrag:)])
    {
        [self.delegate YYPhotoBrowserMainScrollViewDoingDownDrag:dragProportion];
    }
}

@end
