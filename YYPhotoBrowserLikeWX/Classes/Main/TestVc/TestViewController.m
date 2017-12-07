//
//  TestViewController.m
//  YYPhotoBrowserLikeWX
//
//  Created by yuyou on 2017/12/5.
//  Copyright © 2017年 yy. All rights reserved.
//

#import "TestViewController.h"
#import "YYPhotoBrowserViewController.h"

@interface TestViewController ()

@property (nonatomic,strong) NSArray *imageNameArray;//图片名数组
@property (nonatomic,strong) NSMutableArray *imageViewArray;//图片控件数组
@property (nonatomic,strong) NSMutableArray *imageViewFrameArray;//图片控件在window中的位置

@end

@implementation TestViewController

#pragma mark - 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUIComponent];
}

#pragma mark - UI构建
- (void)setUIComponent
{
    self.view.backgroundColor = UIColorFromRGB(0xdddddd);
    
    CGFloat leftRightMargin = 15.0;//左右间距
    CGFloat marginBetweenImage = 10.0;//图片间间距
    CGFloat imageWidth = ([UIScreen mainScreen].bounds.size.width - 2 * leftRightMargin - 2 * marginBetweenImage) / 3.0;//图片宽
    CGFloat imageHeight = imageWidth / 3.0 * 2.0;//图片高
    CGFloat imagesBeginY = 100;
    for (int i = 0; i < self.imageNameArray.count; i++)
    {
        UIImageView *imageView = [[UIImageView alloc] init];
        [self.view addSubview:imageView];
        [self.imageViewArray addObject:imageView];
        int row = i / 3;
        int col = i % 3;
        imageView.frame = CGRectMake(leftRightMargin + col * (imageWidth + marginBetweenImage), imagesBeginY + row * (imageHeight + marginBetweenImage), imageWidth, imageHeight);
        [self saveWindowFrameWithOriginalFrame:imageView.frame];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.masksToBounds = YES;
        imageView.image = [UIImage imageNamed:self.imageNameArray[i]];
        imageView.tag = i;
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickImage:)]];
    }
}

#pragma mark - 事件响应
/** 根据图片再view中的位置，算出在window中的位置，并保存 */
- (void)saveWindowFrameWithOriginalFrame:(CGRect)originalFrame
{
    //因为这里恰好在view中的位置就是在window中的位置，所以不需要转frame
    //因为数组不能存结构体，所以存的时候转成NSValue
    NSValue *frameValue = [NSValue valueWithCGRect:originalFrame];
    [self.imageViewFrameArray addObject:frameValue];
}

/** 点击了图片 */
- (void)clickImage:(UITapGestureRecognizer *)tap
{
    NSInteger tag = tap.view.tag;
    NSLog(@"%ld",tag);
    
    YYPhotoBrowserViewController *photo = [[YYPhotoBrowserViewController alloc] initWithImageNameArray:self.imageNameArray currentImageIndex:((int)tag) imageViewArray:self.imageViewArray imageViewFrameArray:self.imageViewFrameArray];
    [self presentViewController:photo animated:YES completion:nil];
}

#pragma mark - 懒加载
- (NSArray *)imageNameArray
{
    if (!_imageNameArray)
    {
        _imageNameArray = [NSArray arrayWithObjects:@"01.jpg", @"02.jpg", @"03.jpg", @"04.jpg", @"05.jpg", @"06.jpg", nil];
    }
    return _imageNameArray;
}

- (NSMutableArray *)imageViewArray
{
    if (!_imageViewArray)
    {
        _imageViewArray = [NSMutableArray array];
    }
    return _imageViewArray;
}

- (NSMutableArray *)imageViewFrameArray
{
    if (!_imageViewFrameArray)
    {
        _imageViewFrameArray = [NSMutableArray array];
    }
    return _imageViewFrameArray;
}

@end
