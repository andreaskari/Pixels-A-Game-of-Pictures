//
//  PackageResumeMenu.h
//  PixelGun
//
//  Created by Andre Askarinam on 8/14/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface PackageResumeMenu : CCNode

- (void)setBackgroundColorTo:(CCColor *)color;
- (void)updateResumePixelContainerDimensions;
- (void)loadDisplayedPixels;

@end
