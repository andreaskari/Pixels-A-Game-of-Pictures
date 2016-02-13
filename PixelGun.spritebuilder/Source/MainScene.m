//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "GameState.h"

@interface MainScene ()
{
    GameState *_GameState;
    
    CCNodeGradient *_gradientNode;
    CCPhysicsNode *_physicsNode;
    CCNode *_mainSceneContainer;
    CCNode *_labelContainer;
    CCNode *_creditsContainer;
    
    CCNode *_labelNode;
    
    CCNodeColor *_largeSquare1;
    CCNodeColor *_largeSquare2;
    CCNodeColor *_largeSquare3;
    CCNodeColor *_mediumSquare1;
    CCNodeColor *_mediumSquare2;
    CCNodeColor *_mediumSquare3;
    CCNodeColor *_smallSquare1;
    CCNodeColor *_smallSquare2;
    
    CCButton *_startCreditsButton;
    CCButton *_exitCreditsButton;
}

// For squares
@property NSMutableArray *squaresInBackground;

// For swipe gestures
@property UISwipeGestureRecognizer *swipeRight;
@property UISwipeGestureRecognizer *swipeLeft;

// For credits
@property CGFloat returnHeight;
@property BOOL loopCredits;

@end


@implementation MainScene

static const CGFloat SQUARE_VELOCITY = 20.0;

static const CGFloat SPACE_FROM_BORDERS = 50.0;

static const CGFloat FADE_ACTION_DURATION = 0.5;

- (void)didLoadFromCCB
{
    _GameState = [GameState sharedCenter];
    _GameState.accessedPackageIndex = 0;
    
    // Disable exit button
    _exitCreditsButton.enabled = false;
    
    // Initialize labelContainer and buttons for fades
    _labelContainer.cascadeOpacityEnabled = YES;
    _startCreditsButton.cascadeOpacityEnabled = YES;
    _exitCreditsButton.cascadeOpacityEnabled = YES;
    _exitCreditsButton.opacity = 0.0;
    
    NSArray *squares = @[_largeSquare1, _largeSquare2, _largeSquare3, _mediumSquare1, _mediumSquare2, _mediumSquare3, _smallSquare1, _smallSquare2];
    
    // Set color, velocity and location of ccnodecolors
    for (int i = 0; i < squares.count; i++) {
        CCNodeColor *currentSquare = [squares objectAtIndex:i];
        [self initializeSquare:currentSquare behindBorders:NO];
        [self setSquareVelocity:currentSquare];
    }
    
    // Recognizer for swipes
    self.swipeRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipedRight)];
    self.swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:self.swipeRight];
    
    self.swipeLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipedLeft)];
    self.swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:self.swipeLeft];
    
    // Add infinite loop for label
    _labelNode.cascadeOpacityEnabled = YES;
    _labelNode.opacity = 0.0;
    CCActionSequence *repeatedSequence = [CCActionSequence actions:[CCActionFadeIn actionWithDuration:1.0], [CCActionDelay actionWithDuration:1.0], [CCActionFadeOut actionWithDuration:1.0], nil];
    [_labelNode runAction:[CCActionRepeatForever actionWithAction:repeatedSequence]];
    
    // Reset plist
    [self reset];
}

- (void)swipedRight
{
    CCTransition *sideSwipe = [CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:0.3];
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"PackageScene"] withTransition:sideSwipe];
    [[[CCDirector sharedDirector] view] removeGestureRecognizer:self.swipeRight];
    [[[CCDirector sharedDirector] view] removeGestureRecognizer:self.swipeLeft];
}

- (void)swipedLeft
{
    CCTransition *sideSwipe = [CCTransition transitionPushWithDirection:CCTransitionDirectionLeft duration:0.3];
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"PackageScene"] withTransition:sideSwipe];
    [[[CCDirector sharedDirector] view] removeGestureRecognizer:self.swipeRight];
    [[[CCDirector sharedDirector] view] removeGestureRecognizer:self.swipeLeft];
}

