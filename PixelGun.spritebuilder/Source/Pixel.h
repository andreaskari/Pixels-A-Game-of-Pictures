//
//  Pixel.h
//  PixelGun
//
//  Created by Andre Askarinam on 7/5/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface Pixel : NSObject <NSCoding>

@property CGFloat red;
@property CGFloat green;
@property CGFloat blue;

@property int x;
@property int y;

- (CGPoint)getPositionWithPixelSize:(CGFloat)pixelSize pictureWidth:(int)width pictureHeight:(int)height;

@end
