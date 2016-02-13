//
//  PackageScene.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/17/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PackageScene.h"
#import "PackageMessageMenu.h"
#import "PackageResumeMenu.h"
#import "PackageTile.h"
#import "GameState.h"

@interface PackageScene () {
    GameState *_GameState;
    CCNode *_resumeContainer;
    CCNode *_displayContainer;
    CCNode *_tileContainer;
    CCLabelTTF *_coinLabel;
    CCButton *_resumeButton;
}

@property NSValue *startTouch;
@property NSValue *lastTouch;
@property int currentTileIndex;
@property BOOL movedOutOfBounds;

@property int nondiplayedCoins;

@property BOOL allowBounce;

@end

@implementation PackageScene

// For package tile layout (also found in PackageTile)
static const CGFloat percentHeight = 0.45;
static const CGFloat percentWidth = 0.50;
static const CGFloat percentSpace = 1.2;

static const CGFloat TILE_WIDTH = 200;

// For package tile
static const CGFloat tileHeight = 300.0;
static const CGFloat tileWidth = 200.0;

static const CCTime DURATION_OF_ACTION = 0.2;
static const CGFloat TAP_DISTANCE = 10.0;

static const CCTime COIN_LOAD_DURATION = 0.001;

#pragma mark Tile/Display Handling Methods

- (void)didLoadFromCCB
{
    _GameState = [GameState sharedCenter];
    
    // Allow touch interaction
    self.userInteractionEnabled = TRUE;
    
    // Allow pack interaction
    _GameState.packMovementEnabled = true;
    
    // For touch interaction
    self.packageTiles = [NSMutableArray array];
    self.currentTileIndex = _GameState.accessedPackageIndex;
    self.allowBounce = YES;
    
    for (int i = 0; i < [[_GameState.data objectForKey:@"Packages"] count]; i++) {
        // Create and position tile
        PackageTile *tile = (PackageTile *)[CCBReader load:@"PackageTile"];
        tile.position = ccp([[CCDirector sharedDirector]viewSize].width * percentWidth, [[CCDirector sharedDirector]viewSize].height * percentHeight);
        tile.packageIndex = i;
        
        // Set tile color
        NSArray *colors = [[[_GameState.data objectForKey:@"Packages"] objectAtIndex:i] objectForKey:@"Tile Colors"];
        tile.tileColor = [CCColor colorWithRed:[[colors objectAtIndex:0] integerValue] / 255.000
                                         green:[[colors objectAtIndex:1] integerValue] / 255.000
                                          blue:[[colors objectAtIndex:2] integerValue] / 255.000];
        [tile setBackgroundColorTo:tile.tileColor];
        
        // Set tile name and locked
        NSMutableDictionary *package = [[_GameState.data objectForKey:@"Packages"] objectAtIndex:i];
        [tile setPackageName:[package objectForKey:@"Package Name"]];
        [tile setPackageLocked:[[package objectForKey:@"Locked"] boolValue] withTokenPrice:[[package objectForKey:@"Package Price"] intValue]];
        [self.packageTiles addObject:tile];
        
        // Set tile icon
        NSString *iconName = [NSString stringWithFormat:@"%@.png", [[[package objectForKey:@"Package Contents"] objectAtIndex:0] objectForKey:@"Filename"]];
        [tile setTileIcon:[CCSprite spriteWithImageNamed:iconName]];
        
        // Add to tileContainer
        [_tileContainer addChild:tile];
    }
    
    // Load coins
    _coinLabel.string = [NSString stringWithFormat:@"%i", [[_GameState.data objectForKey:@"Displayed Coins"] intValue]];
    _GameState.displayedCoins = [[_GameState.data objectForKey:@"Displayed Coins"] intValue];
    
    if ([[_GameState.data objectForKey:@"Nondisplayed Coins"] intValue] > 0) {
        self.nondiplayedCoins = [[_GameState.data objectForKey:@"Nondisplayed Coins"] intValue];
        [_GameState addNondisplayedCoinsToDisplayed];
    }
    [self schedule:@selector(updateCoins:) interval:COIN_LOAD_DURATION];
    
    // Display resume button if there is a level to resume
    if ([[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Package Index"] intValue] < 0) {
        _resumeButton.visible = false;
    } else {
        _resumeButton.visible = true;
    }
}

- (void)onEnter
{
    [super onEnter];
    
    // Place accessed pack (tile) on top
    PackageTile *topTile = [self.packageTiles objectAtIndex:_GameState.accessedPackageIndex];
    [_tileContainer removeChild:topTile];
    [_tileContainer addChild:topTile];
    
    // Move all tiles to their locations
    for (int i = 0; i < self.packageTiles.count; i++) {
        PackageTile *tile = [self.packageTiles objectAtIndex:i];
        CCAction *moveTile = [CCActionMoveTo actionWithDuration:0.5 position:ccp([[CCDirector sharedDirector]viewSize].width * percentWidth + (i - _GameState.accessedPackageIndex) * percentSpace * TILE_WIDTH, [[CCDirector sharedDirector]viewSize].height * percentHeight)];
        [tile runAction:moveTile];
    }
}

- (void)updateCoins:(CCTime)delta
{
    if (self.nondiplayedCoins > 0 && _GameState.coinsForRemoval > 0) {
        if (self.nondiplayedCoins > _GameState.coinsForRemoval) {
            self.nondiplayedCoins -= _GameState.coinsForRemoval;
            _GameState.coinsForRemoval = 0;
        } else {
            _GameState.coinsForRemoval -= self.nondiplayedCoins;
            self.nondiplayedCoins = 0;
        }
    }
    
    // If there are coins to add, add them
    if (self.nondiplayedCoins > 0) {
        _GameState.displayedCoins++;
        self.nondiplayedCoins--;
        _coinLabel.string = [NSString stringWithFormat:@"%i", _GameState.displayedCoins];
    }
    
    // If purchased a pack, remove coins
    if (_GameState.coinsForRemoval > 0 && self.visible) {
        _GameState.displayedCoins--;
        _GameState.coinsForRemoval--;
        _coinLabel.string = [NSString stringWithFormat:@"%i", _GameState.displayedCoins];
    }
    
    // Unlock package immediately if purchased
    if (_GameState.unlockPackageIndex >= 0) {
        [[self.packageTiles objectAtIndex:_GameState.unlockPackageIndex] unlockPackageVisually];
        _GameState.unlockPackageIndex = -1;
    }
}

#pragma mark Scroll/Swipe Methods

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_tileContainer.visible && _GameState.packMovementEnabled) {
        self.startTouch = [NSValue valueWithCGPoint:touch.locationInWorld];
        self.lastTouch = [NSValue valueWithCGPoint:touch.locationInWorld];
    }
}

