# PixelGun

## Features
* PackageScene

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

### Today

+ Slightly harder for 3 stars
+ Fixed bug for purchased pack
+ Made it harder to earn stars

* Make packs more expensive
* Add fake pack to plist and then add new objects to plist stored in documents
* Add Social Media Pack

* Bugs
  * Scroll while tiles load/move
* Interaction for locked package
  * Flash red
  * More tint?
* Sounds
  * Bonuses
  * Coin load (for package scene and end of level)
* Slide back to menu
* Analytics
* Tutorial introduction

### Expansion
* Multiplier Display
* Pause gameplay when goes into background
* Sound effects
* Settings page
* Credits page
* MGWU SDK
  * Social network implementation
* Packs Scrolling/swiping recognition implementation
  * Fix bug for currentTile
    * Realign if more than one action at a time
  * Fix bug with moving tiles animation onEnter
* Tons of packs

* Multiplayer
* More reward factor for streaks
  * Physical reward?
  * Animations and effects response?

## Analytics
* Tutorial
  * Whether fails tutorial or beats level without completing tutorial
  * Whether skips tutorial
+ Levels and packs unlocked
+ Retention rate
* Facebook posts, tweets, google+ shares
