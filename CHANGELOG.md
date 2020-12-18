# SimpleClassPower Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.1.25-Release] 2020-12-18
### Changed
- Added back our more orange combo point color, the red was never actually intended.
- The usual amount of back-end updates.

## [2.1.24-Release] 2020-12-16
- Back-end updates.

## [2.1.23-Release] 2020-12-15
- Back-end updates.

## [2.1.22-Release] 2020-12-14
### Fixed
- Back-end update to avoid bugs when used alongside Azerite UI Collection.

## [2.1.21-Release] 2020-12-13
### Fixed
- The proper tools should now also be loaded for users that aren't blessed with the Azerite UI Collection.

## [2.1.20-Release] 2020-12-13
### Changed
- Updated back-end. 

### Fixed
- Fixed an issue with wrong names on callback events, that caused position and scale to not save.
- Width of the movable area should adjust to monks with 6 chi now. 

## [2.1.19-Release] 2020-12-09
- Various back-end updates and fixes.
- Fixed faulty changelog dates. Welcome to the future.

## [2.1.18-Release] 2020-11-30
### Fixed
- Changed how events are unregistered in the back-end, making the process a silent one by default. If modules want errors from attempting to unregister an event or message that wasn't registered to begin with, they'll have to explicitly ask for verbose output now. Otherwise, no bugs will occur and the world will go on turning as before. 

## [2.1.17-Release] 2020-11-29
- Major back-end update, fully required to remain compatible with Azerite UI Collection!

## [2.0.16-Release] 2020-11-18
- Bump to WoW client patch 9.0.2.
- Various back-end updates.

## [2.0.15-Release] 2020-10-14
- Updated the back-end to work with WoW client patch 9.0.1! 

## [2.0.14-Release] 2019-10-08
- ToC updates.
- Bump to WoW client patch 8.2.5.

## [2.0.13-Release] 2019-08-25
### Changed
- Various back-end updates. 
- Updated entries in the TOC file.  

## [2.0.12-Release] 2019-08-05
### Fixed
- Fixed a potential incompatibility with HandyNotes in the back-end. 

## [2.0.11-Release] 2019-07-31
### Changed
- Updated back-end. 

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