-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_tileContainer.visible && _GameState.packMovementEnabled) {
        for (int i = 0; i < self.packageTiles.count; i++) {
            PackageTile *tile = [self.packageTiles objectAtIndex:i];
            tile.positionInPoints = ccp(touch.locationInWorld.x - [self.lastTouch CGPointValue].x + tile.positionInPoints.x, tile.positionInPoints.y);
        }
        
        self.lastTouch = [NSValue valueWithCGPoint:touch.locationInWorld];
    }
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Don't do anything if tiles aren't visible or packs movement disabled
    if (!_tileContainer.visible || !_GameState.packMovementEnabled) {
        return;
    }
    
    // If they just tap, load menu
    if (fabs(touch.locationInWorld.x - [self.startTouch CGPointValue].x) <= TAP_DISTANCE && fabs(touch.locationInWorld.y - [self.startTouch CGPointValue].y <= TAP_DISTANCE)) {
        NSLog(@"Tap: (%g, %g)", touch.locationInWorld.x - [self.startTouch CGPointValue].x, touch.locationInWorld.y - [self.startTouch CGPointValue].y);
        
        // Find out if tap on tile
        if (touch.locationInWorld.x < [[CCDirector sharedDirector]viewSize].width * percentWidth + tileWidth / 2 &&
            touch.locationInWorld.x > [[CCDirector sharedDirector]viewSize].width * percentWidth - tileWidth / 2 &&
            touch.locationInWorld.y < [[CCDirector sharedDirector]viewSize].height * percentHeight + tileHeight / 2 &&
            touch.locationInWorld.y > [[CCDirector sharedDirector]viewSize].height * percentHeight - tileHeight / 2)
        {
            // If not locked, generate display and display it
            BOOL locked = [[[[_GameState.data objectForKey:@"Packages"] objectAtIndex:self.currentTileIndex] objectForKey:@"Locked"] boolValue];
            if (!locked) {
                PackageTile *currentTile = [self.packageTiles objectAtIndex:self.currentTileIndex];
                [currentTile selectPackageForDisplay];
                
                OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
                [audio playEffect:@"Tap.wav"];
            } else {
                int packagePrice = [[[[_GameState.data objectForKey:@"Packages"] objectAtIndex:self.currentTileIndex] objectForKey:@"Package Price"] intValue];
                if (packagePrice <= [[_GameState.data objectForKey:@"Displayed Coins"] intValue]) {
                    // If locked and has enough coins, generate message
                    PackageTile *currentTile = [self.packageTiles objectAtIndex:self.currentTileIndex];
                    [currentTile selectPackageForMenu];
                    
                    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
                    [audio playEffect:@"Tap.wav"];
                    
                } else {
                    // Bounce up and down if not enough coins to buy pack
                    if (self.allowBounce) {
                        self.allowBounce = NO;
                        PackageTile *currentTile = [self.packageTiles objectAtIndex:self.currentTileIndex];
                        CGPoint tileLocation = ccp([[CCDirector sharedDirector]viewSize].width * percentWidth, [[CCDirector sharedDirector]viewSize].height * percentHeight);
                        CCActionSequence *bounceSequence = [CCActionSequence actions:[CCActionMoveTo actionWithDuration:0.2 position:ccp(tileLocation.x, tileLocation.y + 20.0)], [CCActionMoveTo actionWithDuration:0.2 position:tileLocation], [CCActionMoveTo actionWithDuration:0.1 position:ccp(tileLocation.x, tileLocation.y + 10.0)], [CCActionMoveTo actionWithDuration:0.2 position:tileLocation], [CCActionDelay actionWithDuration:0.1], [CCActionCallFunc actionWithTarget:self selector:@selector(enableBounce)], nil];
                        [currentTile runAction:bounceSequence];
                        
                        OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
                        [audio playEffect:@"Tap Error.wav"];
                    }
                }
            }
        }
        
        // Move back slightly
        for (int i = 0; i < self.packageTiles.count; i++) {
            PackageTile *tile = [self.packageTiles objectAtIndex:i];
            CCAction *moveBackSlightly = [CCActionMoveTo actionWithDuration:0.2 position:ccp([[CCDirector sharedDirector]viewSize].width * percentWidth + (i - self.currentTileIndex) * percentSpace * TILE_WIDTH, [[CCDirector sharedDirector]viewSize].height * percentHeight)];
            [tile runAction:moveBackSlightly];
        }
        
        return;
    }
    
    // Runs if this isn't a tap
    int closestTileIndex = 0;
    PackageTile *firstTile = [self.packageTiles objectAtIndex:0];
    CGFloat lastTileDistanceFromMiddle = fabs([[CCDirector sharedDirector]viewSize].width / 2 - (firstTile.position.x + firstTile.boundingBox.size.width / 2));
    for (int i = 1; i < self.packageTiles.count; i++) {
        PackageTile *tile = [self.packageTiles objectAtIndex:i];
        if (fabs([[CCDirector sharedDirector]viewSize].width / 2 - (tile.position.x + tile.boundingBox.size.width / 2)) < lastTileDistanceFromMiddle) {
            lastTileDistanceFromMiddle = fabs([[CCDirector sharedDirector]viewSize].width / 2 - (tile.position.x + tile.boundingBox.size.width / 2));
            closestTileIndex = i;
        }
    }
    
    // If its a swipe, then shift over tiles
    if (self.currentTileIndex == closestTileIndex) {
        // Swipe all tiles to the left
        if (touch.locationInWorld.x - [self.startTouch CGPointValue].x > 0 && self.currentTileIndex != 0) {
            [self swipeInDirection:@"Left" withDistanceMoved:lastTileDistanceFromMiddle];
            self.currentTileIndex--;
        // Swipe all tiles to the right
        } else if (touch.locationInWorld.x - [self.startTouch CGPointValue].x < 0 && self.currentTileIndex != self.packageTiles.count - 1) {
            [self swipeInDirection:@"Right" withDistanceMoved:lastTileDistanceFromMiddle];
            self.currentTileIndex++;
        // If on first tile and scrolls left, move back right
        } else if (self.currentTileIndex == 0 && touch.locationInWorld.x - [self.startTouch CGPointValue].x > 0) {
            NSLog(@"Scroll back up");
            for (int i = 0; i < self.packageTiles.count; i++) {
                PackageTile *tile = [self.packageTiles objectAtIndex:i];
                CGPoint moveLocation = ccp(tile.position.x - (touch.locationInWorld.x - [self.startTouch CGPointValue].x), tile.position.y);
                CCAction *move = [CCActionMoveTo actionWithDuration:DURATION_OF_ACTION position:moveLocation];
                [tile runAction:move];
            }
        // If on last tile and scrolls right, move back left
        } else if (self.currentTileIndex == self.packageTiles.count - 1 && touch.locationInWorld.x - [self.startTouch CGPointValue].x < 0) {
            NSLog(@"Scroll back down");
            for (int i = 0; i < self.packageTiles.count; i++) {
                PackageTile *tile = [self.packageTiles objectAtIndex:i];
                CGPoint moveLocation = ccp(tile.position.x - (touch.locationInWorld.x - [self.startTouch CGPointValue].x), tile.position.y);
                CCAction *move = [CCActionMoveTo actionWithDuration:DURATION_OF_ACTION position:moveLocation];
                [tile runAction:move];
            }
        }
    } else {
        // If its a scroll, then go to the nearest tile
        BOOL increaseCurrentTile;
        NSLog(@"Scroll");
        for (int i = 0; i < self.packageTiles.count; i++) {
            PackageTile *tile = [self.packageTiles objectAtIndex:i];
            CGPoint moveLocation = ccp([[CCDirector sharedDirector]viewSize].width* 1.0 / 2 + percentSpace * TILE_WIDTH * (i - closestTileIndex), tile.position.y);
            if (moveLocation.x - (tile.positionInPoints.x + tile.boundingBox.size.width / 2) > 0) {
                increaseCurrentTile = false;
            } else if (moveLocation.x - (tile.positionInPoints.x + tile.boundingBox.size.width / 2) < 0) {
                increaseCurrentTile = true;
            }
            CCAction *move = [CCActionMoveTo actionWithDuration:DURATION_OF_ACTION / 2 position:moveLocation];
            [tile runAction:move];
        }
        if (increaseCurrentTile) {
            self.currentTileIndex++;
        } else {
            self.currentTileIndex--;
        }
    }
    
    if (abs(closestTileIndex - self.currentTileIndex) > 1) {
        NSLog(@"ERROR");
    }
    NSLog(@"Closest Tile: %i\nCurrent Tile: %i\nNet Distance: %g\n", closestTileIndex, self.currentTileIndex, touch.locationInWorld.x - [self.startTouch CGPointValue].x);
    
    //self.currentTileIndex = closestTileIndex;
}

