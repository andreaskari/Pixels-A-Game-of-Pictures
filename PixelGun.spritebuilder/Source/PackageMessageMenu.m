//
//  PackageMessageMenu.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/30/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PackageMessageMenu.h"
#import "GameState.h"

@interface PackageMessageMenu () {
        GameState *_GameState;
        CCNodeColor *_colorNode;
        CCLabelTTF *_messageLabel;
}

@property NSString *packageName;

@end

@implementation PackageMessageMenu

- (void)setBackgroundColorTo:(CCColor *)color
{
    _colorNode.color = color;
}

- (void)setMenuMessageAndPackageName:(NSString *)packageName
{
    _messageLabel.string = [NSString stringWithFormat:@"Purchase %@?", packageName];
    
    // Store packageName for Analytics
    self.packageName = packageName;
}

- (void)purchase
{
    // Do transaction
    _GameState = [GameState sharedCenter];
    [_GameState.data setValue:[NSNumber numberWithInt:self.packagePrice] forKey:@"Coins For Removal"];
    _GameState.coinsForRemoval = self.packagePrice;
    [_GameState subtractRemovalCoinsFromDisplayed];
    
    // Unlock package
    [[[_GameState.data objectForKey:@"Packages"] objectAtIndex:self.packageIndexToUnlock] setObject:@NO forKey:@"Locked"];
    _GameState.unlockPackageIndex = self.packageIndexToUnlock;
    
    [_GameState writeToPlistInDocuments];

    // ANALYTICS: Purchased pack
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: self.packageName, @"pack",  nil];
    NSLog(@"Purchased %@", self.packageName);
    [MGWU logEvent:@"purchasedPack" withParams:params];
    
    // Allow pack movement
    _GameState.packMovementEnabled = true;
    
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Sparkle Chimes.wav"];
    
    [self removeFromParent];
}

- (void)cancel
{
    // Allow pack movement
    _GameState = [GameState sharedCenter];
    _GameState.packMovementEnabled = true;
    
    [self removeFromParent];
    
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Click.wav"];
}

@end
