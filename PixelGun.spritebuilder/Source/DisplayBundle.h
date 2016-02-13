//
//  DisplayBundle.h
//  PixelGun
//
//  Created by Andre Askarinam on 7/22/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface DisplayBundle : CCNode

@property int pictureIndex;

- (void)allowUserInteraction:(BOOL)allowed;
- (void)setStarBarVisible:(BOOL)visible;
- (void)animateDisplayBundleWithStars:(int)stars;

@end
