//
//  PackageMessageMenu.h
//  PixelGun
//
//  Created by Andre Askarinam on 7/30/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface PackageMessageMenu : CCNode

@property int packageIndexToUnlock;
@property int packagePrice;

- (void)setBackgroundColorTo:(CCColor *)color;
- (void)setMenuMessageAndPackageName:(NSString *)packageName;

@end
