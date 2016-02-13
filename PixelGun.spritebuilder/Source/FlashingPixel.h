//
//  FlashingPixel.h
//  PixelGun
//
//  Created by Andre Askarinam on 7/11/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

@interface FlashingPixel : CCSprite {
    CCNodeColor *_flashingSquare;
}

- (void)setFlashingSquareSizeOf:(CGFloat)flashingSquareSize;


@end
