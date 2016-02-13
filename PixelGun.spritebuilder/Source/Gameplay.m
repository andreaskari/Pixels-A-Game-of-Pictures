 //
//  Gameplay.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/5/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "GameState.h"
#import "Picture.h"
#import "Pixel.h"
#import "FlashingPixel.h"
#import "PlayingPixel.h"
#import "CCPhysics+ObjectiveChipmunk.h"

@interface Gameplay ()
{
    GameState *_GameState;
    CCScene *_gameplayScene;
    CCNodeGradient *_gradientNode;
    CCNode *_gameplayContainer;
    CCNode *_pauseMenuContainer;
    CCNode *_nextLevelMenuContainer;
    CCSprite *_platformSprite;
    CCNodeColor *_timerNode;
    CCPhysicsNode *_physicsNode;
    CCNodeColor *_pixelContainer;
    CCLabelTTF *_endLevelLabel;
    CCNode *_starBar;
    CCSprite *_coinSprite;
    CCLabelTTF *_coinLabel;
    CCNode *_pixelBar;
    CCNode *_playingPixelMarkerNode;
    CCNode *_flashingPixelMarkerNode;
    
    CCButton *_nextLevelButton;
    CCButton *_packsButton;
    CCButton *_finishButton;
    
    CCNode *_finishedLevelNode;
    CCNode *_finishedPackNode;
}

// For gameplay
@property Picture *currentPicture;
@property int numPixelsDisplayed;
@property NSString *backgroundColor;
@property NSMutableArray *pixelBarContents;
@property NSMutableArray *starBarContents;
@property PlayingPixel *playingPixel;
@property FlashingPixel *flashingSprite;

@property BOOL collisionHappened;
@property BOOL runEndOfPlay;

@property NSValue *startTouch;

@property CGFloat angleActual;
@property CGFloat anglePerfect;
@property CGFloat angleIncrement;

@property BOOL timerEnabled;
@property BOOL alreadyShot;

// For debugging
@property int debugIntervals;

// For stars
@property int missedPixelCount;
@property int stars;
@property int loadedStars;

// For coins & bonus coins
@property BOOL coinSounded;
@property int loadedCoins;
@property int coins;
@property int burstStarsForBonus;
@property int loadedBonusCoins;
@property int bonusCoins;

// For streaks and awards
@property int streak;
@property int awardPixels;
@property BOOL alreadyAwarded;

// For tutorial
@property int tutorialLevel;
@property int tutorialStepIndex;
@property CCSprite *step;
@property BOOL stepLoaded;
@property BOOL finishedActionForStep;
@property CCSprite *swipeAnimation;
@property CGFloat durationLookedAtStep;
@property CGFloat timeLookingAtStep;

// For bar location
@property BOOL barOnTheRight;

@end

@implementation Gameplay

// For Pixel Container
static const CGFloat DISTANCE_FROM_CONTAINER_WALLS = 5.0;

// For Pixel Bar
static const CGFloat DISTANCE_FROM_BAR_WALLS = 8.0;
static const CGFloat PIXEL_SIZE_IN_BAR = (30.0 - 2 * DISTANCE_FROM_BAR_WALLS);
static const int NUM_PIXELS_HELD_IN_BAR = (int) ((80.0 - DISTANCE_FROM_BAR_WALLS) / PIXEL_SIZE_IN_BAR) + 1;
static const CGFloat PIXELBAR_HEIGHT = 0.08;

// For Playing Pixel
static const CGFloat PLAYING_PIXEL_WIDTH = 0.5;
static const CGFloat PLAYING_PIXEL_HEIGHT = 0.08;

// For Gradient Node
static const CGFloat COLOR_INCREMENT = 0.001;
static const CGFloat STARTING_COLOR_OPACITY = 0.75;

// For impulse
static const CGFloat IMPULSE = 650.0;

// For tap
static const CGFloat TAP_DISTANCE = 6.0;

// For Marker Node radii
static const CGFloat MARKER_RADIUS = 24.0;

// For timer
static const CGFloat TIMER_DEPLETION_RATE = 0.003;
static const CGFloat TIMER_REPLETION_RATE = 0.02;

// For streaks and awards
static const int AWARD_INTERVAL = 5;
static const int AWARD_FACTOR = 2;

// For stars
static const CGFloat THREE_STARS_PIXELS_MISSED = 0.03;
static const CGFloat TWO_STARS_PIXELS_MISSED = 0.10;
static const CGFloat THREE_STARS_TIME_LEFT = 0.45;
static const CGFloat TWO_STARS_TIME_LEFT = 0.20;

// For animations at level end
static const CGFloat PIXELCONTAINER_GAMEPLAY_HEIGHT = 0.62;
static const CGFloat PIXELCONTAINER_CONTINUE_HEIGHT = 0.53;
static const CGFloat ANIMATION_DURATION = 0.5;
static const CGFloat PIXELCONTAINER_END_SCALE = 0.85;
static const CGFloat PIXELCONTAINER_MOVETO_HEIGHT = 0.41;

#pragma mark Default Cocos2D methods

