//
//  YYPhotoBrowserSubScrollView.m
//  YYPhotoBrowserLikeWX
//
//  Created by yuyou on 2017/12/5.
//  Copyright © 2017年 yy. All rights reserved.
//

#import "YYPhotoBrowserSubScrollView.h"
#import "POP.h"
//#import "yyTestScrollView.h"
#import <objc/runtime.h>

//弹簧系数
#define popSpringBounciness 0.0
//速度
#define popSpringSpeed 20.0

@interface YYPhotoBrowserSubScrollView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic,strong) NSString *imageNamed;//图片名称
@property (nonatomic,strong) UIScrollView *mainScrollView;//包装单个图片的scrollView
@property (nonatomic,strong) UIImageView *mainImageView;//图片控件
/** 手势 */
@property (nonatomic,strong) UITapGestureRecognizer *doubleTap;//双击
@property (nonatomic,strong) UITapGestureRecognizer *singleTap;//单击

@property (nonatomic,strong) UIImageView *moveImage;//拖拽时的展示image
@property (nonatomic,assign) BOOL doingPan;//正在拖拽
@property (nonatomic,assign) BOOL doingZoom;//正在缩放，此时不执行拖拽方法
@property (nonatomic,assign) CGFloat comProprotion;//拖拽进度
@property (nonatomic,assign) BOOL directionIsDown;//拖拽是不是正在向下，如果是，退回页面，否则，弹回

@end

#pragma mark - 向下拖拽相关的一些变量
//最多移动多少时，页面完全透明，图片达到最小状态
#define MAX_MOVE_OF_Y 250.0
//当移动达到MAX_MOVE_OF_Y时，图片缩小的比例
#define IMAGE_MIN_ZOOM 0.3
static CGFloat dragCoefficient = 0.0;//拖拽系数，手指移动距离和图片移动距离的系数，图片越高时它越大
static CGFloat panBeginX = 0.0;//向下拖拽手势开始时的X，在拖拽开始时赋值，拖拽结束且没有退回页面时置0
static CGFloat panBeginY = 0.0;//向下拖拽手势开始时的Y，在拖拽开始时赋值，拖拽结束且没有退回页面时置0
static CGFloat imageWidthBeforeDrag = 0.0;//向下拖拽开始时，图片的宽
static CGFloat imageHeightBeforeDrag = 0.0;//向下拖拽开始时，图片的高
static CGFloat imageCenterXBeforeDrag = 0.0;//向下拖拽开始时，图片的中心X
static CGFloat imageYBeforeDrag = 0.0;//向下拖拽开始时，图片的Y
static CGFloat scrollOffsetX = 0.0;//向下拖拽开始时，滚动控件的offsetX

@implementation YYPhotoBrowserSubScrollView

#pragma mark - 生命周期相关
- (instancetype)initWithFrame:(CGRect)frame imageNamed:(NSString *)imageNamed
{
    if (self = [super initWithFrame:frame])
    {
        self.imageNamed = imageNamed;
        
        //添加手势
        [self addGestureRecognizer:self.doubleTap];
        [self addGestureRecognizer:self.singleTap];
        
        [self createUI];
    }
    return self;
}

#pragma mark - setter
- (void)setComProprotion:(CGFloat)comProprotion
{
    _comProprotion = comProprotion;
    
    //改变进度时，就需要通知代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(YYPhotoBrowserSubScrollViewDoingDownDrag:)])
    {
        [self.delegate YYPhotoBrowserSubScrollViewDoingDownDrag:comProprotion];
    }
}

#pragma mark - UI相关
/** 基础UI搭建 */
- (void)createUI
{
    self.backgroundColor = [UIColor clearColor];//注意，背景是clearcolor
    
    self.mainScrollView.hidden = NO;//随意调用一下以懒加载显示
}

/** 计算imageview的center，核心方法之一 */
- (CGPoint)centerOfScrollViewContent:(UIScrollView *)scrollView
{
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;//x偏移
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;//y偏移
    CGPoint actualCenter = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,scrollView.contentSize.height * 0.5 + offsetY);
    
    return actualCenter;
}

