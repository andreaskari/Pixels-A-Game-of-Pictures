//
//  Pixel.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/5/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Pixel.h"

@implementation Pixel

// For Pixel Container
static const CGFloat DISTANCE_FROM_CONTAINER_WALLS = 5.0;

- (CGPoint)getPositionWithPixelSize:(CGFloat)pixelSize pictureWidth:(int)width pictureHeight:(int)height
{
    return CGPointMake(self.x * pixelSize + DISTANCE_FROM_CONTAINER_WALLS, (height - self.y - 1) * pixelSize + DISTANCE_FROM_CONTAINER_WALLS);
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.x = [decoder decodeInt32ForKey:@"x"];
        self.y = [decoder decodeInt32ForKey:@"y"];
        self.red = [decoder decodeDoubleForKey:@"red"];
        self.green = [decoder decodeDoubleForKey:@"green"];
        self.blue = [decoder decodeDoubleForKey:@"blue"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:self.x forKey:@"x"];
    [encoder encodeInt:self.y forKey:@"y"];
    [encoder encodeDouble:self.red forKey:@"red"];
    [encoder encodeDouble:self.green forKey:@"green"];
    [encoder encodeDouble:self.blue forKey:@"blue"];
}

@end
