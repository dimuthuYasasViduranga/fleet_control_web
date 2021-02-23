Changelog 
--------- 

pending [unreleased] 

0.8.2
------
- removed tally and tally page from haul truck app

0.8.1
------
- Added UUID to fallback pages

0.8.0
------
- tally page for manual cycle entry (grange)
- engine hours page now an engine hours modal
- ability to prompt for engine hours at loging/logout
- added network indicator on login (ability to test internet connection)
- submit device details on device authorization
- updated phoenix.js (hopefully fixes socket disconnect issues)
- removed task selector
  - replaced with single allocation bar
- Added excavator, watercart and default application
- Added clock to header bar (with clickable modal)
  - contains user information
- Header words replaced with icons
- Messagings and Engine hours now a modal
- fixed hard reconnect issue (attempts after 60 seconds)
- added radio number page


0.7.4
-----
- fixed destination selector not showing "clear" option
- $modalBus.closeAll() works as expected
- free pan on map no longer follows updates

0.7.3
-----
- disabled markingMode for android (much better performance)
  - WARNING: marking mode 'none' means creating native objects might get GCd if the reference is not concrete
- fixed dispatch acknowledgements not being store-and-forwarded
- fixed exception banner not disappearing offline
- fixed tilt not holding in follow mode on map
- Added a count of entries in "debug/show store"
- Fixed "next -> done" on keyboard of engine hours confirm 

0.7.2
-----
- Show 'dev' if not version is given on login screen
- Fix debug mode password not hiding extra info

0.7.1
-----
- Rework of all modals (now consitant component)
- Added battery monitoring
- Added "Keep awake" while device is charging
- Added "No Recent Messages" when nothing to display on dispatcher message page
- Better destination select click region (on map)
- Added maintenance as a static geofence to map

0.7.0
-----
- store expansion. Complete re-write
- channel accessible globally (this.$channel)
- better channel logging while in DEV
- centralized sending stored data
  - added 'in-transit' flags to prevent sending data multiple times
- increased header bar size (where exceptions are shown)
- engine hours accepts decimals and has better variation handling
- global termination of open modals
- debug modal can view store data
- map rework
  - ability to calculate route (if clusters present)
- added ability to answer dispatcher questions

0.6.1
-----
- cannot logout without having an active delay
- increased exception subgroup size
- increased loading spinner hide delay
- fixed engine hours icon not taking user to correct page
- ability to log a user out even when not connected

0.6.0-alpha-1
-----
- folder structure rework
- logos not shown on login screen
- added task selection
- added exceptions
- exception banner (when exception is active)

0.5.0
-----

- tablets with no assigned asset show a "No Asset" screen
- engine hours
  - fixed crash when device not assigned to asset
  - error message if hours entered include '-' or '.'
  - check if engine hours are less than existing
  - check if engine hours are greater than existing + hours since entry
- more routes buttons can be disabled
- asset assignment changes trigger a re-init 
- tablet logout attempt on device shutdown (effectiveness depends on comms)
- nav bar shows operator nickname, if available
- acknowledge bar dims when not required
- removed invalid css ('inherit' not supported)
- debug modal can be used to change restart policy for crashes
- login modal attempts extended (~5 minutes worth)
- login modal text renamed to 'Awaiting comms'
- header buttons slightly taller (easier to click)
 
0.4.0 
----- 
 
- reconnect modal when long-offline (fix for permanent disconnect) 
- added timestamps for incoming messages (gives how long ago the message was recieved) 
- engine hours shows local value while offline (readable store and forward) 
- fixed stored acknowledgedments miss-spelling causing crash 
- odometer icon shown on dispatch page if engine hours are more than 24 hours old 
- added debug modal (holds additional helpful functions while on the ground testing/debugging) 
- added wifi indicator colours 
- added initial login have 10 attempts 
- logout icon now black stroke 
 
0.3.0 
----- 
 
- fixed successful loging showing "Cannot connect" 
- explicit channel destruction method 
- ability to programatically restart the application (used on crashes) 
- store holds data stored on disk 
- parent-child communication to dispatch page used so that objects are not mutated by child 
- messages submitting to `submit messages` instead of `submit message` 
- settings icon updated to `cog` instead of `i` 
- added `...` for more nav buttons 
- explicit background color for button class 
- logout word changed to door icon 
- added basic engine hours page 
 
0.2.1 
----- 
 
- added count of unread messages on message list 
- added icons ability to dispatch page 
- added `unread messages` icon 
  - clicking on it show the number of unread messages 
- set long offline colour to orange 
 
0.2.0 
----- 
 
- device authorization button 
- try catch for spinner (defence against crashes) 
- authChannel for authorization handling 
- font size changes 
- authorization feedback 
- av player (audio) rename and file location change 
- reduced red offline outline to 45 seconds 
- clear login error on login submit 
- added confirmation on logout (yes/no) 
- removed delay tab (currently not being used) 
- increased volume of notification sound file 
 
0.1.0 
----- 
 
- init project 
- haultrax spashscreen 
- join operator channel 
- basic login 
- basic messaging 
- basic delays 
- added next location 
- toasts for submissions 
- red-text for operator miss-match 
- updated to cli v6.0 
- added spinner class for loading 
- added device info popout 
- added accessible version number 
- ability to clear cache 
- jump-back timer set at 10 seconds 
- added store and forward for all submission types 
- ability to recieve force logout 
- enforced landscape in manifest 
- notification sounds 
- repeating sound after 30 seconds of unacknowledged 
- border colours to indicate offline (grey and red)