- (void)didLoadFromCCB
{
    // Allow screen touch
    self.userInteractionEnabled = TRUE;
    
    // visualize physics bodies & joints
    //_physicsNode.debugDraw = TRUE;
    
    _physicsNode.collisionDelegate = self;
    
    _GameState = [GameState sharedCenter];
    
    NSString *imageName;
    // If starting a new level, set resume settings
    if ([[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Package Index"] intValue] < 0) {
        // Get picture from package
        imageName = [NSString stringWithFormat:@"%@.png", [[[_GameState.accessedPackage objectForKey:@"Package Contents"] objectAtIndex:_GameState.accessedLevelIndex] objectForKey:@"Filename"]];
        self.currentPicture = [[Picture alloc] initWithUIImage:[UIImage imageNamed:imageName] andGenerateShuffledPixels:YES];
        
        self.numPixelsDisplayed = 0;
        self.missedPixelCount = 0;
        self.streak = 0;
        self.awardPixels = 0;
        self.alreadyAwarded = NO;
        
        // If this is the first or second level of first pack, ready the tutorial
        if (_GameState.accessedPackageIndex == 0 && _GameState.accessedLevelIndex == 0 && [[_GameState.data objectForKey:@"Tutorial"] integerValue] == 1) {
            self.tutorialLevel = 1;
            self.tutorialStepIndex = 1;
            self.finishedActionForStep = YES;
            self.stepLoaded = NO;
        } else if (_GameState.accessedPackageIndex == 0 && _GameState.accessedLevelIndex == 1 && [[_GameState.data objectForKey:@"Tutorial"] integerValue] == 2) {
            self.tutorialLevel = 2;
            self.tutorialStepIndex = 1;
            self.finishedActionForStep = YES;
        }
        
        // Save package and level index
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:_GameState.accessedPackageIndex] forKey:@"Package Index"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:_GameState.accessedLevelIndex] forKey:@"Level Index"];
        
        // Save shuffled pixels aray
        NSData *shuffledPixels = [NSKeyedArchiver archivedDataWithRootObject:self.currentPicture.shuffledPixels];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:shuffledPixels forKey:@"Shuffled Pixels"];
        
        // Save width and length of photo in pixels, pixel size, streak, mixed pixels, award pixels and pixels already displayed
        [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Picture Dimensions"] setObject:[NSNumber numberWithInt:self.currentPicture.width] atIndex:0];
        [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Picture Dimensions"] setObject:[NSNumber numberWithInt:self.currentPicture.height] atIndex:1];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithDouble:self.currentPicture.pixelSize] forKey:@"Pixel Size"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:@0 forKey:@"Pixels Displayed"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:@0 forKey:@"Missed Pixels"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:@0 forKey:@"Streak"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:@0 forKey:@"Award Pixels"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:@NO forKey:@"Already Awarded Pixels"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:@0.0 forKey:@"Time Left"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:@0 forKey:@"Tutorial Step"];
        
        // Save to plist
        [_GameState writeToPlistInDocuments];
    // If resuming a level, load resume settings
    } else {
        _GameState.accessedPackageIndex = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Package Index"] intValue];
        _GameState.accessedPackage = [[_GameState.data objectForKey:@"Packages"] objectAtIndex:_GameState.accessedPackageIndex];
        _GameState.accessedLevelIndex = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Level Index"] intValue];
        
        // Get picture from package
        imageName = [NSString stringWithFormat:@"%@.png", [[[_GameState.accessedPackage objectForKey:@"Package Contents"] objectAtIndex:_GameState.accessedLevelIndex] objectForKey:@"Filename"]];
        self.currentPicture = [[Picture alloc] initWithUIImage:[UIImage imageNamed:imageName] andGenerateShuffledPixels:NO];
        
        // If this is the first level of first pack, ready the tutorial
        // (For second level there is no way that can paush before the only tutorial step)
        if (_GameState.accessedPackageIndex == 0 && _GameState.accessedLevelIndex == 0 && [[_GameState.data objectForKey:@"Tutorial"] integerValue] == 1) {
            self.tutorialLevel = 1;
            self.tutorialStepIndex = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Tutorial Step"] intValue];
            self.finishedActionForStep = NO;
            self.stepLoaded = NO;
        }
        
        // Set pixels displayed, shuffled pixels, missed pixels, streak, awarded pixels and already awarded pixels
        self.numPixelsDisplayed = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Pixels Displayed"] intValue];
        self.currentPicture.shuffledPixels = (NSMutableArray *)[NSKeyedUnarchiver unarchiveObjectWithData:[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Shuffled Pixels"]];
        self.missedPixelCount = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Missed Pixels"] intValue];
        self.streak = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Streak"] intValue];
        self.awardPixels = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Award Pixels"] intValue];
        self.alreadyAwarded = [[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Already Awarded Pixels"] boolValue];
        
        // Load timer bar
        _timerNode.position = ccp([[[_GameState.data objectForKey:@"Level to Resume"] objectForKey:@"Time Left"] doubleValue], _timerNode.positionInPoints.y);
        
        // Load pixels already diplayed
        for (int i = 0; i < self.numPixelsDisplayed; i++) {
            Pixel *pixelToAdd = [self.currentPicture.shuffledPixels objectAtIndex:i];
            CCNodeColor *square = [CCNodeColor nodeWithColor:[CCColor colorWithRed:pixelToAdd.red green:pixelToAdd.green blue:pixelToAdd.blue] width:self.currentPicture.pixelSize height:self.currentPicture.pixelSize];
            square.positionInPoints = [pixelToAdd getPositionWithPixelSize:self.currentPicture.pixelSize pictureWidth:self.currentPicture.width pictureHeight:self.currentPicture.height];
            [_pixelContainer addChild:square];
        }
    }
    
    _pauseMenuContainer.visible = false;
    _nextLevelMenuContainer.visible = false;

    // Set changing background
    int randomColor = arc4random() % 6;
    if (randomColor == 0) {
        self.backgroundColor = @"Red";
        _gradientNode.endColor = [CCColor redColor];
    } else if (randomColor == 1) {
        self.backgroundColor = @"Magenta";
        _gradientNode.endColor = [CCColor magentaColor];
    } else if (randomColor == 2) {
        self.backgroundColor = @"Blue";
        _gradientNode.endColor = [CCColor blueColor];
    } else if (randomColor == 3) {
        self.backgroundColor = @"Cyan";
        _gradientNode.endColor = [CCColor cyanColor];
    } else if (randomColor == 4) {
        self.backgroundColor = @"Green";
        _gradientNode.endColor = [CCColor greenColor];
    } else {
        self.backgroundColor = @"Yellow";
        _gradientNode.endColor = [CCColor yellowColor];
    }
    _gradientNode.startColor = _gradientNode.endColor;
    _gradientNode.startOpacity = STARTING_COLOR_OPACITY;
    
    self.loadedCoins = -1;
    _coinLabel.string = @"0";
    
    // Set right or left for bar
    self.barOnTheRight = ![[_GameState.data objectForKey:@"Righthanded"] boolValue];
    
    // Initialize gameplay
    [self updatePixelContainerDimensions];
    [self createPixelBarContents];
    [self createGameplayPixels];
    
    // Initiliaze timer selector
    [self schedule:@selector(tick:) interval:0.1];
    self.timerEnabled = YES;
    
    // For Debugging
    self.debugIntervals = (int) self.currentPicture.shuffledPixels.count;
    NSLog(@"%i Pixels\t%g Size each", (int) self.currentPicture.shuffledPixels.count, self.currentPicture.pixelSize);
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_playingPixelMarkerNode.physicsBody.velocity.x == 0.0 && _playingPixelMarkerNode.physicsBody.velocity.y == 0.0) {
        self.startTouch = [NSValue valueWithCGPoint:touch.locationInWorld];
    }
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // If on TUTORIAL 2 (for pause function) don't do anything
    if (self.tutorialStepIndex == 2 && self.tutorialLevel == 2) {
        return;
    }
    
    // If not on gameplay container, don't do anything
    if (_gameplayContainer.visible == false) {
        return;
    }
    
    // If start touch and moved touch are both above platform, don't do anything
    if (touch.locationInWorld.y > _platformSprite.positionInPoints.y + _platformSprite.contentSizeInPoints.height * _platformSprite.scale + 5.0 && [self.startTouch CGPointValue].y > _platformSprite.positionInPoints.y + _platformSprite.contentSizeInPoints.height * _platformSprite.scale + 5.0) {
        return;
    }
    
    // If goes above platform and hasn't shot already and isn't debuting tutorial, shoot
    if (touch.locationInWorld.y > _platformSprite.positionInPoints.y + _platformSprite.contentSizeInPoints.height * _platformSprite.scale + 5.0 && !self.alreadyShot && (!self.stepLoaded || self.swipeAnimation != nil) && !self.finishedActionForStep) {
        [self calculateAngleAndShootWithPoint:touch.locationInWorld];
        self.alreadyShot = YES;
    }
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // If not on gameplay container, don't do anything
    if (_gameplayContainer.visible == false) {
        return;
    }
    
    // If they tap below platform, don't do anything
    if (fabs(touch.locationInWorld.x - [self.startTouch CGPointValue].x) <= TAP_DISTANCE && fabs(touch.locationInWorld.y - [self.startTouch CGPointValue].y <= TAP_DISTANCE)) {
        //NSLog(@"Tap: %f", fabs(touch.locationInWorld.x - [self.startTouch CGPointValue].x));
        
        // If they tap when a step is loaded, fade step out and report time looked at step
        if (self.tutorialStepIndex > 0 && self.stepLoaded) {
            CCActionSequence *stepSequence = [CCActionSequence actions:[CCActionFadeOut actionWithDuration:0.2], [CCActionCallFunc actionWithTarget:self selector:@selector(removeStep)], nil];
            [self.step runAction:stepSequence];
            
            // ANALYTICS: Time viewed tutorial step
            NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithDouble:self.timeLookingAtStep - 0.2], @"timeViewedTutorialStep", [NSNumber numberWithInt:self.tutorialStepIndex], @"tutorialStep", [NSNumber numberWithInt:_GameState.accessedLevelIndex], @"level", nil];
            NSLog(@"Time for step: %g", self.timeLookingAtStep - 0.2);
            [MGWU logEvent:@"viewedTutorialStep" withParams:params];
            return;
        }
        
        // If they tap above the platform, pause the game
        if (touch.locationInWorld.y > _platformSprite.positionInPoints.y + _platformSprite.contentSizeInPoints.height * _platformSprite.scaleY) {
            [self pause];
        }
        return;
    }
    
    // If drag longer than a tap and starting touch was already above platform, don't do anything
    if (touch.locationInWorld.y > _platformSprite.positionInPoints.y + _platformSprite.contentSizeInPoints.height * _platformSprite.scale + 5.0 && [self.startTouch CGPointValue].y > _platformSprite.positionInPoints.y + _platformSprite.contentSizeInPoints.height * _platformSprite.scale + 5.0) {
        return;
    }
    
    // If didn't drag finger up (results in divide by zero or negative change), don't do anything
    CGPoint startTouchLocation = [self.startTouch CGPointValue];
    if (touch.locationInWorld.y <= startTouchLocation.y) {
        return;
    }
    
    // If on TUTORIAL 2 (for pause function) don't do anything
    if (self.tutorialStepIndex == 2 && self.tutorialLevel == 2) {
        return;
    }
    
    // If not moving and not already shot and not debuting tutorial, add an impulse
    if (_playingPixelMarkerNode.physicsBody.velocity.x == 0.0 && _playingPixelMarkerNode.physicsBody.velocity.y == 0.0 && !self.alreadyShot && (!self.stepLoaded || self.swipeAnimation != nil) && !self.finishedActionForStep) {
        [self calculateAngleAndShootWithPoint:touch.locationInWorld];
    }
    self.alreadyShot = NO;
}

- (void)calculateAngleAndShootWithPoint:(CGPoint)lastTouch
{
    // Start location is from starting touch
    CGPoint startTouchLocation = [self.startTouch CGPointValue];
    
    // Calculate angles of shot and to flashing pixel
    self.angleActual = atan2(lastTouch.y - startTouchLocation.y, lastTouch.x - startTouchLocation.x);
    self.anglePerfect = atan2(_flashingPixelMarkerNode.positionInPoints.y - _playingPixelMarkerNode.positionInPoints.y, _flashingPixelMarkerNode.positionInPoints.x - _playingPixelMarkerNode.positionInPoints.x);
    //NSLog(@"Actual: %g \nPerfect: %g", self.angleActual, self.anglePerfect);
    
    CGFloat changeX = _flashingPixelMarkerNode.positionInPoints.x - _playingPixelMarkerNode.positionInPoints.x;
    CGFloat changeY = _flashingPixelMarkerNode.positionInPoints.y - _playingPixelMarkerNode.positionInPoints.y;
    self.angleIncrement = asin(MARKER_RADIUS * 2 / sqrt(changeY * changeY + changeX * changeX));
    //NSLog(@"Between %g & %g", self.anglePerfect - self.angleIncrement, self.anglePerfect + self.angleIncrement);
    
    // Impulse
    CGPoint impulse;
    if (self.angleActual <= self.anglePerfect + self.angleIncrement && self.angleActual >= self.anglePerfect - self.angleIncrement) {
        //NSLog(@"Good");
        impulse = ccp(IMPULSE * (_flashingPixelMarkerNode.positionInPoints.x - _playingPixelMarkerNode.positionInPoints.x) / (_flashingPixelMarkerNode.positionInPoints.y - _playingPixelMarkerNode.positionInPoints.y), IMPULSE);
    } else {
        //NSLog(@"Missed");
        impulse = ccp(IMPULSE * (lastTouch.x - startTouchLocation.x) / (lastTouch.y - startTouchLocation.y), IMPULSE);
    }
    int hasAngularVelocity = arc4random() % 4;
    if (hasAngularVelocity == 0) {
        _playingPixelMarkerNode.physicsBody.angularVelocity = arc4random() % 8;
    }
    //NSLog(@"Angular Velocity %g", _playingPixelMarkerNode.physicsBody.angularVelocity);
    [_playingPixelMarkerNode.physicsBody applyImpulse:impulse];
}

- (void)tick:(CCTime)delta
{
    if (self.timerEnabled) {
        // If not on tutorial, or on tutorial but not viewing a step (and beyond TUTORIAL 1 STEP 2) then deplete timer
        if ((self.tutorialLevel == 0) ||
            (self.tutorialLevel == 2 && !self.stepLoaded && !self.finishedActionForStep) ||
            (self.tutorialLevel == 1 && !self.stepLoaded && !self.finishedActionForStep && self.tutorialStepIndex >= 2)) {
            _timerNode.positionInPoints = ccp(_timerNode.positionInPoints.x - TIMER_DEPLETION_RATE * [[CCDirector sharedDirector]viewSize].width, _timerNode.positionInPoints.y);
            
            // Save time left
            [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithDouble:_timerNode.position.x] forKey:@"Time Left"];
            [_GameState writeToPlistInDocuments];
        }
    }
    
    // When timer bar runs out
    if (_timerNode.positionInPoints.x <= 0 && self.timerEnabled) {
        [self cancelAndEndLevel];
    }
}

