Changelog
---------

pending [unreleased]
-------
- NA

0.8.7
-----
- updated pheonix js
- added re-init of channel on close
- added manual ability to disconnect channel (debug)

0.8.5
------
- added offline notification banner

0.8.4
------
###### time allocation report
  - added toasts on failure/timeout
  - added time allocation editor shortcut
  - trigger page update on allocation change
###### time allocation editor
  - fixed delete/merge/override not respecting time range bounds
  - fixed new time span showing 'undefined - undefined'
  - ability to delete first element within range


0.8.3
------
- fixed "time codes" editor not showing time codes

0.8.2
------
- fixed toasted css compile issue (colors and font)
- fixed modal close causing scroll to top of page
- fixed device info modal width
- fixed "alert" icon for no exception in statis geofence condition
- fixed location assignment not showing unassigned dump assets

0.8.0
-------
###### Asset assignment
  - other assets group for time allocation changes

###### Location assignment
  - complete rewrite (better code)
  - added "ancillary" heading
  - replaced "Add route" dropdowns with "Click to add Route" banner (now a modal)
  - x => y routes with "unassigned" are greyed out
  - ability to drag dig unit to a route (pinned on location)
  - move cursor on tiles (better user feedback)

###### Mine Map
  - Added alerts based on time allocations (outside static geofences)
  - toggle clustering
  - Long word buttons replaced with icon equivalents
  - Ability to find assets in dropdown
  - Fixed async position update performance issues
    - replaced with a group update every 10 seconds
  - Fixed stuttering panning during update

###### Operators
  - Edit now in a modal
  - "enable" operator toggle instead of "delete/restore"

###### Device assignment
  - "i" icon for additional information tagging
  - Asset types shown in place of tablet icon (where possible)
  - Shows operator assigned to asset
  - Logout requires an exception to be entered

###### Time Code Editor (Time Codes)
  - create new time codes on the fly
  - update time code names

###### Time Code Editor (Time Code Groups)
  - Ability to give aliases to time code groups (is reflected on tablet)

###### Time Code Editor (Time Code Tree)
  - Rewrite of component
  - Drag and drop functionality
  - 🐛 Empty time codes become groups called "New Leaf" upon submission

###### Time Code Editor (Time Code Tree Matrix)
  - matrix view for all assigned time codes per asset type

###### Message Editor (Messages)
  - create new messages
  - update message names
  - delete messages from use (can be re-enabled)

###### Message Editor (Message Tree)
  - drag and drop messages
  - ordering persisted

###### Message Editor (Message Tree Matrix)
  - matrix view for all messages per asset type

###### Engine Hours
  - fixed bug hidding assets with no engine hours

###### Time Allocation
  - underline to asset name (easier to seet)
  - Lock/unlock elements (while in shift view)
  - DatetimeInput replaced with Dately (in-house version) due to limitations
  - split functionality to easily split long elements
  - edit actions now icons instead of words

###### Chat
  - fixed ordering of contacts (ready, exception, offline)
  - fixed mass message styling for 250+ assets at once
  - rework mass messaging


###### General
- Cycle tally page added (unused)
- Added colors to time code groups to make it easier to navigate in dropdowns
- fixed dozer marker rotated 180deg
- fixed prettier default change
- added operator names to time allocation report
- ability to display datetimes in sitetime always (ahhhhh)

0.7.6
------
- fixed operator messages not showing operator name

0.7.5
-------
- removed closed locations from next

0.7.4
-------
- ignition shows as 'On', 'Off' or '--' (when it is unknown)
- fixed all locations checkbox not working for AddRoute (location assignment)
- added show all geofences to mine map
- Drag shows placement outline
- progress line row for pathing problems
- assignment editing from progress line
- time allocation secondary sorting by id (prevents strange 'flipping' issue when start times are equal)

0.7.3
-------
- progress line show active allocation
- fixed popover lag on drag and drop page
- conditional showing of radio number; no longer shows '--'
- fixed mass assignment "jumping"
- added route clear warning prompt (prevent accidental clicks)

0.7.2
-------
- added create + override to "create new" to reduce clicks
- added alert when exception not entered in static geofence
- updated popovers to use slots instead of html strings

0.7.1
-------
- top-down icons
  - font-end loader
  - drill
  - dozer 
  - watercart
  - scraper
  - grader
