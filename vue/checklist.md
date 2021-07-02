# IE Detection
- [ ] No Support message when loading on internet explorer

# Device Assignment
- [ ] Cannot revoke while assigned to asset
- [ ] Can logout operator while connected
  - [ ] must enter allocation
- [ ] Can logout operator with no connection
  - [ ] this should log tablet out on reconnect
- [ ] Icon equal to asset type/tablet
- [ ] Assign to "Not Assigned"
- [ ] Assign asset (from no asset)
- [ ] Change asset while logged in
- [ ] Revoke tablet
  - [ ] Warning message appears
- [ ] Accept new device
  - [ ] new device should have orange indicator
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
  - [ ] green - operator and ready code
  - [ ] orange - process
  - [ ] white - standby
  - [ ] gray with x - down
  - [ ] No wifi symbol - disconnected
  - [ ] blue - no operator and ready code
- [ ] change allocation
- [ ] Change source 
  - [ ] set dig unit. Location should clear
  - [ ] Location. Dig unit should clear
- [ ] Change dump location
- [ ] Clear assignment

#### Dig Units
- [ ] Active operator present
- asset icon
  - [ ] green - connected and no exception
  - [ ] orange - exception active
  - [ ] grey - offline with no exception
- [ ] Change allocation
- [ ] Change location
- [ ] Clear row

#### Other assetes
- [ ] Active operator present
- asset icon
  - [ ] green - operator and ready code
  - [ ] orange - process
  - [ ] white - standby
  - [ ] gray with x - down
  - [ ] No wifi symbol - disconnected
  - [ ] blue - no operator and ready code
- [ ] change allocation

# Location Assignment
- [ ] Other asssets closeable
- [ ] Other asset not movable, and no move cursor
- [ ] Unassigned closeable
- [ ] Check multiline of assets holds shape (ie does not stretch or break boundary)
- [ ] No popover from dragged icon
- [ ] valid source with no dump location
- [ ] no source with valid dump location
- Asset Icon
  - [ ] green - operator and ready code
  - [ ] orange - process
  - [ ] white - standby
  - [ ] gray with x - down
  - [ ] No wifi symbol - disconnected
  - [ ] blue - no operator and ready code
- Asset name bar (haul truck)
  - [ ] clear - asset offline and no operator
  - [ ] green - online and acknowledged
  - [ ] orange - online and not acknowledged
- [ ] Operator name on tile
- [ ] Unassigned route shown while no assets in it
- [ ] Unassigned route minimise
- [ ] ability to delete route if no assets present
- [ ] context menu
  - [ ] can change assignment
  - [ ] can operator time allocations
  - [ ] can operator chat (if assigned to tablet)
  - [ ] can logout operator

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
- [ ] move trucks (click dump heading)
- [ ] clear an entire dump
- [ ] move a source
- [ ] clear source

### Settings
- [ ] sort by status
- [ ] change route orientation


### Asset Tile Popover
includes the following info
- [ ] GPS location
- [ ] operator
- [ ] radio number
- [ ] connection
- haul trucks:
  - [ ] acknowledged
- [ ] allocation
- [ ] last seen


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
  - [ ] toggle alert visibility
- [ ] Clusters toggleable
- [ ] Asset selectable from dropdown
- [ ] Asset editable from popover (and that the details update)


### Info window - general
- [ ] Click to show info 
- popover shows
  - [ ] Asset name (type)
  - [ ] Operator
  - [ ] Location
  - [ ] Speed
  - [ ] Heading
  - [ ] Ignition
  - [ ] Last GPS
  - [ ] radio
  - [ ] Allocation (with duration)
- [ ] Ability to change assignment


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
- [ ] tooltip if code has already been taken
- [ ] cannot edit "No task"

### Time code groups
- [ ] Ability to set alias
- [ ] alias appears on mobile app


### Time code tree
- [ ] able to add new time code
- [ ] ability to drag time code
- [ ] ability to drag group
- [ ] ability to delete elements
- [ ] empty groups automatically removed
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


# Pre-start Editor
### Forms
- [ ] Can change section order
- [ ] Can edit section heading
- [ ] Cannot submit empty control
  - [ ] toast with reason
- [ ] Cannot submit empty sections
  - [ ] toast with reason
- [ ] Ability to submit with zero sections
- [ ] Can set category
  - [ ] dropdown should show the actions for each element
  - [ ] set cateogry should show tooltip on hover
- [ ] Ability to set "comment required"
- [ ] Can change order of control
  - [ ] can move into another section

### Editor
- [ ] Ability to create category
- [ ] update name
- [ ] update action
- [ ] Ability to change order


# Asset Status
- [ ] Check that ignition and last seen updates
- [ ] Edit radio number during update (to see if the radio number is reverted)
- [ ] Refresh page to ensure that all asset data is still there


# Engine Hours
- [ ] Request engine hours
- [ ] See engine hours update
- [ ] Ensure entered by appears
- [ ] Entered at > 24 hours ago appears red
- [ ] Correct ordering by
  - [ ] engine hours (not alphabetically)
  - [ ] Entered at (timestamp not alphabetically)
  - [ ] Entered by does not produce 'undefined'

# Time Allocation
### Asset Info Row
- [ ] try and make a popover stay open (you shouldnt be able to)
- [ ] Swapping a device should log out the operator
- open more info
  - [ ] see time allocations
  - [ ] see cycles (if available)
  - [ ] see timeusage (if available)
  - [ ] see operator logins
  - [ ] see shifts
- [ ] add report

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
- [ ] can insert new elements ontop of locked elements
- [ ] cannot merge new with locked elements
- [ ] unlock element
- [ ] lock entire shift
- [ ] unlock entire shift

# Operator Time Allocation
- [ ] black color used if logged in with no allocation
- [ ] Y axis ordered by assets alphabetically
- [ ] show breakdown production summary
  - [ ] Only productive elements by asset
- [ ] all groups
  - [ ] ability to step into groups


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
- [ ] can use quick message
- [ ] Always shows top date separator
- [ ] Date separators always have something between them
- Contact shows
  - [ ] Asset name
  - [ ] Asset icon
  - [ ] Operator
  - [ ] current time allocation
  - [ ] asset colors
    - [ ] green - operator and ready code
    - [ ] orange - process
    - [ ] white - standby
    - [ ] gray with x - down
    - [ ] No wifi symbol - disconnected
    - [ ] blue - no operator and ready code
- [ ] Can see active allocation at the bottom of the feed
- [ ] Can edit an exception (bottom edit icon)
- [ ] Show radio number on message bar (if set)
- [ ] Dispatcher message outline when not acknowledged
- [ ] Operator message outline until acknowledged (clicked)
- [ ] Searchable contact fields
- [ ] Searchable feed
- [ ] Operator message shows operator name
- [ ] "call me" message shows radio number in chat log