- (void)update:(CCTime)delta
{
    CGFloat red = _gradientNode.startColor.red;
    CGFloat green = _gradientNode.startColor.green;
    CGFloat blue = _gradientNode.startColor.blue;
//    CGFloat alpha = _gradientNode.startColor.alpha;
//    NSLog(@"%g, %g, %g, %g", red, green, blue, alpha);
    
    if ([self.backgroundColor isEqualToString: @"Red"]) {
        _gradientNode.endColor = [CCColor colorWithRed:1.0 green:0.0 blue:blue + COLOR_INCREMENT alpha:1.0];
        if (blue >= 1.0) {
            self.backgroundColor = @"Magenta";
        }
    } else if ([self.backgroundColor isEqualToString: @"Magenta"]) {
        _gradientNode.endColor = [CCColor colorWithRed:red - COLOR_INCREMENT green:0.0 blue:1.0 alpha:1.0];
        if (red <= 0.0) {
            self.backgroundColor = @"Blue";
        }
    } else if ([self.backgroundColor isEqualToString: @"Blue"]) {
        _gradientNode.endColor = [CCColor colorWithRed:0.0 green:green + COLOR_INCREMENT blue:1.0 alpha:1.0];
        if (green >= 1.0) {
            self.backgroundColor = @"Cyan";
        }
    } else if ([self.backgroundColor isEqualToString: @"Cyan"]) {
        _gradientNode.endColor = [CCColor colorWithRed:0.0 green:1.0 blue:blue - COLOR_INCREMENT alpha:1.0];
        if (blue <= 0.0) {
            self.backgroundColor = @"Green";
        }
    } else if ([self.backgroundColor isEqualToString: @"Green"]) {
        _gradientNode.endColor = [CCColor colorWithRed:red + COLOR_INCREMENT green:1.0 blue:0.0 alpha:1.0];
        if (red >= 1.0) {
            self.backgroundColor = @"Yellow";
        }
    } else if ([self.backgroundColor isEqualToString: @"Yellow"]) {
        _gradientNode.endColor = [CCColor colorWithRed:1.0 green:green - COLOR_INCREMENT blue:0.0 alpha:1.0];
        if (green <= 0.0) {
            self.backgroundColor = @"Red";
        }
    }
    _gradientNode.startColor = _gradientNode.endColor;
    _gradientNode.startOpacity = STARTING_COLOR_OPACITY;
    
    // If goes out of bounds
    if (_playingPixelMarkerNode.positionInPoints.x < 0.0 || _playingPixelMarkerNode.positionInPoints.y < 0.0 ||     _playingPixelMarkerNode.positionInPoints.x > [[CCDirector sharedDirector]viewSize].width || _playingPixelMarkerNode.positionInPoints.y > [[CCDirector sharedDirector]viewSize].height)
    {
        self.streak = 0;
        //NSLog(@"Streak: %i", self.streak);
        self.alreadyAwarded = NO;
        self.missedPixelCount++;
        
        self.collisionHappened = NO;
        self.runEndOfPlay = YES;
    }
    
    // Starting intervals for debugging
    if (self.debugIntervals && _gameplayContainer.visible) {
        //self.debugIntervals--;
        self.collisionHappened = true;
        self.runEndOfPlay = true;
    }
    
    // For streaks
    if (self.streak % AWARD_INTERVAL == 0 && !self.alreadyAwarded && self.streak != 0) {
        self.awardPixels = (int) pow(AWARD_FACTOR, (self.streak / AWARD_INTERVAL + 1));
        if (self.awardPixels > self.currentPicture.shuffledPixels.count - self.numPixelsDisplayed) {
            self.awardPixels = (int) self.currentPicture.shuffledPixels.count - self.numPixelsDisplayed;
        }
        self.alreadyAwarded = YES;
        NSLog(@"Award: %g", self.awardPixels * (TIMER_REPLETION_RATE * 0.6 / (self.currentPicture.shuffledPixels.count * 0.01 + 1)));
        _timerNode.positionInPoints = ccp(_timerNode.positionInPoints.x + self.awardPixels * (TIMER_REPLETION_RATE * 0.6 / (self.currentPicture.shuffledPixels.count * 0.01 + 1)) * [[CCDirector sharedDirector]viewSize].width, _timerNode.positionInPoints.y);
        if (_timerNode.positionInPoints.x > [[CCDirector sharedDirector]viewSize].width) {
            _timerNode.positionInPoints = ccp([[CCDirector sharedDirector]viewSize].width, _timerNode.positionInPoints.y);
        }
    }
    
    // Awards from streaks
    if (self.awardPixels && _gameplayContainer.visible) {
        //self.awardPixels--;
        self.collisionHappened = true;
        self.runEndOfPlay = true;
        
        // FOR TUTORIAL 1 STEP 2: First streak
        // Checks for award pixels is one because hasn't incremented it down yet
        if (self.tutorialLevel == 1 && self.tutorialStepIndex == 2 && self.streak / AWARD_INTERVAL == 1 && self.awardPixels == 1) {
            self.finishedActionForStep = true;
            [self incrementTutorialStep];
        }
    }
    
    // Run end of play if necessary
    if (self.runEndOfPlay) {
        [self endOfPlay];
    }
    
    // Display coins if available
    if (self.loadedCoins != self.coins && self.coins && self.loadedCoins >= 0) {
        self.loadedCoins++;
        _coinLabel.string = [NSString stringWithFormat:@"%i", self.loadedCoins];
        
        if (self.loadedCoins % 10 && self.loadedCoins >= 0 && !self.coinSounded) {
            self.coinSounded = YES;
            [self loadCoinSound];
        }
        
        // Burst stars and load bonus coins if won the level and finished loading coins (coins are non-zero)
        if (_starBar.visible && _starBar.opacity == 1.0 && self.loadedBonusCoins == 0 && self.loadedCoins == self.coins && self.coins) {
            [_starBar runAction:[CCActionSequence actions: [CCActionDelay actionWithDuration:0.3], [CCActionCallFunc actionWithTarget:self selector:@selector(burstStarsAgain)], nil]];
        }
    }
    
    // Display bonus coins if available and burst particles for bonus already displayed
    if (self.loadedBonusCoins != self.bonusCoins && self.burstStarsForBonus) {
        self.loadedBonusCoins++;
        _coinLabel.string = [NSString stringWithFormat:@"%i", self.coins + self.loadedBonusCoins];
        
        if (self.loadedBonusCoins % 10 && !self.coinSounded) {
            self.coinSounded = YES;
            [self loadCoinSound];
        }
    }
    
    // TUTORIAL: If this step is done and action completed, load next step
    if (self.tutorialStepIndex > 0 && !self.stepLoaded && self.finishedActionForStep) {
        [self loadTutorialStep];
        self.stepLoaded = YES;
    }
    
    // If viewing a step, increment timeLookingAtStep
    if (self.stepLoaded) {
        self.timeLookingAtStep += delta;
    }
}

