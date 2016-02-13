//
//  PackageResumeMenu.m
//  PixelGun
//
//  Created by Andre Askarinam on 8/14/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PackageResumeMenu.h"
#import "GameState.h"
#import "Pixel.h"

@interface PackageResumeMenu () {
    GameState *_GameState;
    CCNodeColor *_colorNode;
    CCNodeColor *_resumePixelContainer;
}

@property CGFloat pixelSize;

@end

@implementation PackageResumeMenu

// For Resume Pixel Container
static const CGFloat DISTANCE_FROM_CONTAINER_WALLS = 5.0;

- (void)resume
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];
    
    [_resumePixelContainer removeAllChildren];
    
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

- (void)replay
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];
    
    // Save package index in resume as -1
    [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:-1] forKey:@"Package Index"];
    [_GameState writeToPlistInDocuments];
    
    [_resumePixelContainer removeAllChildren];
    
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

- (void)exitResumeMenu
{
    CCNode *resumeContainer = [self parent];
    [self removeFromParent];
    
    CCNode *displayContainer = [[resumeContainer children] objectAtIndex:0];
    displayContainer.visible = true;
    
    CCButton *resumeButton = [[[[[resumeContainer parent] children] objectAtIndex:0] children] objectAtIndex:0];
    resumeButton.enabled = true;
    
    [_resumePixelContainer removeAllChildren];
    
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Click.wav"];
}

- (void)setBackgroundColorTo:(CCColor *)color
{
    _colorNode.color = color;
}

- (void)updateResumePixelContainerDimensions
{
    _GameState = [GameState sharedCenter];
    
    self.pixelSize = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Pixel Size"] doubleValue];
    
    CGFloat width = self.pixelSize * [[[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Picture Dimensions"] objectAtIndex:0] intValue] + DISTANCE_FROM_CONTAINER_WALLS * 2;
    CGFloat height = self.pixelSize * [[[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Picture Dimensions"] objectAtIndex:1] intValue] + DISTANCE_FROM_CONTAINER_WALLS * 2;
    CGSize newContainerSize = CGSizeMake(width, height);
    [_resumePixelContainer setContentSizeInPoints:newContainerSize];
}

- (void)loadDisplayedPixels
{
    // Load all pixels that have been played already
    for (int i = 0; i < [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Pixels Displayed"] intValue]; i++) {
        Pixel *pixelToAdd = [[NSKeyedUnarchiver unarchiveObjectWithData:[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Shuffled Pixels"]] objectAtIndex:i];
        CGFloat pixelSize = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Pixel Size"] doubleValue];
        int pictureWidth = [[[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Picture Dimensions"] objectAtIndex:0] doubleValue];
        int pictureHeight = [[[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Picture Dimensions"] objectAtIndex:1] doubleValue];
        CCNodeColor *square = [CCNodeColor nodeWithColor:[CCColor colorWithRed:pixelToAdd.red green:pixelToAdd.green blue:pixelToAdd.blue] width:pixelSize height:pixelSize];
        square.positionInPoints = [pixelToAdd getPositionWithPixelSize:pixelSize pictureWidth:pictureWidth pictureHeight:pictureHeight];
        [_resumePixelContainer addChild:square];
    }
}

@end
