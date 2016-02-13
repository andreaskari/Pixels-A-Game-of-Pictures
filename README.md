# PixelGun

## Author

Andre Askari ([JustAskAndre@gmail.com](mailto:JustAskAndre@gmail.com))

## Description

Pixels is a game where users create a picture by shooting pixels into place onto a grid before the timer runs out. With every completed picture, users get a rating out of 3 stars on their performance in the level and also a series of coins to buy future packages of pictures to complete.

As pixels are shot from the dashboard below onto the screen, the timer is replenished just a little bit but players will need to rely on streaks of pixels (without missing) to beat the levels. With every streak of 5 pixels, not only is more time rewarded but some pixels are automatically placed on the screen helping complete the picture faster.

## Screenshots

<img src="Description Pictures/IMG_4407.PNG" height="400" alt="Screenshot"/>

<img src="Description Pictures/IMG_4408.PNG" height="400" alt="Screenshot"/>

<img src="Description Pictures/IMG_4410.PNG" height="400" alt="Screenshot"/>

<img src="Description Pictures/IMG_4411.PNG" height="400" alt="Screenshot"/>

## What's working
* Basic gameplay
  * Pixel loading
  * Shooting mechanism (uses collision detector)
  * Loading menus (pause, nextLevel)
  * End of game result
    * After winning
    * After losing
  * Timer
  * Shooting range limitation
  * Bonuses
* Packages Scene
  * Scrolling
  * Swiping
  * Tapping (uses location sensing and not actual object recognition)
  * Loading packages and levels
  * Buying packages

## Analytics
* Level Completed (completedLevel)
  * stars
  * level
  * pack name
* Pack Completed (completedPack)
  * pack name
* Level Failed (failedLevel)
  * missed pixels
  * level
  * pack name
* Purchased Pack (purchasedPack)
  * pack name
* Tutorial Step (viewedTutorialStep)
  * level
  * duration viewed


## To Be Implemented

### Major Features
* Multiplier Display
* Pause gameplay when goes into background
* Sound effects
* Settings page
* Credits page
* MGWU SDK (Deprecated)
  * Social network implementation
* Packs Scrolling/swiping recognition implementation
  * Fix bug for currentTile
    * Realign if more than one action at a time
  * Fix bug with moving tiles animation onEnter
* Tons of packs

### Minor Misc. Features
* Slightly harder for 3 stars
* Fixed bug for purchased pack
* Made it harder to earn stars
* Add fake pack to plist and then add new objects to plist stored in documents
* Add Social Media Pack

### UI Improvements
* Interaction for locked package
  * Flash red
  * More tint?
* Sounds
  * Bonuses
  * Coin load (for package scene and end of level)
* Slide back to menu
* Analytics
* Tutorial introduction

### Bugs
* Scroll while tiles load/move

### Future Analytics
* Tutorial
  * Whether fails tutorial or beats level without completing tutorial
  * Whether skips tutorial
* Levels and packs unlocked
* Retention rate
* Facebook posts, tweets, google+ shares