- (BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair flashingPixel:(CCNode *)nodeA playingPixel:(CCNode *)nodeB
{
    self.streak++;
    self.alreadyAwarded = NO;
    
    _timerNode.positionInPoints = ccp(_timerNode.positionInPoints.x + TIMER_REPLETION_RATE * [[CCDirector sharedDirector]viewSize].width, _timerNode.positionInPoints.y);
    if (_timerNode.positionInPoints.x > [[CCDirector sharedDirector]viewSize].width) {
        _timerNode.positionInPoints = ccp([[CCDirector sharedDirector]viewSize].width, _timerNode.positionInPoints.y);
    }
    
    self.collisionHappened = YES;
    self.runEndOfPlay = YES;
    return true;
}

#pragma mark Button Selector Methods

- (void)pause
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];
    
    //NSLog(@"Pause");
    _gameplayContainer.visible = false;
    _pixelContainer.visible = false;
    _pauseMenuContainer.visible = true;
    
    self.timerEnabled = NO;
}

- (void)resume
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];
    
    _pauseMenuContainer.visible = false;
    _gameplayContainer.visible = true;
    _pixelContainer.visible = true;
    
    self.timerEnabled = YES;
}

- (void)gameplay
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];
    
    // Save package index in resume as -1
    [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:-1] forKey:@"Package Index"];
    [_GameState writeToPlistInDocuments];
    
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

- (void)packs
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];
    
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"PackageScene"]];
}

- (void)continueForCash
{
    
}

- (void)cancelAndEndLevel
{
    // Remove markerNodes
    [_playingPixelMarkerNode removeChild:self.playingPixel.playingSquare];
    [_flashingPixelMarkerNode removeChild:self.flashingSprite];
    
    self.timerEnabled = NO;
    
    // Save package index in resume as -1
    [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:-1] forKey:@"Package Index"];
    [_GameState writeToPlistInDocuments];
    
    // ANALYTICS: Lost level
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt:self.missedPixelCount], @"pixelsMissed", [NSNumber numberWithInt:_GameState.accessedLevelIndex], @"level", [[[_GameState.data objectForKey:@"Packages"] objectAtIndex:_GameState.accessedPackageIndex] objectForKey:@"Package Name"], @"pack",  nil];
    [MGWU logEvent:@"failedLevel" withParams:params];
    
    // Bring failed level menu
    _gameplayContainer.visible = false;
    _nextLevelMenuContainer.visible = true;
    
    // Set button labels
    CCSpriteFrame *retryFrame = [CCSpriteFrame frameWithImageNamed:@"ButtonAssets/replay.png"];
    CCSpriteFrame *retryFrameShaded = [CCSpriteFrame frameWithImageNamed:@"ButtonAssets/replay-down.png"];
    [_nextLevelButton setBackgroundSpriteFrame:retryFrame forState:CCControlStateNormal];
    [_nextLevelButton setBackgroundSpriteFrame:retryFrameShaded forState:CCControlStateHighlighted];
    [_nextLevelButton setBackgroundSpriteFrame:retryFrameShaded forState:CCControlStateSelected];
    [_nextLevelButton setBackgroundSpriteFrame:retryFrameShaded forState:CCControlStateDisabled];
    _finishedPackNode.visible = false;
    
    // Set endLevelLabel to filename
    _endLevelLabel.string = @"Out of Time!";
    _endLevelLabel.position = ccp(0.5, 0.14);
    
    // Make starBar invisible
    _starBar.visible = false;
    
    // Set coins
    if (_pixelContainer.children.count) {
        self.coins = ((int) _pixelContainer.children.count / 4 / 10 + 1) * 10;
    } else {
        self.coins = 0;
    }
    [_GameState addCoinsToDisplayLater:self.coins];
    _coinSprite.position = ccp(0.35, 0.74);
    _coinLabel.position = ccp(0.585, 0.74);
    
    [self resetAnimationContent];
    
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Ethereal Magic Sparkle.wav"];
    
    // Scale, fade and move pixelContainer -> Call selector to show label and buttons
    CCAction *fadePixelContainer = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION * 2 opacity:0.0];
    CCAction *movePixelContainer = [CCActionMoveTo actionWithDuration:ANIMATION_DURATION * 2 position:ccp(0.5 , PIXELCONTAINER_MOVETO_HEIGHT)];
    CCAction *scalePixelContainer = [CCActionScaleBy actionWithDuration:ANIMATION_DURATION * 2 scale: PIXELCONTAINER_END_SCALE];
    [_pixelContainer runAction:fadePixelContainer];
    [_pixelContainer runAction:scalePixelContainer];
    [_pixelContainer runAction:[CCActionSequence actions: (CCActionFiniteTime *)movePixelContainer, [CCActionCallFunc actionWithTarget:self selector:@selector(loadButtonsAndTitle)], nil]];
}

