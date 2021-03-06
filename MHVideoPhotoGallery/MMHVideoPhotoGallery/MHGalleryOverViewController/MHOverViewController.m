//
//  MHGalleryOverViewController.m
//  MHVideoPhotoGallery
//
//  Created by Mario Hahn on 27.12.13.
//  Copyright (c) 2013 Mario Hahn. All rights reserved.
//

#import "MHOverViewController.h"

@implementation MHIndexPinchGestureRecognizer
@end

@interface MHOverViewController ()

@property (nonatomic, strong) MHTransitionShowDetail *interactivePushTransition;
@property (nonatomic, strong) NSNumberFormatter  *numberFormatter;

@property (nonatomic) CGPoint lastPoint;
@property (nonatomic) CGFloat startScale;

@end


@implementation MHOverViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.title =  MHGalleryLocalizedString(@"overview.title.current");
    
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    
    self.navigationItem.rightBarButtonItem = doneBarButton;
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:self.view.bounds
                                            collectionViewLayout:[self layoutForOrientation:UIApplication.sharedApplication.statusBarOrientation]];
    
    self.collectionView.backgroundColor = [self.gallerViewController.UICustomization MHGalleryBackgroundColorForViewMode:MHGalleryViewModeOverView];
    self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    
    [self.collectionView registerClass:[MHGalleryOverViewCell class]
            forCellWithReuseIdentifier:@"MHGalleryOverViewCell"];
    
    self.collectionView.dataSource =self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.delegate =self;
    self.collectionView.autoresizingMask =UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.collectionView];
    [self.collectionView reloadData];
        
    self.numberFormatter = [NSNumberFormatter new];
    [self.numberFormatter setMinimumIntegerDigits:2];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    UIMenuItem *saveItem = [[UIMenuItem alloc] initWithTitle:MHGalleryLocalizedString(@"overview.menue.item.save")
                                                      action:@selector(saveImage:)];
#pragma clang diagnostic pop
    
    [[UIMenuController sharedMenuController] setMenuItems:@[saveItem]];
    
}

-(UICollectionViewFlowLayout*)layoutForOrientation:(UIInterfaceOrientation)orientation{
    if (orientation == UIInterfaceOrientationPortrait ) {
        return self.gallerViewController.UICustomization.overViewCollectionViewLayoutPortrait;
    }
    return self.gallerViewController.UICustomization.overViewCollectionViewLayoutLandscape;
}

-(MHGalleryController*)gallerViewController{
    return  (MHGalleryController*)self.navigationController;
}


-(MHGalleryItem*)itemForIndex:(NSInteger)index{
    return [self.gallerViewController.dataSource itemForIndex:index];
}
-(void)donePressed{
    self.navigationController.transitioningDelegate = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.gallerViewController.dataSource numberOfItemsInGallery:self.gallerViewController];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell =nil;
    NSString *cellIdentifier = nil;
    cellIdentifier = @"MHGalleryOverViewCell";
    cell = (MHGalleryOverViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [self makeMHGalleryOverViewCell:(MHGalleryOverViewCell*)cell
                        atIndexPath:indexPath];
    
    return cell;
}



-(void)makeMHGalleryOverViewCell:(MHGalleryOverViewCell*)cell atIndexPath:(NSIndexPath*)indexPath{
    
    MHGalleryItem *item =  [self itemForIndex:indexPath.row];
    cell.thumbnail.image = nil;
    
    
    cell.videoGradient.hidden = YES;
    cell.videoIcon.hidden     = YES;
    
    
    cell.saveImage = ^(BOOL shouldSave){
        [self getImageForItem:item
               finishCallback:^(UIImage *image) {
                   UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
               }];
    };
    cell.videoDurationLength.text = @"";
    cell.thumbnail.backgroundColor = [UIColor lightGrayColor];
    __block MHGalleryOverViewCell *blockCell = cell;
    
    if (item.galleryType == MHGalleryTypeVideo) {
        [[MHGallerySharedManager sharedManager] startDownloadingThumbImage:item.URLString
                                                              successBlock:^(UIImage *image,NSUInteger videoDuration,NSError *error,NSString *newURL) {
                                                                  
                                                                  if (error) {
                                                                      blockCell.thumbnail.backgroundColor = [UIColor whiteColor];
                                                                      blockCell.thumbnail.image = MHGalleryImage(@"error");
                                                                  }else{
                                                                      NSNumber *minutes = @(videoDuration / 60);
                                                                      NSNumber *seconds = @(videoDuration % 60);
                                                                      
                                                                      blockCell.videoDurationLength.text = [NSString stringWithFormat:@"%@:%@",
                                                                                                            [self.numberFormatter stringFromNumber:minutes] ,[self.numberFormatter stringFromNumber:seconds]];
                                                                      [blockCell.thumbnail setImage:image];
                                                                      [blockCell.videoIcon setHidden:NO];
                                                                      [blockCell.videoGradient setHidden:NO];
                                                                  }
                                                                  [[blockCell.contentView viewWithTag:405] setHidden:YES];
                                                              }];
    }else{
        if ([item.URLString rangeOfString:@"assets-library"].location != NSNotFound && item.URLString) {
            [[MHGallerySharedManager sharedManager] getImageFromAssetLibrary:item.URLString assetType:MHAssetImageTypeThumb successBlock:^(UIImage *image, NSError *error) {
                cell.thumbnail.image = image;
            }];
        }else if(item.image){
            cell.thumbnail.image = item.image;
        }else{
            [cell.thumbnail setImageWithURL:[NSURL URLWithString:item.URLString]
                           placeholderImage:nil
                                    options:SDWebImageContinueInBackground
                                   progress:nil
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                      if (!image) {
                                          blockCell.thumbnail.backgroundColor = [UIColor whiteColor];
                                          blockCell.thumbnail.image = MHGalleryImage(@"error");
                                      }
                                      [[blockCell.contentView viewWithTag:405] setHidden:YES];
                                  }];
        }
    }
    cell.thumbnail.userInteractionEnabled =YES;
    
    MHIndexPinchGestureRecognizer *pinch = [[MHIndexPinchGestureRecognizer alloc]initWithTarget:self
                                                                                         action:@selector(userDidPinch:)];
    pinch.indexPath = indexPath;
    [cell.thumbnail addGestureRecognizer:pinch];
    
    UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc]initWithTarget:self
                                                                                      action:@selector(userDidRoate:)];
    rotate.delegate = self;
    [cell.thumbnail addGestureRecognizer:rotate];
    
    
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}


