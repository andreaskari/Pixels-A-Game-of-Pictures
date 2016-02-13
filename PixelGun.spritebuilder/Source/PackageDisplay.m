//
//  PackageDisplay.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/21/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PackageDisplay.h"
#import "DisplayBundle.h"
#import "GameState.h"

@interface PackageDisplay ()
{
    GameState *_GameState;
    
    CCNodeColor *_colorNode;
    CCLabelTTF *_packageLabel;
    CCNode *_bundleContainer;
}

@end

@implementation PackageDisplay

static const CGFloat BORDER_WIDTH = 10.0;
static const CGFloat ICON_DIMENSIONS = 65.0;

-(void)didLoadFromCCB
{
    _GameState = [GameState sharedCenter];
    
    NSMutableDictionary *package = [[_GameState.data objectForKey:@"Packages"] objectAtIndex:_GameState.accessedPackageIndex];
    NSMutableArray *packageContents = [package objectForKey:@"Package Contents"];
    
    for (int i = 0; i < packageContents.count; i++) {
        // Create and position DisplayBundle for each level
        DisplayBundle *bundle = (DisplayBundle *)[CCBReader load:@"DisplayBundle"];
        
        CGFloat xPosition = ((i % 3) * 0.32 + 0.18) * (self.boundingBox.size.width - BORDER_WIDTH);
        CGFloat yPosition = ((i / 3) * -0.28 + 0.74) * (self.boundingBox.size.height - BORDER_WIDTH);
        bundle.position = ccp(xPosition, yPosition);
        
        CCSprite *icon;
        BOOL locked = [[[packageContents objectAtIndex:i] objectForKey:@"Locked"] boolValue];
        if (locked && i == [[package objectForKey:@"Levels Passed"] integerValue]) {
            // Load a question mark for next level that can be played
            icon = (CCSprite *)[CCBReader load:@"QuestionMark"];
            [bundle setStarBarVisible:NO];
            bundle.pictureIndex = i;
        } else if (!locked) {
            // Load the icon of already played levels
            NSString *imageName = [[packageContents objectAtIndex:i] objectForKey:@"Filename"];
            icon = [[CCSprite alloc] initWithImageNamed:[NSString stringWithFormat:@"%@.png", imageName]];
            
            CGFloat scaleFactor;
            if (icon.boundingBox.size.width > icon.boundingBox.size.height) {
                scaleFactor = ICON_DIMENSIONS / icon.boundingBox.size.width;
            } else {
                scaleFactor = ICON_DIMENSIONS / icon.boundingBox.size.height;
            }
            [icon.texture setAntialiased:NO];
            icon.scale = scaleFactor;
            
            [bundle animateDisplayBundleWithStars:[[[packageContents objectAtIndex:i] objectForKey:@"Stars"] intValue]];
            
            bundle.pictureIndex = i;
        } else {
            // Load a lock for locked levels
            icon = (CCSprite *)[CCBReader load:@"Lock"];
            [bundle allowUserInteraction:NO];
            [bundle setStarBarVisible:NO];
            bundle.pictureIndex = 999;
        }
        
        icon.anchorPoint = ccp(0.5, 0.5);
        [bundle addChild:icon];
        
        // Add DisplayBundle to display
        [_bundleContainer addChild:bundle];
    }
    
    // Save to plist
    [_GameState writeToPlistInDocuments];
}

- (void)setBackgroundColorTo:(CCColor *)color
{
    _colorNode.color = color;
}

- (void)setPackageLabel:(NSString *)packageName
{
    _packageLabel.string = packageName;
}

- (void)exitDisplay
{
    CCNode *displayContainer = [self parent];
    [self removeFromParent];
    
    CCNode *tileContainer = [[displayContainer children] objectAtIndex:0];
    tileContainer.visible = true;
    
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Click.wav"];
}

@end