#pragma mark - 事件响应
/** 核心：向下拖动的功能 */
- (void)doPan:(UIPanGestureRecognizer *)pan
{
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStatePossible)
    {
        panBeginX = 0.0;
        panBeginY = 0.0;
        self.doingPan = NO;
//        [self noticeDelegateBeginOrEndDrag:NO];
        
        return;
    }
    
    if (pan.numberOfTouches != 1 || self.doingZoom)//两个手指在拖，此时应该是在缩放，不执行继续执行
    {
        self.moveImage = nil;
        self.doingPan = NO;
        panBeginX = 0.0;
        panBeginY = 0.0;
//        [self noticeDelegateBeginOrEndDrag:NO];
        return;
    }
    
    if (panBeginX == 0.0 && panBeginY == 0.0)//说明新的一次下拉开始了
    {
        panBeginX = [pan locationInView:self].x;//赋值初始x
        panBeginY = [pan locationInView:self].y;//赋值初始Y
        self.doingPan = YES;
        self.mainImageView.hidden = YES;
        [self saveFrameBeginPan];//计算并存储image初始frame;
        [self noticeDelegateBeginOrEndDrag:YES];
    }
    
    if (self.moveImage == nil)
    {
        self.moveImage = [[UIImageView alloc] init];
        [self addSubview:self.moveImage];
        self.moveImage.contentMode = UIViewContentModeScaleAspectFill;
        self.moveImage.backgroundColor = [UIColor whiteColor];
        self.moveImage.layer.masksToBounds = YES;
        self.moveImage.image = [UIImage imageNamed:self.imageNamed];
        self.moveImage.yy_width = imageWidthBeforeDrag;
        self.moveImage.yy_height = imageHeightBeforeDrag;
        self.moveImage.yy_centerX = imageCenterXBeforeDrag;
        self.moveImage.yy_y = imageYBeforeDrag;
    }
    
    static CGFloat panLastY = 0.0;
    CGFloat panCurrentX = [pan locationInView:self].x;//触摸点当前的x
    CGFloat panCurrentY = [pan locationInView:self].y;//触摸点当前的y
    
    //判断是不是正在向下拖拽
    self.directionIsDown = panCurrentY > panLastY;
    panLastY = panCurrentY;
    
    //拖拽进度
    CGFloat comProprotion = (panCurrentY - panBeginY) / MAX_MOVE_OF_Y;
    comProprotion = comProprotion > 1.0 ? 1.0 : comProprotion;
    self.comProprotion = comProprotion;//set方法中通知代理
    if (panCurrentY > panBeginY)//当前的y比起始的时候大
    {
        self.moveImage.yy_width = imageWidthBeforeDrag - (imageWidthBeforeDrag - imageWidthBeforeDrag * IMAGE_MIN_ZOOM) * comProprotion;
        self.moveImage.yy_height = imageHeightBeforeDrag - (imageHeightBeforeDrag - imageHeightBeforeDrag * IMAGE_MIN_ZOOM) * comProprotion;
    }
    else//当前的Y比起始的时候还小，此时图片的大小保持原状
    {
        self.moveImage.yy_width = imageWidthBeforeDrag;
        self.moveImage.yy_height = imageHeightBeforeDrag;
    }
    self.moveImage.yy_centerX = (panCurrentX - panBeginX) + imageCenterXBeforeDrag;
    self.moveImage.yy_y = (panCurrentY - panBeginY) * dragCoefficient + imageYBeforeDrag;
}

/** 核心方法：存储拖拽开始前，图片的frame */
- (void)saveFrameBeginPan
{
    imageWidthBeforeDrag = self.mainImageView.yy_width;
    imageHeightBeforeDrag = self.mainImageView.yy_height;
    //计算图片centerY需要考虑到图片此时的高
    CGFloat imageBeginY = (imageHeightBeforeDrag < kMainScreenHeight) ? (kMainScreenHeight - imageHeightBeforeDrag) * 0.5 : 0.0;
    imageYBeforeDrag = imageBeginY; //+ imageHeightBeforeDrag * 0.5;
    //centerX需要考虑到offset
    scrollOffsetX = self.mainScrollView.contentOffset.x;
    CGFloat imageX = -scrollOffsetX;
    imageCenterXBeforeDrag = imageX + imageWidthBeforeDrag * 0.5;
    dragCoefficient = 1.0 + imageHeightBeforeDrag / 2000.0;
}

