//
//  DisplayBundle.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/22/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "DisplayBundle.h"
#import "GameState.h"

@interface DisplayBundle ()
{
    GameState *_GameState;
    CCButton *_button;
    CCNode *_starBar;
}

@property int starsToDisplay;
@property int starsDisplayed;

@end

@implementation DisplayBundle

static const CGFloat STAR_SCALE = 0.5;

- (void)allowUserInteraction:(BOOL)allowed
{
    if (allowed) {
        _button.userInteractionEnabled = true;
    } else {
        _button.userInteractionEnabled = false;
    }
}

- (void)selectLevel {
    NSLog(@"Select Level");
    
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];
    
    _GameState = [GameState sharedCenter];
    
    // Save package index in resume as -1
    [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:-1] forKey:@"Package Index"];
    [_GameState writeToPlistInDocuments];
    
    if (self.pictureIndex != 999) {
        // Set accessed level to selected index
        _GameState.accessedLevelIndex = self.pictureIndex;
        
        // Bring gameplay scene
        [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
    }
}

- (void)setStarBarVisible:(BOOL)visible
{
    _starBar.visible = visible;
}

- (void)animateDisplayBundleWithStars:(int)stars
{
    self.starsDisplayed = 0;
    self.starsToDisplay = stars;
    
    [_starBar runAction:[CCActionSequence actions: [CCActionDelay actionWithDuration:0.2], [CCActionCallFunc actionWithTarget:self selector:@selector(loadStar)], [CCActionDelay actionWithDuration:0.2], [CCActionCallFunc actionWithTarget:self selector:@selector(loadStar)], [CCActionDelay actionWithDuration:0.2], [CCActionCallFunc actionWithTarget:self selector:@selector(loadStar)], nil]];
}

- (void)loadStar
{
    if (self.starsDisplayed < self.starsToDisplay) {
        CCSprite *star = (CCSprite *)[CCBReader load:@"Star"];
        star.position = ccp((0.38 * self.starsDisplayed + 0.12) * _starBar.contentSizeInPoints.width, 0.5 * _starBar.contentSizeInPoints.height);
        star.scale = STAR_SCALE;
        star.visible = false;
        [_starBar addChild:star];
        [star runAction:[CCActionSequence actions:[CCActionShow action], nil]];
        
        CCParticleSystem *particles = (CCParticleSystem *)[CCBReader load:@"Particle Effects/Small Burst Sparkles"];
        particles.position = star.position;
        [_starBar addChild:particles];
        
        OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
        [audio playEffect:@"Star Appear Small.wav"];
    }
    self.starsDisplayed++;
}

@end
