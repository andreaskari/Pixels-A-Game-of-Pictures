//
//  PackageTile.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/17/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PackageTile.h"
#import "GameState.h"
#import "PackageScene.h"

@interface PackageTile ()
{
    GameState *_GameState;
    
    CCNodeColor *_colorNode;
    CCLabelTTF *_packageLabel;
    CCLabelTTF *_priceLabel;
    CCNodeColor *_tintNode;
}

@end

@implementation PackageTile

// For package tile layout (also found in PackageScene)
static const CGFloat percentHeight = 0.45;
static const CGFloat percentWidth = 0.50;

static const CGFloat TILE_ICON_SIZE = 140;

- (void)setPackageName:(NSString *)name
{
    _packageLabel.string = name;
}

- (void)setPackageLocked:(BOOL)locked withTokenPrice:(int)price
{
    if (locked) {
        _priceLabel.string = [NSString stringWithFormat: @"%i Coins",price];
        [self setPackageTinted:YES];
    } else {
        _priceLabel.visible = false;
        [self setPackageTinted:NO];
        
        // Add sparkles if not played yet
        _GameState = [GameState sharedCenter];
        if ([[[[[[_GameState.data objectForKey:@"Packages"] objectAtIndex:self.packageIndex] objectForKey:@"Package Contents"] objectAtIndex:0] objectForKey:@"Locked"] boolValue]) {
            CCParticleSystem *sparkles = (CCParticleSystem *)[CCBReader load:@"Tile Sparkles"];
            [self addChild:sparkles];
        }
    }
}

- (void)setPackageTinted:(BOOL)tinted
{
    if (tinted) {
        _tintNode.visible = true;
    } else {
        _tintNode.visible = false;
    }
}

- (void)setBackgroundColorTo:(CCColor *)color
{
    _colorNode.color = color;
}

- (void)setTileIcon:(CCSprite *)icon
{
    icon.anchorPoint = ccp(0.5, 0.5);
    icon.position = ccp(0.5 * _colorNode.boundingBox.size.width, 0.46 * _colorNode.boundingBox.size.height);
    
    CGFloat scaleFactor;
    if (icon.boundingBox.size.width > icon.boundingBox.size.height) {
        scaleFactor = TILE_ICON_SIZE / icon.boundingBox.size.width;
    } else {
        scaleFactor = TILE_ICON_SIZE / icon.boundingBox.size.height;
    }
    [icon.texture setAntialiased:NO];
    icon.scale = scaleFactor;
    
    [_colorNode addChild:icon];
}

- (void)selectPackageForDisplay
{
    // Set accessed package index and its actual dictionary
    _GameState = [GameState sharedCenter];
    _GameState.accessedPackageIndex = self.packageIndex;
    _GameState.accessedPackage = [[_GameState.data objectForKey:@"Packages"] objectAtIndex:_GameState.accessedPackageIndex];
    
    PackageDisplay *display = (PackageDisplay *)[CCBReader load:@"PackageDisplay"];
    display.position = ccp([[CCDirector sharedDirector]viewSize].width * percentWidth, [[CCDirector sharedDirector]viewSize].height * percentHeight);
    [display setBackgroundColorTo:self.tileColor];
    [display setPackageLabel:_packageLabel.string];
    self.display = display;
    
    // Add to _container in PackageScene, make _iconContainer in PackageScene invisible
    CCNode *tileContainer = [self parent];
    CCNode *container = [tileContainer parent];
    [container addChild:self.display];
    tileContainer.visible = false;
}

- (void)selectPackageForMenu
{
    _GameState = [GameState sharedCenter];
    NSMutableDictionary *package = [[_GameState.data objectForKey:@"Packages"] objectAtIndex:self.packageIndex];
    
    PackageMessageMenu *menu = (PackageMessageMenu *)[CCBReader load:@"PackageMessageMenu"];
    [menu setBackgroundColorTo:self.tileColor];
    [menu setMenuMessageAndPackageName:[package objectForKey:@"Package Name"]];
    menu.packagePrice = [[package objectForKey:@"Package Price"] intValue];
    menu.position = ccp(0.5 * [[CCDirector sharedDirector]viewSize].width, 0.5 * [[CCDirector sharedDirector]viewSize].height);
    menu.packageIndexToUnlock = self.packageIndex;
    self.menu = menu;
    
    CCNode *tileContainer = [self parent];
    CCNodeColor *container = (CCNodeColor *)[tileContainer parent];
    [container addChild:self.menu];
    self.menu.scale = 0.0;
    CCAction *menuScaleIn = [CCActionScaleTo actionWithDuration:0.2 scale:1.0];
    [self.menu runAction:menuScaleIn];
    
    _GameState.packMovementEnabled = false;
}

- (void)unlockPackageVisually
{
    _priceLabel.visible = false;
    
    // Fade away tint
    CCAction *fadeAwayTint = [CCActionFadeTo actionWithDuration:0.5 opacity:0.0];
    [_tintNode runAction:fadeAwayTint];
    
    // Add particle effects
    CCParticleSystem *sparkles = (CCParticleSystem *)[CCBReader load:@"Tile Sparkles"];
    CCParticleSystem *burst = (CCParticleSystem *)[CCBReader load:@"Large Burst Sparkles"];
    [self addChild:sparkles];
    [self addChild:burst];
}

@end
