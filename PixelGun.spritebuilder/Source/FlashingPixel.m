//
//  FlashingPixel.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/11/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "FlashingPixel.h"

@implementation FlashingPixel

- (void)setFlashingSquareSizeOf:(CGFloat)flashingSquareSize
{
    _flashingSquare.contentSize = CGSizeMake(flashingSquareSize * 1.02, flashingSquareSize);
}

@end
