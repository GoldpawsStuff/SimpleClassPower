# SimpleClassPower Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.10-Release] 2019-07-08
### Changed
- Updated back-end. 

## [2.0.9-Release] 2019-07-02
### Changed
- Updated back-end and bumped toc version WoW client patch 8.2.0.

## [2.0.8-Release] 2019-05-20
### Fixed
- The scale should now be saved between sessions. 

## [2.0.7-Release] 2019-04-27
New release with a new back-end and upgraded features!

### Changed
- The entire back-end is new. We're now basing this on the same libraries as used in AzeriteUI and the upcoming GoldpawUI6 and DiabolicUI2. It's more solid than what was before, and far easier to work with and update when we use the same core for multiple projects. What benefits one benefits all. Time saved, features gained! Wohoo! :) 

### Added
- In-game help menu. Type `/scp help` for a full list of options. 
- Optional class coloring of the resource points! 
- Optional smart hiding (old behavior), or have the frame always visible (new default).
- Dragging & scaling! You can scale the size with the mouse wheel and drag it to your desired position. This is only available when not engaged in combat, and your choices will be saved between sessions. 

## [1.0.6] 2018-08-14
### Changed
- Library updates. 

## [1.0.5] 2018-08-09
### Changed
- Many library updates. 
- Workaround for Auctionator's dumb coding style and `EnumerateFrames()` usage.

## [1.0.4] 2018-07-22
### Changed
- Library updates.

## [1.0.3] 2018-07-18
### Fixed
- Rewrote and simplified rune module to accomodate the changed event return values in 8.0.1 which eventually caused "runeData" errors. 

## [1.0.2] 2018-07-18
### Changed
- Removed deprecated files.

### Fixed
- Correct files are now loaded, which should prevent "runeData" errors. 

## [1.0.1] 2018-07-18
### Changed
- Bumped to WoW client patch 8.0.1.
- Upgraded libraries.

## [1.0.0] 2018-06-18
- Initial commit.