#pragma mark Non-default Xcode Methods

- (void)updatePixelContainerDimensions
{
    CGFloat width = self.currentPicture.pixelSize * self.currentPicture.width + DISTANCE_FROM_CONTAINER_WALLS * 2;
    CGFloat height = self.currentPicture.pixelSize * self.currentPicture.height + DISTANCE_FROM_CONTAINER_WALLS * 2;
    CGSize newContainerSize = CGSizeMake(width, height);
    [_pixelContainer setContentSizeInPoints:newContainerSize];
}

- (void)createGameplayPixels
{
    CGFloat playingPixelSize;
    if (_pixelContainer.scaleX > _pixelContainer.scaleY) {
        playingPixelSize = self.currentPicture.pixelSize * _pixelContainer.scaleY;
    } else {
        playingPixelSize = self.currentPicture.pixelSize * _pixelContainer.scaleX;
    }
    
    // Initializes playingSquare
    self.playingPixel = [[PlayingPixel alloc]init];
    Pixel *actualPlayingPixel = [self.currentPicture.shuffledPixels objectAtIndex:self.numPixelsDisplayed];
    self.playingPixel.playingSquare = [CCNodeColor nodeWithColor:[CCColor colorWithRed:actualPlayingPixel.red green:actualPlayingPixel.green blue:actualPlayingPixel.blue] width:playingPixelSize height:playingPixelSize];
    
    self.playingPixel.playingSquare.anchorPoint = ccp(0.5, 0.5);
    [_playingPixelMarkerNode addChild:self.playingPixel.playingSquare];
    
    // Initializes flashingSprite
    self.flashingSprite = (FlashingPixel *)[CCBReader load:@"FlashingPixel"];
    [self.flashingSprite setFlashingSquareSizeOf:playingPixelSize];
    Pixel *actualFlashingPixel = [self.currentPicture.shuffledPixels objectAtIndex:self.numPixelsDisplayed];
    CGFloat anchorPointHeight = _pixelContainer.position.y * [[CCDirector sharedDirector]viewSize].height;
    CGFloat anchorPointWidth = _pixelContainer.position.x * [[CCDirector sharedDirector]viewSize].width;
    CGPoint corner = ccp(anchorPointWidth - 0.5 * _pixelContainer.contentSizeInPoints.width * _pixelContainer.scaleX, anchorPointHeight - 0.5 * _pixelContainer.contentSizeInPoints.height * _pixelContainer.scaleY);
    CGPoint origin = [actualFlashingPixel getPositionWithPixelSize:self.currentPicture.pixelSize pictureWidth:self.currentPicture.width pictureHeight:self.currentPicture.height];
    CGPoint nextPoint = ccp(corner.x + 0.5 * playingPixelSize + origin.x * _pixelContainer.scaleX, corner.y + 0.5 * playingPixelSize + origin.y * _pixelContainer.scaleY);
    _flashingPixelMarkerNode.positionInPoints = nextPoint;
    [_flashingPixelMarkerNode addChild:self.flashingSprite];
}

- (void)createPixelBarContents
{
    // Creates pixel bar container for squares of displayed pixels
    self.pixelBarContents = [NSMutableArray arrayWithCapacity:NUM_PIXELS_HELD_IN_BAR];
    
    if (self.barOnTheRight) {
        _pixelBar.anchorPoint = ccp(1.0, 0.5);
        _pixelBar.positionInPoints = ccp([[CCDirector sharedDirector]viewSize].width, PIXELBAR_HEIGHT * [[CCDirector sharedDirector]viewSize].height);
    } else {
        _pixelBar.anchorPoint = ccp(0.0, 0.5);
        _pixelBar.positionInPoints = ccp(0.0, PIXELBAR_HEIGHT * [[CCDirector sharedDirector]viewSize].height);
    }
    
    // Runs loop to add first five displayed squares (from first five pixels)
    for (int i = 0; i < NUM_PIXELS_HELD_IN_BAR; i++) {
        Pixel *addedPixel = [self.currentPicture.shuffledPixels objectAtIndex:i + self.numPixelsDisplayed + 1];
        CCNodeColor *squareForPixelBar = [CCNodeColor nodeWithColor:[CCColor colorWithRed:addedPixel.red green:addedPixel.green blue:addedPixel.blue] width:PIXEL_SIZE_IN_BAR height:PIXEL_SIZE_IN_BAR];

        if (self.barOnTheRight) {
            squareForPixelBar.anchorPoint = ccp(0.0, 0.0);
            squareForPixelBar.positionInPoints = ccp(PIXEL_SIZE_IN_BAR * i + DISTANCE_FROM_BAR_WALLS, DISTANCE_FROM_BAR_WALLS);
        } else {
            squareForPixelBar.anchorPoint = ccp(1.0, 0.0);
            squareForPixelBar.positionInPoints = ccp(_pixelBar.contentSize.width - (PIXEL_SIZE_IN_BAR * i + DISTANCE_FROM_BAR_WALLS), DISTANCE_FROM_BAR_WALLS);
        }

        [_pixelBar addChild:squareForPixelBar];
        [self.pixelBarContents addObject:squareForPixelBar];
    }
}