- (void)update:(CCTime)delta {
    NSArray *squares = @[_largeSquare1, _largeSquare2, _largeSquare3, _mediumSquare1, _mediumSquare2, _mediumSquare3, _smallSquare1, _smallSquare2];
    
    // If any square goes out of bounds, re-create it with new colors behind corders and set its velocity
    for (int i = 0; i < squares.count; i++) {
        CCNodeColor *currentSquare = [squares objectAtIndex:i];
        if (currentSquare.position.x < SPACE_FROM_BORDERS * -1.0 || currentSquare.position.y > [[CCDirector sharedDirector]viewSize].height + SPACE_FROM_BORDERS) {
            [self initializeSquare:currentSquare behindBorders:YES];
            [self setSquareVelocity:currentSquare];
        }
    }
    
    // Have credits roll up if loaded
    if (self.loopCredits) {
        for (int labelIndex = 0; labelIndex < [_creditsContainer children].count; labelIndex++) {
            // Increment each label upward
            CCLabelTTF *label = (CCLabelTTF *)[[_creditsContainer children] objectAtIndex:labelIndex];
            label.position = ccp(label.position.x, label.position.y + LABEL_INCREMENT_RATE);
            
            // If label is above bound, then loop back to bottom
//            if (label.position.y > [[CCDirector sharedDirector]viewSize].height + END_LABEL_BOUND) {
//                label.position = ccp(label.position.x, self.returnHeight + [[CCDirector sharedDirector]viewSize].height - END_LABEL_BOUND);
//                [label removeFromParent];
//                [_creditsContainer addChild:label];
//            }
        }
        // If the last label is above bound, remove credits
        CCLabelTTF *lastLabel = (CCLabelTTF *)[[_creditsContainer children] objectAtIndex:[[_creditsContainer children] count] - 1];
        if (lastLabel.position.y > [[CCDirector sharedDirector]viewSize].height + END_LABEL_BOUND) {
            [self exitCredits];
        }
    }
}

- (void)initializeSquare:(CCNodeColor *)square behindBorders:(BOOL)generateBehindBorders
{
    CGFloat red = (float) (arc4random() % 100) / 100.0;
    CGFloat green = (float) (arc4random() % 100) / 100.0;
    CGFloat blue = (float) (arc4random() % 100) / 100.0;
    //NSLog(@"%g, %g, %g", red, green, blue);
    
    // Generate behind the borders
    if (generateBehindBorders) {
        int locater = arc4random() % 2;
        if (locater == 0) {
            int xPosition = arc4random() % (int)[[CCDirector sharedDirector]viewSize].width + SPACE_FROM_BORDERS;
            square.position = ccp(xPosition, SPACE_FROM_BORDERS * -1.0);
        } else {
            int yPosition = arc4random() % (int)[[CCDirector sharedDirector]viewSize].height - SPACE_FROM_BORDERS;
            square.position = ccp([[CCDirector sharedDirector]viewSize].width + SPACE_FROM_BORDERS, yPosition);
        }
    }
    // Generate anywhere on the board
    else {
        int xPosition = arc4random() % (int)[[CCDirector sharedDirector]viewSize].width;
        int yPosition = arc4random() % (int)[[CCDirector sharedDirector]viewSize].height;
        square.position = ccp(xPosition, yPosition);
    }
    //NSLog(@"Positions: %f, %f", square.position.x, square.position.y);
    square.color = [CCColor colorWithRed:red green:green blue:blue];
}

- (void)setSquareVelocity:(CCNodeColor *)square
{
    // Each square moves linear
    square.physicsBody.angularVelocity = 0.0;
    square.rotation = 0.0;
    
    // Set each square velocity
    if (square.boundingBox.size.width == 20.0) {
        square.physicsBody.velocity = ccp(SQUARE_VELOCITY * -1.0, SQUARE_VELOCITY);
    } else if (square.boundingBox.size.width == 30.0) {
        square.physicsBody.velocity = ccp(SQUARE_VELOCITY * -2.0, SQUARE_VELOCITY * 2.0);
    } else {
        square.physicsBody.velocity = ccp(SQUARE_VELOCITY * -4.0, SQUARE_VELOCITY * 4.0);
    }
}

- (void)reset
{
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    [audio playEffect:@"Tap.wav"];
    
    _GameState.resetPlist = YES;
    _GameState = [GameState sharedCenter];
}

- (void)credits
{  
    [self startCredits];
}

#pragma mark Credits Methods

// For Credit Label Placement
static const CGFloat SPACE_FROM_EACH_HEADER = 80.0;
static const CGFloat SPACE_FROM_EACH_ITEM = 50.0;
static const CGFloat SPACE_FROM_ITEM_TO_PIECE = 25.0;
static const CGFloat SPACE_FROM_PIECE_TO_ARTIST = 20.0;

static const CGFloat FIRST_HEADER_PLACE = -30.0;
static const CGFloat END_LABEL_BOUND = 30.0;
static const CGFloat LABEL_INCREMENT_RATE = 1.0;

// For Credit Label Fonst Size
static const CGFloat HEADER_FONT_SIZE = 30.0;
static const CGFloat ITEM_FONT_SIZE = 22.0;
static const CGFloat PIECE_FONT_SIZE = 18.0;
static const CGFloat ARTIST_FONT_SIZE = 18.0;