/** 核心方法：拖拽结束 */
- (void)endPan
{
    if (!self.directionIsDown)//不退回页面
    {
        //套一个动画，这要comProprotion是逐渐改变，动画时间
        [UIView animateWithDuration:0.35 animations:^{
            self.comProprotion = 0.0;
        }];
        
        //设置动画把图片弹回去
        POPSpringAnimation *imageMove = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
        //计算图片浏览器中image的frame
        imageMove.fromValue = [NSValue valueWithCGRect:CGRectMake(self.moveImage.yy_x, self.moveImage.yy_y, self.moveImage.yy_width, self.moveImage.yy_height)];
        imageMove.toValue = [NSValue valueWithCGRect:CGRectMake(imageCenterXBeforeDrag - imageWidthBeforeDrag * 0.5, imageYBeforeDrag, imageWidthBeforeDrag, imageHeightBeforeDrag)];
        imageMove.beginTime = CACurrentMediaTime();
        imageMove.springBounciness = popSpringBounciness;
        imageMove.springSpeed = popSpringSpeed;
        imageMove.completionBlock = ^(POPAnimation *anim ,BOOL isEnd){
            
            self.mainScrollView.contentOffset = CGPointMake(scrollOffsetX, 0);
            panBeginX = 0.0;
            panBeginY = 0.0;
            [self noticeDelegateBeginOrEndDrag:NO];
            self.moveImage.hidden = YES;
            self.mainImageView.hidden = NO;
            self.moveImage = nil;
        };
        [self.moveImage pop_addAnimation:imageMove forKey:nil];
    }
    else
    {
        //通知代理结束拖拽，并退回页面
        if (self.delegate && [self.delegate respondsToSelector:@selector(YYPhotoBrowserSubScrollViewDoDownDrag:view:needBack:imageFrame:)])
        {
            [self.delegate YYPhotoBrowserSubScrollViewDoDownDrag:NO view:self needBack:YES imageFrame:self.moveImage.frame];
        }
    }
}


/** 双击 */
- (void)doDoubleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint touchPoint = [recognizer locationInView:self];
    if (self.mainScrollView.zoomScale <= 1.0)
    {
        CGFloat scaleX = touchPoint.x + self.mainScrollView.contentOffset.x;//需要放大的图片的X点
        CGFloat sacleY = touchPoint.y + self.mainScrollView.contentOffset.y;//需要放大的图片的Y点
        [self.mainScrollView zoomToRect:CGRectMake(scaleX, sacleY, 10, 10) animated:YES];
    }
    else
    {
        [self.mainScrollView setZoomScale:1.0 animated:YES]; //还原
    }
}

/** 单击 */
- (void)doSingleTap:(UITapGestureRecognizer *)recognizer
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(YYPhotoBrowserSubScrollViewDoSingleTapWithImageFrame:)])
    {
        CGFloat imageW = self.mainImageView.yy_width;
        CGFloat imageH = self.mainImageView.yy_height;
        //计算图片imageY需要考虑到图片此时的高
        CGFloat imageY = (imageH < kMainScreenHeight) ? (kMainScreenHeight - imageH) * 0.5 : 0.0;
        imageY = imageY - self.mainScrollView.contentOffset.y;
        //centerX需要考虑到offset
        CGFloat imageX = -self.mainScrollView.contentOffset.x;
        [self.delegate YYPhotoBrowserSubScrollViewDoSingleTapWithImageFrame:CGRectMake(imageX, imageY, imageW, imageH)];
    }
}