- (void)swipeInDirection:(NSString *)swipeDirection withDistanceMoved:(CGFloat)distance {
    for (int i = 0; i < self.packageTiles.count; i++) {
        PackageTile *tile = [self.packageTiles objectAtIndex:i];
        CGPoint moveLocation;
        if ([swipeDirection isEqualToString:@"Right"]) {
            moveLocation = ccp(tile.positionInPoints.x - (TILE_WIDTH * percentSpace - distance), tile.positionInPoints.y);
        } else if ([swipeDirection isEqualToString:@"Left"]) {
            moveLocation = ccp(tile.positionInPoints.x + (TILE_WIDTH * percentSpace - distance), tile.positionInPoints.y);
        }
        CCAction *move = [CCActionMoveTo actionWithDuration:DURATION_OF_ACTION position:moveLocation];
        [tile runAction:move];
    }
    NSLog(@"Swipe %@", swipeDirection);
}

#pragma mark Button Selector Methods

- (void)loadResumeMenu
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];

    _displayContainer.visible = false;
    _resumeButton.enabled = false;
    
    PackageResumeMenu *resumeMenu = (PackageResumeMenu *)[CCBReader load:@"PackageResumeMenu"];
    resumeMenu.position = ccp([[CCDirector sharedDirector]viewSize].width * percentWidth, [[CCDirector sharedDirector]viewSize].height * percentHeight);
    NSArray *backgroundRGB = [[[_GameState.data objectForKey:@"Packages"] objectAtIndex:[[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Package Index"] intValue]] objectForKey:@"Tile Colors"];
    [resumeMenu setBackgroundColorTo:[CCColor colorWithRed:[[backgroundRGB objectAtIndex:0] doubleValue] / 255.0 green:[[backgroundRGB objectAtIndex:1] doubleValue] / 255.0 blue:[[backgroundRGB objectAtIndex:2] doubleValue] / 255.0]];
    
    [resumeMenu updateResumePixelContainerDimensions];
    [resumeMenu loadDisplayedPixels];
    
    [_resumeContainer addChild:resumeMenu];
}

//- (void)back
//{
//    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"MainScene"]];
//}

#pragma mark Animation Selector Methods

- (void)enableBounce
{
    self.allowBounce = YES;
}

@end
