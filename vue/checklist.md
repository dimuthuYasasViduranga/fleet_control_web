# IE Detection
- [ ] No Support message when loading on internet explorer

# Device Assignment
- [ ] Cannot revoke while assigned to asset
- [ ] Can logout if operators but no connection
  - [ ] this should log user out on reconnect
- [ ] Logout works on connected tablet
- [ ] Icon equal to asset type/tablet
- [ ] Remove tablet
  - [ ] Warning message appears
- [ ] Assign to asset with no UI
- [ ] Assign asset (from no asset)
- [ ] Change asset while logged in
- [ ] Send logout
  - [ ] Prompted to enter exception
- [ ] Revoke tablet
- [ ] Accept new device
- [ ] Reject new device
- [ ] Accept existing device
- [ ] Ability to set device details

# Asset Assignment

#### Haul Trucks
- [ ] Active operator present
- User icon
  - [ ] green - acknowledged
  - [ ] orange - unacknowledged
- asset icon
  - [ ] green - connected and no exception
  - [ ] orange - exception active
  - [ ] grey - offline with no exception
- [ ] change allocation
- [ ] Change load location
- [ ] Change dump location
- [ ] Change next location
- [ ] Clear assignment

#### Dig Units
- [ ] Active operator present
- asset icon
  - [ ] green - connected and no exception
  - [ ] orange - exception active
  - [ ] grey - offline with no exception
- [ ] Change allocation
- [ ] Change location
- [ ] Change load style
- [ ] Clear row

#### Other assetes
- [ ] Active operator present
- asset icon
  - [ ] green - connected and no exception
  - [ ] orange - exception active
  - [ ] grey - offline with no exception
- [ ] change allocation

# Location Assignment
- [ ] Ancillary closeable
- [ ] Ancillary not movable, and no move cursor
- [ ] Unassigned closeable
- [ ] Check multiline of assets holds shape (ie does not stretch or break boundary)
- [ ] No popovers while dragging
- [ ] Scroll when dragging to bottom of page (must have enough routes)
- [ ] X -> unassigned (with asset) and X -> Y (with asset) has both showing
- [ ] X -> unassigned shown if dig unit and no haul trucks
- [ ] X -> unassigned (dig unit and no haul truck) and X - y (dig unit, haul truck) does not show unassigned
- [ ] Warning icon when in static geofence but no exception
- Truck icon
  - [ ] green - connected and no exception
  - [ ] orange - exception active
  - [ ] grey - offline with no exception
- Asset name bar
  - [ ] clear - asset offline and no operator
  - [ ] green - online and acknowledged
  - [ ] orange - online and not acknowledged
- [ ] Operator name on tile
- [ ] Unassigned route shown while no assets in it
- [ ] Unassigned route minimise
- [ ] ability to delete route if no assets present

### Create route
- [ ] create route with load and dump
- [ ] create route with no load
- [ ] create route with no dump
- [ ] create route using show all locations

### Drag dispatch
- [ ] Outline shown in placement area
- [ ] Drag to change route doesn't jump between target and existing route
- [ ] Drag to change grey flash on change
- [ ] Drag to change blue flash on second tab


### Mass dispatch
All the following are done within the edit modal
- [ ] clear should have confirm prompt
- [ ] clear should move "apply to" assets to unassigned
- [ ] accept should invoke change
- [ ] Mass change of load, no jumping and old route should be deleted
- [ ] Mass change of dump, no jumping and old route should be deleted
- [ ] Mass change of load and dump, no jumping and old route should be deleted
- [ ] Use 'show all locations' and make a change to an unusual dump and load location


### Popover
includes the following info
- [ ] location
- [ ] operator
- [ ] connection
- haul trucks:
  - [ ] acknowledged
- excavators:
  - [ ] load style
- [ ] allocation
- [ ] last seen
- [ ] warning message (when warning icon shown)


# Mine Map
- [ ] Recenter
- [ ] Reset zoom
- [ ] Satelite image
- [ ] Map image
- [ ] Static geofences drawn
- [ ] Toggle all geofences
- [ ] Asset clickable over geofence
- [ ] Selected asset dims other assets
- [ ] Operator name shown in popup
- Alerts per type
  - [ ] Process (yellow)
  - [ ] Standby (white)
  - [ ] Down (grey)
  - [ ] Emergency (orange)
  - [ ] NO allocation (purple. Only occurs on new assets)
  - [ ] toggle visibility
- [ ] Clusters toggleable
- [ ] Asset selectable from dropdown
- [ ] Asset editable from popover (and that the details update)


