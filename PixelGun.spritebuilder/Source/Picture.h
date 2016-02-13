//
//  Picture.h
//  PixelGun
//
//  Created by Andre Askarinam on 7/5/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "Pixel.h"

@interface Picture : CCNode

@property UIImage *originalPicture;
@property NSMutableArray *pixelsLayout;
@property NSMutableArray *shuffledPixels;
@property int width;
@property int height;
@property double pixelSize;

- (instancetype)initWithUIImage:(UIImage *)picture andGenerateShuffledPixels:(BOOL)generateShuffledPixels;
- (void)getPictureDataWithPixelsLayout:(BOOL)generatePixelLayoutArray;

@end