- time allocation report removes filteres when not required
- radio numbers shown on individual messaging
- progress line asset coloring and alert when in static geofence without exception


0.7.0
-------
- added logs to channel when in Dev
- all pages changed to new store design
- minemap has improved truck icons
- side-on icons
  - excavator
  - drill
  - dozer
  - watercart
  - front-end loader
  - scraper
  - grader
  - LV
- fleetops data added to time allocation editor
  - gives greater context
- time allocation reports page
  - allows users to quickly determine if there are major elements missing
- updated 'time-allocation-chart' to 'time-span' chart so that it is more general
  - can format data based on chartLayout config
  - coloring moved to function callback
  - create new elements based on clicking elements other than time-allocations
- time allocation page can expand timespan timeline on click
  - saves page from looking like a christmas tree
- ability to send questions (and get answers) to operators
- added end exception/edit asset assignment from chat
- chat feed filters now icons instead of text

0.6.2
-----
- fixed operator name not being shown without a valid nickname

0.6.1
-----
- added time code tree editor
- added task history debug page
- added allocation page
  - edit time allocations
  - vue time allocations per asset
  - view/edit past 12 hours and per shift
- can collapse 'unassigned' route heading
- dropdowns replaced with searchable ones
- simplified scroll-lock for modals

0.5.1
-----
- operators page
  - handle authorization error
  - rename "nickname" -> "name" for HR reasons

0.5.0
-----

- fixed mass message asset names not appearing in order
- fixed message log exposing border color on corner wedges
- fix for notification bar opacitiy not showing up in production built css
- radio numbers stored separate from assets
- asset status shows for all assets, not just those with assigned devices
- operators
  - added optional nicknames
  - ability to update name
  - deleted operators not hidden (shown in italics)
  - custom search bar for better table performance
  - new modal to add new operator
- added date separator to chat log (stays even when filtering)
- added mass dispatch type in chat log (reduces clutter)
- confirmation modal added to revoke a device. Cannot revoke when device is assigned to asset
- fixed radio numbers not staying/updating on asset status
- added login/logout and device assigned/unassigned messages in the chat
- fixed engine hours page having the wrong title
- removed assigned operator for asset assignment page
- operator nicknames shown where possible

0.4.0
-----

- asset progression line
- added individual assignment ability on the drag-and-drop page
- clickable notification bar added when there are outstanding messages
- engine hours list added
- ability to set load/dump to any given location (helpful for rehab/unique cycles)
- unread operator messages displayed as yellow outline of message count
- mass messaging
  - select asset/route/assignment
  - messages grouped in message feed

0.3.0
-----

- added timestamp to assignment submission
- refactored UUID formatting function
- changing a devices asset now its own channel topic
- message box sends timestamp to stop race condition
- drag-and-drop
  - icons now show no bar colour when logged out
  - routes
    - added clear all button (trash icon)
    - added popups over icons to show action name

0.2.2
-----

- removed rouding from modals (now straight edges)
- removed clear button from feed search (people thought this was the close button)
- added cursor pointers
- bubble component accepts color
- removed red for delays, moved to orange
- fixed unread not hiding when 0 on contacts in chat overlay
- ability to mass assign/change/clear routes in drag-and-drop

0.2.0
-----

- device authorization
  - table showing outstanding actions
  - allow authorization button (open for 1 minute)
  - close authorization button
- add/delete/upsert operators
- loading wheel when socket is disconnected
- ability to force logout device remotely
- `esc` closes modal
- re-ordered routes
- added route whitelist

0.1.0
-----

- project init
- basic dispatch tabular view
  - show operator logged in to assets
  - clear assignment button
  - icons
    - asset (grey - offline, green - online, red - delay)
    - asset name (green - acknowledged, orange - unacknowledged)
    - operator name (red - miss-matched operator assignments)
    - v-popover with same information
- phoenix presence
- set haultrax icon
- added dispatcher channel
- device assignment page
- drag-and-drop truck icons for dispatching
  - create new run 
  - remove empty run
- basic messaging (message box on all pages)
- acknowledged === red when unread messages
- add operators view
- activity log added (short term log of 'what has been happening')
- use of v-tooltip
- orange icon for delays
- basic delays
- added map view
- chat overlay
  - contact list
  - feed filter
  - message feed
  - message box
- floating chat access head
- heading chat access button