- (void)startCredits
{
    if (!self.loopCredits) {
        // Allow credits to loop
        self.loopCredits = YES;
        
        // Disable start button and enable exit button
        _startCreditsButton.enabled = false;
        _exitCreditsButton.enabled = true;
        
        // Fade in exit button and fade out labelContainer and start button
        CCAction *fadeOutLabelContainer = [CCActionFadeTo actionWithDuration:FADE_ACTION_DURATION opacity:0.0];
        [_labelContainer runAction:fadeOutLabelContainer];
        
        CCAction *fadeOutStartCreditsButton = [CCActionFadeTo actionWithDuration:FADE_ACTION_DURATION opacity:0.0];
        [_startCreditsButton runAction:fadeOutStartCreditsButton];
        
        CCAction *fadeInExitButton = [CCActionFadeTo actionWithDuration:FADE_ACTION_DURATION opacity:1.0];
        [_exitCreditsButton runAction:fadeInExitButton];
        
        // Create path to the plist and read from it (in the application bundle)
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"plist"];
        NSArray *allCredits = [[NSMutableArray alloc] initWithContentsOfFile:path];
        
        CGFloat currentPlace = FIRST_HEADER_PLACE;
        
        for (int headerIndex = 0; headerIndex < allCredits.count; headerIndex++) {
            NSDictionary *headerCredits = [allCredits objectAtIndex:headerIndex];
            
            // Create Header label
            CCLabelTTF *headerLabel = [[CCLabelTTF alloc] initWithString:[headerCredits objectForKey:@"Header"] fontName:@"Futura-Medium" fontSize:HEADER_FONT_SIZE];
            headerLabel.position = ccp(0.5 * [[CCDirector sharedDirector]viewSize].width, currentPlace);
            [_creditsContainer addChild:headerLabel];
            
            NSArray *titleCredits = [headerCredits objectForKey:@"Credits"];
            for (int titleIndex = 0; titleIndex < titleCredits.count; titleIndex++) {
                NSDictionary *itemCredits = [titleCredits objectAtIndex:titleIndex];
                
                // Create Item label
                CCLabelTTF *itemLabel = [[CCLabelTTF alloc] initWithString:[itemCredits objectForKey:@"Item"] fontName:@"Futura-Medium" fontSize:ITEM_FONT_SIZE];
                currentPlace -= SPACE_FROM_EACH_ITEM;
                itemLabel.position = ccp(0.5 * [[CCDirector sharedDirector]viewSize].width, currentPlace);
                [_creditsContainer addChild:itemLabel];
                
                // Create Piece label
                CCLabelTTF *pieceLabel = [[CCLabelTTF alloc] initWithString:[itemCredits objectForKey:@"Piece"] fontName:@"Futura-Medium" fontSize:PIECE_FONT_SIZE];
                
                //CCLabelTTF *pieceLabel = [[CCLabelTTF alloc] init];
                
                currentPlace -= SPACE_FROM_ITEM_TO_PIECE;
                
                //            pieceLabel.dimensions = CGSizeMake([[CCDirector sharedDirector]viewSize].width, PIECE_FONT_SIZE + 10.0);
                //            pieceLabel.adjustsFontSizeToFit = true;
                //
                //            pieceLabel.fontName = @"Futura-Medium";
                //            pieceLabel.fontSize = PIECE_FONT_SIZE;
                //            pieceLabel.horizontalAlignment = kCCTextAlignmentCenter;
                //            pieceLabel.string = [itemCredits objectForKey:@"Piece"];
                
                pieceLabel.position = ccp(0.5 * [[CCDirector sharedDirector]viewSize].width, currentPlace);
                [_creditsContainer addChild:pieceLabel];
                
                // Create Artist label
                CCLabelTTF *artistLabel = [[CCLabelTTF alloc] initWithString:[NSString stringWithFormat:@"by %@", [itemCredits objectForKey:@"Artist"]] fontName:@"Futura-MediumItalic" fontSize:ARTIST_FONT_SIZE];
                currentPlace -= SPACE_FROM_PIECE_TO_ARTIST;
                artistLabel.position = ccp(0.5 * [[CCDirector sharedDirector]viewSize].width, currentPlace);
                [_creditsContainer addChild:artistLabel];
            }
            
            currentPlace -= SPACE_FROM_EACH_HEADER;
        }
        
        // Find last label and store vertical position
        self.returnHeight = currentPlace;
    }
}

- (void)exitCredits
{
    if (self.loopCredits) {
        self.loopCredits = NO;
        
        // Enable start button and disable exit button
        _startCreditsButton.enabled = true;
        _exitCreditsButton.enabled = false;
        
        // Fade in labelContainer and start button and fade out exit button
        CCAction *fadeInLabelContainer = [CCActionFadeTo actionWithDuration:FADE_ACTION_DURATION opacity:1.0];
        [_labelContainer runAction:fadeInLabelContainer];
        
        CCAction *fadeInStartCreditsButton = [CCActionFadeTo actionWithDuration:FADE_ACTION_DURATION opacity:1.0];
        [_startCreditsButton runAction:fadeInStartCreditsButton];
        
        CCAction *fadeOutExitCreditsButton = [CCActionFadeTo actionWithDuration:FADE_ACTION_DURATION opacity:0.0];
        [_exitCreditsButton runAction:fadeOutExitCreditsButton];
    
        [_creditsContainer removeAllChildren];
        
        _labelContainer.visible = true;
        
        _startCreditsButton.visible = true;
        _exitCreditsButton.visible = false;
    }
}

@end
