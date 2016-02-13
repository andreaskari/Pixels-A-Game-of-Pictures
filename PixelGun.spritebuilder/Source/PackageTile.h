//
//  PackageTile.h
//  PixelGun
//
//  Created by Andre Askarinam on 7/17/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"
#import "PackageMessageMenu.h"
#import "PackageDisplay.h"

@interface PackageTile : CCNode

@property int packageIndex;
@property PackageDisplay *display;
@property PackageMessageMenu *menu;

@property CCColor *tileColor;

- (void)setPackageName:(NSString *)name;
- (void)setPackageLocked:(BOOL)locked withTokenPrice:(int)tokenPrice;
- (void)setBackgroundColorTo:(CCColor *)color;
- (void)setTileIcon:(CCSprite *)icon;

- (void)selectPackageForDisplay;
- (void)selectPackageForMenu;

- (void)unlockPackageVisually;

@end
