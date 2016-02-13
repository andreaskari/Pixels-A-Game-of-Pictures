//
//  GameState.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/16/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameState.h"

@implementation GameState

static GameState *sharedAwardCenter = nil;    // static instance variable

+ (GameState *)sharedCenter {
    if (sharedAwardCenter == nil || sharedAwardCenter.resetPlist) {
        // Delete plist in documents, if necessary
        if (sharedAwardCenter.resetPlist) {
            [sharedAwardCenter deletePlistInDocuments];
        }
        
        sharedAwardCenter = [[super allocWithZone:NULL] init];
    }
    return sharedAwardCenter;
}

- (id)init {
    if ( (self = [super init]) ) {
        [self copyPlistToDocuments];
        [self readPlistInDocuments];
        self.unlockPackageIndex = -1;
    }
    return self;
}

- (void)copyPlistToDocuments
{
    //        1) Create a list of paths.
    //        2) Get a path to your documents directory from the list.
    //        3) Create a full file path.
    //        4) Check if file exists.
    //        5) Get a path to your plist created before in bundle directory (by Xcode).
    //        6) Copy this plist to your documents directory.
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //1
    NSString *documentsDirectory = [paths objectAtIndex:0]; //2
    self.pathToPList = [documentsDirectory stringByAppendingPathComponent:@"Game Data.plist"]; //3
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath: self.pathToPList]) //4
    {
        NSString *pathToResourcesPlist = [[NSBundle mainBundle] pathForResource:@"Game Data" ofType:@"plist"]; //5
        
        [fileManager copyItemAtPath:pathToResourcesPlist toPath: self.pathToPList error:&error]; //6
    }
}

- (void)readPlistInDocuments
{
    // Get Package & it's index
    self.data = [NSMutableDictionary dictionaryWithContentsOfFile:self.pathToPList];
}

- (void)writeToPlistInDocuments
{
    [self.data writeToFile: self.pathToPList atomically:YES];
    //BOOL success = [self.data writeToFile: self.pathToPList atomically:YES];
    //NSLog(@"Saved to plist! %i", success);
}

- (void)deletePlistInDocuments
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.pathToPList error:NULL];
}

- (void)addCoinsToDisplayLater:(int)coins
{
    int previousCoins = [[self.data objectForKey:@"Nondisplayed Coins"] intValue];
    [self.data setValue:[NSNumber numberWithInt:previousCoins + coins] forKey:@"Nondisplayed Coins"];
}

- (void)addNondisplayedCoinsToDisplayed
{
    int nondisplayedCoins = [[self.data objectForKey:@"Nondisplayed Coins"] intValue];
    int displayedCoins = [[self.data objectForKey:@"Displayed Coins"] intValue];
    [self.data setValue:[NSNumber numberWithInt:displayedCoins + nondisplayedCoins] forKey:@"Displayed Coins"];
    [self.data setValue:@0 forKey:@"Nondisplayed Coins"];
}

- (void)subtractRemovalCoinsFromDisplayed
{
    int removedCoins = [[self.data objectForKey:@"Coins For Removal"] intValue];
    int displayedCoins = [[self.data objectForKey:@"Displayed Coins"] intValue];
    [self.data setValue:[NSNumber numberWithInt:displayedCoins - removedCoins] forKey:@"Displayed Coins"];
    [self.data setValue:@0 forKey:@"Coins For Removal"];
}

@end