/** 通知代理开始或结束拖拽,不返回 */
- (void)noticeDelegateBeginOrEndDrag:(BOOL)isBegin
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(YYPhotoBrowserSubScrollViewDoDownDrag:view:needBack:imageFrame:)])
    {
        [self.delegate YYPhotoBrowserSubScrollViewDoDownDrag:isBegin view:self needBack:NO imageFrame:CGRectZero];
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.mainImageView;//返回需要缩放的控件
}

/** 缩放完成的回调 */
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    self.mainImageView.center = [self centerOfScrollViewContent:scrollView];
    self.doingZoom = NO;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.doingZoom = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    static float scrollNewY = 0;
    static float scrollOldY = 0;
    scrollNewY = scrollView.contentOffset.y;
    if ((scrollView.contentOffset.y < 0 || self.doingPan) && (self.doingZoom == NO))
    {
        [self doPan:self.mainScrollView.panGestureRecognizer];
    }
    scrollOldY = scrollNewY;
}

//结束拖拽
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self endPan];
}

#pragma mark - 懒加载
- (UIScrollView *)mainScrollView
{
    if (!_mainScrollView)
    {
        _mainScrollView = [[UIScrollView alloc] init];
        [self addSubview:_mainScrollView];
        _mainScrollView.frame = CGRectMake(0, 0, self.yy_width, self.yy_height);// frame中的size指UIScrollView的可视范围
        _mainScrollView.delegate = self;
        _mainScrollView.backgroundColor = [UIColor clearColor];//注意，背景是clearcolor
        _mainScrollView.clipsToBounds = YES;
        _mainScrollView.showsVerticalScrollIndicator = NO;
        _mainScrollView.showsHorizontalScrollIndicator = NO;
        _mainScrollView.alwaysBounceVertical = YES;
        _mainScrollView.alwaysBounceHorizontal = YES;//这是为了左右滑时能够及时回调scrollViewDidScroll代理
        if (@available(iOS 11.0, *))//表示只在ios11以上的版本执行
        {
            _mainScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        [_mainScrollView addSubview:self.mainImageView];//加入imageview
        
        _mainScrollView.contentSize = self.mainImageView.frame.size;
        self.mainImageView.center = [self centerOfScrollViewContent:_mainScrollView];
        _mainScrollView.minimumZoomScale = 1.0;//最小缩放比例
        _mainScrollView.maximumZoomScale = 3.0;//最大缩放比例
        _mainScrollView.zoomScale = 1.0f;//当前缩放比例
        _mainScrollView.contentOffset = CGPointZero;//当前偏移
    }
    return _mainScrollView;
}

- (UIImageView *)mainImageView
{
    if (!_mainImageView)
    {
        _mainImageView = [[UIImageView alloc] init];
        _mainImageView.contentMode = UIViewContentModeScaleAspectFill;
        _mainImageView.backgroundColor = [UIColor whiteColor];
        _mainImageView.layer.masksToBounds = YES;
        //根据image宽高算imageview的宽高
        UIImage *image = [UIImage imageNamed:self.imageNamed];
        CGSize imageSize = image.size;
        CGFloat imageViewWidth = kMainScreenWidth;
        CGFloat imageViewHeight = imageSize.height / imageSize.width * imageViewWidth;//等于是按比例算出满宽时的高
        _mainImageView.yy_width = imageViewWidth;
        _mainImageView.yy_height = imageViewHeight;
        _mainImageView.image = image;
        
        
    }
    return _mainImageView;
}

- (UITapGestureRecognizer *)doubleTap
{
    if (!_doubleTap)
    {
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)];
        _doubleTap.numberOfTapsRequired = 2;
        _doubleTap.numberOfTouchesRequired  =1;
    }
    return _doubleTap;
}

- (UITapGestureRecognizer *)singleTap
{
    if (!_singleTap)
    {
        _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
        _singleTap.numberOfTapsRequired = 1;
        _singleTap.numberOfTouchesRequired = 1;
        [_singleTap requireGestureRecognizerToFail:self.doubleTap];//系统会先判定是不是双击，如果不是，才会调单击的事件
        
    }
    return _singleTap;
}

@end