### Info window - general
- [ ] Click to show info 
- [ ] Click to show route path (if cluster avaiable for the area)
- popover shows
  - [ ] Asset name (type)
  - [ ] Operator
  - [ ] Location
  - [ ] Speed
  - [ ] Heading
  - [ ] Ignition
  - [ ] Time
  - [ ] Allocation
- [ ] Ability to change assignment

# Asset progress
- [ ] Asset direction (left and right)
- [ ] Other assets shown at bottom
- [ ] Assets that cannot find route shown at bottom
- [ ] warning when asset with route is in static geofence without exception
- icon
  - [ ] green - connected no exception
  - [ ] orange - active exception
  - [ ] grey - offline no exception
- popover
  - [ ] Location
  - [ ] Allocation
  - [ ] Load
  - [ ] Dump
  - [ ] Last seen


# Operators
- [ ] must have legal name
- [ ] must have employee id
- [ ] Edit operator name
- [ ] Cannot use taken employee id
- [ ] Disable operator (check that they cant log in anymore and that it logs them out)
- [ ] Enable operator (check that they can log in)

# Time Code Editor
### Time codes
- [ ] ability to change name
- [ ] create new error on duplicate code
- [ ] cannot edit "No task"

### Time code groups
- [ ] Ability to set alias
- [ ] alias appears on mobile app


### Time code tree
- [ ] able to add new time code
- [ ] ability to drag time code
- [ ] ability to drag group
- [ ] ability to delete elements
- [ ] ability to have empty groups
- [ ] removal of empty time code entries

### Time code tree matrix
- [ ] ticks for use
- [ ] hover to see asset type in box

# Message Editor
### messages
- [ ] ability to disable message
  - [ ] in-use messages should be cleared from assets that use them
- [ ] ability to override message
- [ ] ability to update (delete old and create new shortcut)

### Message Tree
- [ ] ability to have no messages
- [ ] order holds on device


### Message tree matrix
- [ ] ticks for use
- [ ] hover to see asset type in box

# Asset Status
- [ ] Check that ignition and last seen updates
- [ ] Edit radio number during update (to see if the radio number is reverted)
- [ ] Refresh page to ensure that all asset data is still there


# Engine Hours
- [ ] Request engine hours
- [ ] See engine hours update
- [ ] Ensure entered by appears
- [ ] Entered at > 24 hours ago appears red

# Time Allocation
### Asset Info Row
- [ ] try and make a popover stay open (you shouldnt be able to)
- [ ] Swapping a device should log out the operator
- open more info
  - [ ] see time allocations
  - [ ] see cycles (if available)
  - [ ] see timeusage (if available)
  - [ ] see operator logins

### Editor - create
- [ ] click on cycle element to create span
- [ ] create new element
- [ ] override new element
- [ ] ensure only a valid element can be created

### Editor - error 
- [ ] fix override
- [ ] fix delete
- [ ] fix merge

### Editor - timeline
- [ ] end latest element only
- [ ] delete element
- [ ] fill back
- [ ] fill forward
- [ ] cannot delete first element
- [ ] cannot edit first element timecode or start time

### Editor - locking
- [ ] lock element (only in shift view)
- [ ] locked element should cut at shift boundary
- [ ] can lock overlapping elements
- [ ] cannot update locked elements
- [ ] unlock element


### Add report
- [ ] test that the report can be added

# Time Allocation report
- [ ] Compliant - green
- [ ] Warn - orange
- [ ] issues - red
- [ ] No filter if there are no events

# Chat 
- [ ] test all filters (top of feed)
- [ ] Can send a message
- [ ] Can send a mass message
- [ ] Can send a question
  - [ ] And get a response
- [ ] Can send a mass question
  - [ ] And see all responses (hover over to get all assets)
- [ ] Cannot send question without 2 answers
- [ ] Always shows top date separator
- [ ] Date separators always have something between them
- Contact shows
  - [ ] Asset name
  - [ ] Asset icon
  - [ ] Operator
  - [ ] current time allocation
  - [ ] Green, orange, offline icon colors (good, exception, offline)
- [ ] Can see active allocation at the bottom of the screen
- [ ] Can edit an exception (bottom edit icon)
- [ ] Show radio number on message bar (if set)
- [ ] Dispatcher message outline when not acknowledged
- [ ] Operator message outline until acknowledged (clicked)
- [ ] Searchable contact fields
- [ ] Searchable feed
- [ ] Operator message shows operator name

# Other conditions
- [ ] Ensure that you can acknowledge initial device assignment