- (void)shiftPixelBarContentsAndPixel
{
    // Remove first pixel in bar and initializes playingSquare and flashingSprite
    CCNodeColor *removedSquareFromBar;
    if (self.pixelBarContents.count != 0) {
        removedSquareFromBar = [self.pixelBarContents objectAtIndex:0];
        [_pixelBar removeChild:removedSquareFromBar];
        [self.pixelBarContents removeObjectAtIndex:0];
        
        self.playingPixel.playingSquare.color = removedSquareFromBar.color;
        
        CGFloat playingPixelSize;
        if (_pixelContainer.scaleX > _pixelContainer.scaleY) {
            playingPixelSize = self.currentPicture.pixelSize * _pixelContainer.scaleY;
        } else {
            playingPixelSize = self.currentPicture.pixelSize * _pixelContainer.scaleX;
        }
        
        Pixel *actualFlashingPixel = [self.currentPicture.shuffledPixels objectAtIndex:self.numPixelsDisplayed];
        CGFloat anchorPointHeight = _pixelContainer.position.y * [[CCDirector sharedDirector]viewSize].height;
        CGFloat anchorPointWidth = _pixelContainer.position.x * [[CCDirector sharedDirector]viewSize].width;
        CGPoint corner = ccp(anchorPointWidth - 0.5 * _pixelContainer.contentSizeInPoints.width * _pixelContainer.scaleX, anchorPointHeight - 0.5 * _pixelContainer.contentSizeInPoints.height * _pixelContainer.scaleY);
        CGPoint origin = [actualFlashingPixel getPositionWithPixelSize:self.currentPicture.pixelSize pictureWidth:self.currentPicture.width pictureHeight:self.currentPicture.height];
        CGPoint nextPoint = ccp(corner.x + 0.5 * playingPixelSize + origin.x * _pixelContainer.scaleX, corner.y + 0.5 * playingPixelSize + origin.y * _pixelContainer.scaleY);
        _flashingPixelMarkerNode.positionInPoints = nextPoint;

        // Save number pixels displayed, streak, award pixels and awardedPixels to plist
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:self.numPixelsDisplayed] forKey:@"Pixels Displayed"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:self.streak] forKey:@"Streak"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:self.awardPixels] forKey:@"Award Pixels"];
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithBool:self.alreadyAwarded] forKey:@"Already Awarded Pixels"];
        
        [_GameState writeToPlistInDocuments];
        
    } else if (self.collisionHappened) {
        
        // Remove markerNodes
        [_playingPixelMarkerNode removeChild:self.playingPixel.playingSquare];
        [_flashingPixelMarkerNode removeChild:self.flashingSprite];
        
        self.timerEnabled = NO;
        
        // Bring next level menu
        _gameplayContainer.visible = false;
        _nextLevelMenuContainer.visible = true;
        
        // Set endLevelLabel to filename
        _endLevelLabel.string = [[[_GameState.accessedPackage objectForKey:@"Package Contents"] objectAtIndex:_GameState.accessedLevelIndex] objectForKey:@"Filename"];
        
        // Unlock current picture
        [[[_GameState.accessedPackage objectForKey:@"Package Contents"] objectAtIndex:_GameState.accessedLevelIndex] setObject:@NO forKey:@"Locked"];
        
        // Set stars for current picture & bonus coins
        if ((double)self.missedPixelCount / self.currentPicture.shuffledPixels.count <= THREE_STARS_PIXELS_MISSED && (_timerNode.positionInPoints.x) / [[CCDirector sharedDirector]viewSize].width > THREE_STARS_TIME_LEFT) {
            self.stars = 3;
        } else if ((double)self.missedPixelCount / self.currentPicture.shuffledPixels.count <= TWO_STARS_PIXELS_MISSED && (_timerNode.positionInPoints.x) / [[CCDirector sharedDirector]viewSize].width > TWO_STARS_TIME_LEFT) {
            self.stars = 2;
        } else {
            self.stars = 1;
        }
        
        // Set coins
        self.coins = ((int) self.currentPicture.shuffledPixels.count / 100 + 1) * 50;
        self.bonusCoins = self.stars * (0.2 * self.coins);
        [_GameState addCoinsToDisplayLater:self.coins + self.bonusCoins];
        
        // If earned more stars this round than before, store stars
        if ([[[[_GameState.accessedPackage objectForKey:@"Package Contents"] objectAtIndex:_GameState.accessedLevelIndex] objectForKey:@"Stars"] intValue] < self.stars) {
            [[[_GameState.accessedPackage objectForKey:@"Package Contents"] objectAtIndex:_GameState.accessedLevelIndex] setObject:[NSNumber numberWithInt:self.stars] forKey:@"Stars"];
        }
        
        // If this is the newest level, set Level's passed to current level index
        if ([[_GameState.accessedPackage objectForKey:@"Levels Passed"] integerValue] < _GameState.accessedLevelIndex + 1) {
            [_GameState.accessedPackage setObject:[NSNumber numberWithInt:_GameState.accessedLevelIndex + 1] forKey:@"Levels Passed"];
        }
        
        // Set current picture index
        [_GameState.accessedPackage setObject:[NSNumber numberWithInt:_GameState.accessedLevelIndex] forKey:@"Current Picture Index"];
        
        // Save tutorial completion if finished TUTORIAL 1 or TUTORIAL 2
        if (self.tutorialLevel == 1 || self.tutorialLevel == 2) {
            [_GameState.data setValue:[NSNumber numberWithInt:(self.tutorialLevel + 1) % 3] forKey:@"Tutorial"];
        }
        
        // Save package index in resume as -1
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:-1] forKey:@"Package Index"];
        
        // Save to plist
        [_GameState writeToPlistInDocuments];
        
        // ANALYTICS: Beat level
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt:self.stars], @"stars", [NSNumber numberWithInt:_GameState.accessedLevelIndex], @"level", [[[_GameState.data objectForKey:@"Packages"] objectAtIndex:_GameState.accessedPackageIndex] objectForKey:@"Package Name"], @"pack",  nil];
        [MGWU logEvent:@"completedLevel" withParams:params];
        
        // Increment picture index
        BOOL finishedPackage;
        NSMutableArray *packageContents = [_GameState.accessedPackage objectForKey:@"Package Contents"];
        if (_GameState.accessedLevelIndex == packageContents.count - 1) {
            finishedPackage = true;
            
            // ANALYTICS: Beat pack
            NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: [[[_GameState.data objectForKey:@"Packages"] objectAtIndex:_GameState.accessedPackageIndex] objectForKey:@"Package Name"], @"pack",  nil];
            [MGWU logEvent:@"completedPack" withParams:params];
        } else {
            _GameState.accessedLevelIndex++;
            finishedPackage = false;
        }
        
        // If this is the last level in package, create finish option to load PackageScene
        if (finishedPackage) {
            _finishedLevelNode.visible = false;
        } else {
            _finishedPackNode.visible = false;
        }
        
        [self resetAnimationContent];
        
        // Play heaven's gates
        OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
        [audio playEffect:@"Heavens Gates.wav"];
        
        // Scale, fade and move pixelContainer -> Call selector to show label and buttons
        CCAction *fadePixelContainer = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION * 2 opacity:0.0];
        CCAction *movePixelContainer = [CCActionMoveTo actionWithDuration:ANIMATION_DURATION * 2 position:ccp(0.5 , PIXELCONTAINER_MOVETO_HEIGHT)];
        CCAction *scalePixelContainer = [CCActionScaleBy actionWithDuration:ANIMATION_DURATION * 2 scale: PIXELCONTAINER_END_SCALE];
        [_pixelContainer runAction:fadePixelContainer];
        [_pixelContainer runAction:scalePixelContainer];
        [_pixelContainer runAction:[CCActionSequence actions: (CCActionFiniteTime *)movePixelContainer, [CCActionCallFunc actionWithTarget:self selector:@selector(loadButtonsAndTitle)], nil]];
    }
    
    // Add a pixel to bar if available
    CCNodeColor *addedSquareToBar;
    if (self.currentPicture.shuffledPixels.count > self.numPixelsDisplayed + NUM_PIXELS_HELD_IN_BAR) {
        Pixel *addedPixelToBar = [self.currentPicture.shuffledPixels objectAtIndex:self.numPixelsDisplayed + NUM_PIXELS_HELD_IN_BAR];
        addedSquareToBar = [CCNodeColor nodeWithColor:[CCColor colorWithRed:addedPixelToBar.red green:addedPixelToBar.green blue:addedPixelToBar.blue] width:PIXEL_SIZE_IN_BAR height:PIXEL_SIZE_IN_BAR];
    } else if (!self.collisionHappened) {
        Pixel *addedPixelToBar = [self.currentPicture.shuffledPixels objectAtIndex:self.currentPicture.shuffledPixels.count - 1];
        addedSquareToBar = [CCNodeColor nodeWithColor:[CCColor colorWithRed:addedPixelToBar.red green:addedPixelToBar.green blue:addedPixelToBar.blue] width:PIXEL_SIZE_IN_BAR height:PIXEL_SIZE_IN_BAR];
    }
    
    // Add position to square added to bar
    if (self.barOnTheRight) {
        addedSquareToBar.anchorPoint = ccp(0.0, 0.0);
        addedSquareToBar.positionInPoints = ccp(PIXEL_SIZE_IN_BAR * self.pixelBarContents.count + DISTANCE_FROM_BAR_WALLS, DISTANCE_FROM_BAR_WALLS);
    } else {
        addedSquareToBar.anchorPoint = ccp(1.0, 0.0);
        addedSquareToBar.positionInPoints = ccp(_pixelBar.contentSize.width - (PIXEL_SIZE_IN_BAR * self.pixelBarContents.count + DISTANCE_FROM_BAR_WALLS), DISTANCE_FROM_BAR_WALLS);
    }
    
    // Run loop for each pixel in bar
    for (int i = 0; i < self.pixelBarContents.count; i++) {
        CCNodeColor *modifiedSquare = [self.pixelBarContents objectAtIndex:i];
        if (self.barOnTheRight) {
            modifiedSquare.positionInPoints = ccp(PIXEL_SIZE_IN_BAR * i + DISTANCE_FROM_BAR_WALLS, DISTANCE_FROM_BAR_WALLS);
        } else {
            modifiedSquare.positionInPoints = ccp(_pixelBar.contentSize.width - (PIXEL_SIZE_IN_BAR * i + DISTANCE_FROM_BAR_WALLS), DISTANCE_FROM_BAR_WALLS);
        }
    }
    
    // Add the actual square to the bar, visually
    if (self.currentPicture.shuffledPixels.count > self.numPixelsDisplayed + NUM_PIXELS_HELD_IN_BAR) {
        [self.pixelBarContents addObject:addedSquareToBar];
        [_pixelBar addChild:addedSquareToBar];
    } else if (addedSquareToBar != nil && !self.collisionHappened) {
        // If the last pixel (we know this because removedPixelFromBar is nil) is missed, set it to playing pixel
        if (self.pixelBarContents.count == 0 && removedSquareFromBar == nil) {
            [self resetPlayingPixelLocation];
            self.playingPixel.playingSquare.color = addedSquareToBar.color;
        } else {
            [self.pixelBarContents addObject:addedSquareToBar];
            [_pixelBar addChild:addedSquareToBar];
        }
    }
}