-(void)userDidRoate:(UIRotationGestureRecognizer*)recognizer{
    if (self.interactivePushTransition) {
        CGFloat angle = recognizer.rotation;
        self.interactivePushTransition.angle = angle;
    }
}
-(void)userDidPinch:(MHIndexPinchGestureRecognizer*)recognizer{

    CGFloat scale = recognizer.scale/5;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (recognizer.scale>1) {
            self.interactivePushTransition = [MHTransitionShowDetail new];
            self.interactivePushTransition.indexPath = recognizer.indexPath;
            self.lastPoint = [recognizer locationInView:self.view];
            MHGalleryImageViewerViewController *detail = [MHGalleryImageViewerViewController new];
            detail.galleryItems = self.galleryItems;
            detail.pageIndex = recognizer.indexPath.row;
            self.startScale = recognizer.scale/8;
            [self.navigationController pushViewController:detail
                                                 animated:YES];
        }else{
            [recognizer setCancelsTouchesInView:YES];
        }
    }else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        if (recognizer.numberOfTouches <2) {
            [recognizer setEnabled:NO];
            [recognizer setEnabled:YES];
        }
        
        CGPoint point = [recognizer locationInView:self.view];
        self.interactivePushTransition.scale = recognizer.scale/8-self.startScale;
        self.interactivePushTransition.changedPoint = CGPointMake(self.lastPoint.x - point.x, self.lastPoint.y - point.y) ;
        [self.interactivePushTransition updateInteractiveTransition:scale];
        self.lastPoint = point;
    }else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (scale > 0.5) {
            [self.interactivePushTransition finishInteractiveTransition];
        }else {
            [self.interactivePushTransition cancelInteractiveTransition];
        }
        self.interactivePushTransition = nil;
    }
    
}


- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if ([animationController isKindOfClass:[MHTransitionShowDetail class]]) {
        return self.interactivePushTransition;
    }else {
        return nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    
    if (fromVC == self && [toVC isKindOfClass:[MHGalleryImageViewerViewController class]]) {
        return [MHTransitionShowDetail new];
    }else {
        return nil;
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }
}
-(void)pushToImageViewerForIndexPath:(NSIndexPath*)indexPath{
    MHGalleryImageViewerViewController *detail = [MHGalleryImageViewerViewController new];
    detail.pageIndex = indexPath.row;
    detail.galleryItems = self.galleryItems;
    [self.navigationController pushViewController:detail animated:YES];
    
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    MHGalleryOverViewCell *cell = (MHGalleryOverViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    MHGalleryItem *item =  [self itemForIndex:indexPath.row];
    
    if ([item.URLString rangeOfString:@"assets-library"].location != NSNotFound && item.URLString) {
        
        [[MHGallerySharedManager sharedManager] getImageFromAssetLibrary:item.URLString
                                                               assetType:MHAssetImageTypeFull
                                                            successBlock:^(UIImage *image, NSError *error) {
                                                                cell.thumbnail.image = image;
                                                                [self pushToImageViewerForIndexPath:indexPath];
                                                            }];
    }else{
        [self pushToImageViewerForIndexPath:indexPath];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    MHGalleryItem *item =  [self itemForIndex:indexPath.row];
    if (item.galleryType == MHGalleryTypeImage) {
        if ([NSStringFromSelector(action) isEqualToString:@"copy:"] || [NSStringFromSelector(action) isEqualToString:@"saveImage:"]){
            return YES;
        }
    }
    return NO;
}

-(void)getImageForItem:(MHGalleryItem*)item
        finishCallback:(void(^)(UIImage *image))FinishBlock{
    [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:item.URLString]
                                               options:SDWebImageContinueInBackground
                                              progress:nil
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                 FinishBlock(image);
                                             }];
}


- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    if ([NSStringFromSelector(action) isEqualToString:@"copy:"]) {
        UIPasteboard *pasteBoard = [UIPasteboard pasteboardWithName:UIPasteboardNameGeneral create:NO];
        pasteBoard.persistent = YES;
        MHGalleryItem *item =  [self itemForIndex:indexPath.row];
        [self getImageForItem:item finishCallback:^(UIImage *image) {
            if (image) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                NSData *data = UIImagePNGRepresentation(image);
                [pasteboard setData:data forPasteboardType:@"public.jpeg"];
            }
        }];
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    self.collectionView.collectionViewLayout = [self layoutForOrientation:toInterfaceOrientation];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end
