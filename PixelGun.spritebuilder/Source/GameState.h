//
//  GameState.h
//  PixelGun
//
//  Created by Andre Askarinam on 7/16/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameState : NSObject

@property NSString *pathToPList;
@property NSDictionary *data;

@property NSMutableDictionary *accessedPackage;
@property int accessedPackageIndex;
@property int accessedLevelIndex;

// For coins
@property int displayedCoins;
@property int coinsForRemoval;

// For packages unlocked in game
@property int unlockPackageIndex;

// For PackageScene
@property BOOL packMovementEnabled;

// For Game Data reset
@property BOOL resetPlist;

+ (GameState *)sharedCenter;   // class method to return the singleton object

- (void)copyPlistToDocuments;
- (void)readPlistInDocuments;
- (void)writeToPlistInDocuments;
- (void)deletePlistInDocuments;

- (void)addCoinsToDisplayLater:(int)coins;
- (void)addNondisplayedCoinsToDisplayed;
- (void)subtractRemovalCoinsFromDisplayed;

@end