- (void)resetPlayingPixelLocation
{
    _playingPixelMarkerNode.physicsBody.angularVelocity = 0.0;
    _playingPixelMarkerNode.rotation = 0.0;
    _playingPixelMarkerNode.physicsBody.velocity = ccp(0.0, 0.0);
    _playingPixelMarkerNode.positionInPoints = ccp(PLAYING_PIXEL_WIDTH * [[CCDirector sharedDirector]viewSize].width, PLAYING_PIXEL_HEIGHT * [[CCDirector sharedDirector]viewSize].height);
}

- (void)resetAnimationContent
{
    // Disable nextLevel, finish, packs buttons
    _nextLevelButton.enabled = false;
    _packsButton.enabled = false;
    _finishButton.enabled = false;
    
    // Initialize content to invisible
    _endLevelLabel.opacity = 0.0;
    if (_finishedLevelNode.visible) {
        _nextLevelButton.cascadeOpacityEnabled = YES;
        _nextLevelButton.opacity = 0.0;
        _packsButton.cascadeOpacityEnabled = YES;
        _packsButton.opacity = 0.0;
    } else {
        _finishButton.cascadeOpacityEnabled = YES;
        _finishButton.opacity = 0.0;
    }
    _starBar.cascadeOpacityEnabled = YES;
    _starBar.opacity = 0.0;
    _coinSprite.cascadeOpacityEnabled = YES;
    _coinSprite.opacity = 0.0;
    _coinLabel.opacity = 0.0;
}

- (void)endOfPlay
{
    if (self.collisionHappened) {
        //NSLog(@"Added Pixel because collided");
        Pixel *currentPixel = [self.currentPicture.shuffledPixels objectAtIndex:self.numPixelsDisplayed];
        CCNodeColor *square = [CCNodeColor nodeWithColor:[CCColor colorWithRed:currentPixel.red green:currentPixel.green blue:currentPixel.blue] width:self.currentPicture.pixelSize height:self.currentPicture.pixelSize];
        square.positionInPoints = [currentPixel getPositionWithPixelSize:self.currentPicture.pixelSize pictureWidth:self.currentPicture.width pictureHeight:self.currentPicture.height];
        [_pixelContainer addChild:square];
        
        CCParticleSystem *particles = (CCParticleSystem *)[CCBReader load:@"Small Burst Sparkles"];
        particles.position = ccp(self.currentPicture.pixelSize / 2, self.currentPicture.pixelSize / 2);
        [square addChild:particles];
        
        if (self.debugIntervals == 0 && self.awardPixels == 0) {
            // Make pop sound for pixels shot
            OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
            [audio playEffect:@"Pop.wav"];
        } else {
            // TODO: Place other sound for bonuses here
            
            OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
            [audio playEffect:@"Pop.wav"];
        }
        
        // Increment debug intervals or award pixels
        if (self.debugIntervals) {
            self.debugIntervals--;
        } else if (self.awardPixels) {
            self.awardPixels--;
        }
        
        self.numPixelsDisplayed++;
    } else {
        //NSLog(@"Removed Pixel because out of bounds");
        Pixel *missedPixel = [self.currentPicture.shuffledPixels objectAtIndex:self.numPixelsDisplayed];
        [self.currentPicture.shuffledPixels removeObjectAtIndex:self.numPixelsDisplayed];
        [self.currentPicture.shuffledPixels addObject:missedPixel];
        
        // Save shuffled pixels to resume in plist
        [[_GameState.data objectForKey:@"Level to Resume"] setObject:self.currentPicture.shuffledPixels forKey:@"Shuffled Pixels"];
        [_GameState writeToPlistInDocuments];
    }
       
    [self resetPlayingPixelLocation];
    
    self.runEndOfPlay = false;
    
    [self shiftPixelBarContentsAndPixel];
    
    // FOR TUTORIAL 1 STEP 1: Learning to swipe
    if (self.tutorialLevel == 1 && self.tutorialStepIndex == 1) {
        if (self.collisionHappened) {
            // If completed first step, move on to step two
            [self removeSwipeAnimation];
            self.finishedActionForStep = true;
            self.stepLoaded = NO;
            [self incrementTutorialStep];
        } else {
            // If missed and therefore step isn't completed, reset animation
            [self removeSwipeAnimation];
            [self createSwipeAnimation];
        }
    }
}

#pragma mark Selectors for Completed Level

- (void)loadButtonsAndTitle
{
    // Fade in endLevelLabel and bottom buttons -> Call selector to load star shadows
    CCAction *fadeInLabel = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
    [_endLevelLabel runAction:fadeInLabel];
    
    // If won the game, load buttons and then stars
    if (_starBar.visible) {
        if (_finishedLevelNode.visible) {
            // If this is not the last level, load both buttons
            CCAction *fadeInPacksButton = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
            [_packsButton runAction:fadeInPacksButton];
            CCAction *fadeInEndButton = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
            [_nextLevelButton runAction:[CCActionSequence actions: (CCActionFiniteTime *)fadeInEndButton, [CCActionCallFunc actionWithTarget:self selector:@selector(loadStarShadows)], nil]];
            _packsButton.enabled = true;
            _nextLevelButton.enabled = true;
        } else {
            // If this is the last level in the pack, load just the finish button
            CCAction *fadeInFinishButton = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
            [_finishButton runAction:[CCActionSequence actions: (CCActionFiniteTime *)fadeInFinishButton, [CCActionCallFunc actionWithTarget:self selector:@selector(loadStarShadows)], nil]];
            _finishButton.enabled = true;
        }
    // If lost the game, load buttons and then coins
    } else {
        CCAction *fadeInPacksButton = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
        [_packsButton runAction:fadeInPacksButton];
        CCAction *fadeInEndButton = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
        [_nextLevelButton runAction:[CCActionSequence actions: (CCActionFiniteTime *)fadeInEndButton, [CCActionCallFunc actionWithTarget:self selector:@selector(fadeCoinElements)], nil]];
        _packsButton.enabled = true;
        _nextLevelButton.enabled = true;
    }
}

- (void)loadStarShadows
{
    // Fade in star shadows -> Call selector to load stars
    CCAction *fadeInStarShadows = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
    self.loadedStars = 0;
    
    [_starBar runAction:[CCActionSequence actions: (CCActionFiniteTime *)fadeInStarShadows, [CCActionCallFunc actionWithTarget:self selector:@selector(loadStar)], [CCActionDelay actionWithDuration:0.4], [CCActionCallFunc actionWithTarget:self selector:@selector(loadStar)], [CCActionDelay actionWithDuration:0.4], [CCActionCallFunc actionWithTarget:self selector:@selector(loadStar)], [CCActionDelay actionWithDuration:0.2], [CCActionCallFunc actionWithTarget:self selector:@selector(fadeCoinElements)], nil]];
}

- (void)loadStar
{
    if (self.loadedStars < self.stars) {
        CCSprite *star = (CCSprite *)[CCBReader load:@"Star"];
        star.position = ccp((0.4 * self.loadedStars + 0.1) * _starBar.contentSizeInPoints.width, 0.5 * _starBar.contentSizeInPoints.height);
        star.visible = false;
        [_starBar addChild:star];
        [star runAction:[CCActionSequence actions:[CCActionShow action], nil]];
        
        CCParticleSystem *particles = (CCParticleSystem *)[CCBReader load:@"Small Burst Sparkles"];
        particles.position = star.position;
        [_starBar addChild:particles];
        
        OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
        [audio playEffect:@"Star Appear Large.wav"];
    }
    self.loadedStars++;
}

- (void)fadeCoinElements
{
    // Fade in coin sprite and label
    CCAction *fadeInSprite = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
    CCAction *fadeInLabel = [CCActionFadeTo actionWithDuration:ANIMATION_DURATION opacity:1.0];
    [_coinSprite runAction:fadeInSprite];
    [_coinLabel runAction:[CCActionSequence actions:(CCActionFiniteTime *) fadeInLabel, [CCActionCallFunc actionWithTarget:self selector:@selector(resetLoadedCoins)], nil]];
}

- (void)resetLoadedCoins
{
    self.loadedCoins = 0;
}

- (void)burstStarsAgain
{
    for (int i = 0; i < self.stars; i++) {
        CCParticleSystem *burst = (CCParticleSystem *)(CCParticleSystem *)[CCBReader load:@"Medium Burst Particles"];
        burst.position = ccp((0.4 * i + 0.1) * _starBar.contentSizeInPoints.width, 0.5 * _starBar.contentSizeInPoints.height);
        [_starBar addChild:burst];
    }
    
    [self runAction:[CCActionSequence actions:[CCActionDelay actionWithDuration:0.2], [CCActionCallFunc actionWithTarget:self selector:@selector(loadBonusCoins)], nil]];
}

- (void)loadBonusCoins
{
    self.burstStarsForBonus = YES;
    self.loadedBonusCoins = 0;
}

- (void)loadCoinSound
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio setEffectsVolume:0.6];
    [audio playEffect:@"Increment 4.wav"];
    self.coinSounded = NO;
}

#pragma mark Tutorial methods

- (void)loadTutorialStep
{
    if (self.tutorialLevel == 1 && self.tutorialStepIndex == 1) {
        // Load swipe animation for first animation
        [self createSwipeAnimation];
        self.finishedActionForStep = NO;
    } else {
        // FOR TUTORIAL 2: Finish tutorial
        if (self.tutorialLevel == 2 && self.tutorialStepIndex == 1) {
            self.finishedActionForStep = NO;
        }

        [self fadeNextStep];
    }
}

- (void)fadeNextStep
{
    // Initialize next icon
    self.step = [CCSprite spriteWithImageNamed:[NSString stringWithFormat:@"Step%i.png", self.tutorialStepIndex]];
    self.step.position = ccp(_pixelContainer.position.x * [[CCDirector sharedDirector]viewSize].width, _pixelContainer.position.y* [[CCDirector sharedDirector]viewSize].height);
    self.step.cascadeOpacityEnabled = YES;
    self.step.opacity = 0.0;
    self.step.scale = 0.3;
    
    [_gameplayContainer addChild:self.step];
    
    CCAction *fadeStep = [CCActionFadeIn actionWithDuration:0.2];
    
    // IF JUST GOT ONTO TUTORIAL 1 STEP 3 (Just got first streak)
    if (self.tutorialLevel == 1 && self.tutorialStepIndex == 3) {
        fadeStep = [CCActionSequence actions:[CCActionDelay actionWithDuration:0.4], fadeStep, nil];
    }
    
    [self.step runAction:fadeStep];
    
    self.timeLookingAtStep = 0.0;
}

- (void)removeStep
{
    // Remove step
    [_gameplayContainer removeChild:self.step];
    self.stepLoaded = NO;
    self.finishedActionForStep = false;
}

- (void)incrementTutorialStep
{
    if ((self.tutorialLevel == 1 && self.tutorialStepIndex == 3) || (self.tutorialLevel == 2 && self.tutorialStepIndex == 1)) {
        self.tutorialStepIndex = 0;
    } else {
        self.tutorialStepIndex++;
    }
    
    // Save tutorial step for resume
    [[_GameState.data objectForKey:@"Level to Resume"] setObject:[NSNumber numberWithInt:self.tutorialStepIndex] forKey:@"Tutorial Step"];
    [_GameState writeToPlistInDocuments];
 }

- (void)createSwipeAnimation
{
    self.swipeAnimation = (CCSprite *)[CCBReader load:@"Touch"];
    [self initializeSwipeAnimation];
    [_gameplayContainer addChild:self.swipeAnimation];
    
    CGPoint moveToLocation = ccp((_flashingPixelMarkerNode.positionInPoints.x - _platformSprite.positionInPoints.x) / _flashingPixelMarkerNode.positionInPoints.y * (_platformSprite.contentSize.height * _platformSprite.scale - 10.0) + _platformSprite.positionInPoints.x, _platformSprite.contentSize.height * _platformSprite.scale - 10.0);
    
    CCActionSequence *sequence = [CCActionSequence actions: [CCActionCallFunc actionWithTarget:self selector:@selector(initializeSwipeAnimation)], [CCActionFadeTo actionWithDuration:0.2 opacity:0.6], [CCActionMoveTo actionWithDuration:0.8 position:moveToLocation], [CCActionFadeTo actionWithDuration:0.2 opacity:0.0], [CCActionDelay actionWithDuration:0.5], nil];
    CCActionRepeatForever *repeatedSequence = [CCActionRepeatForever actionWithAction:sequence];
    
    [self.swipeAnimation runAction:repeatedSequence];
}

- (void)initializeSwipeAnimation
{
    self.swipeAnimation.positionInPoints = ccp(PLAYING_PIXEL_WIDTH * [[CCDirector sharedDirector]viewSize].width, PLAYING_PIXEL_HEIGHT * [[CCDirector sharedDirector]viewSize].height);
    self.swipeAnimation.cascadeOpacityEnabled = YES;
    self.swipeAnimation.opacity = 0.0;
}

- (void)removeSwipeAnimation
{
    [self.swipeAnimation removeFromParent];
    self.swipeAnimation = nil;
}

@end
