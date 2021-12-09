## Changelog

## pending [unreleased]

## 0.12.0
- 💥 using next version of hps_data
  - fleetops agent uses haul instead of fleet
  - locations use new start/end structure
  - use new location types
  - material types moved from "dis_material_type" to "dim_material_type"
- 🧹 removed some unused pages
- ✨ added asset roster to show/hide assets
  - 🔒 requires the "can_edit_asset_roster" permission
- 💄 dig units now show a "loading radius" bubble around them for better feedback
- ✨ added "locate" context menu on asset tiles. Opens the minemap, centered on the target
- ✨ long click and hold on chat head allows it to be moved around

## 0.11.2
- 🐛 added redirect on 401 (ie not authenticated)

## 0.11.1
- 🔊 error log if unable to access azure graph (for authorization groups)
- 🧹 merged startup calls
- 🔒 added 'authorized' group to prevent any access without it

## 0.11.0
- 👽 updated endpoints to kube format of /fleet-control
- 🧹 merged release config params

## 0.10.20
- 🐛 fixed pdf page numbers

## 0.10.19
- 🐛 fixed pre-start pdf not considering empty comments
- 💄 better spacing on pre-start titles (alignment)

## 0.10.18
- 🐛 fixed incorrect redirect on page controller (unable to initially log in)

## 0.10.17
- 📦 updated deps
- simplified analyzing bundles

## 0.10.16
- 🚸 sorting algorithm has better ordering (especially for dropdowns)
- 🚸 removed crossover range in pre-starts (was too confusing)
- 🚸 device assignment table searchable by asset type and version
- 💄 fixed pre-start comments not going over mulitple lines
- ✨ can now access location on map (accuracy varies)
- 🐛 fixed date selector day off by 1
- ✨ added ability to download pre-start submissions as pdf
- 📦 updated/change/culled packages to reduce overall bundle size

## 0.10.15
- moved pre-start submission comments to top of viewer (easier to find/read)

## 0.10.14
- fixed "pass - has comments" not appearing for submissions with general comments only
- toast on updating device details (also has loading modal)
- refactored the secondary asset tile icon
- removed alert icon
- added "In Ready code without operator" alert to asset tile tooltip
- fixed "General Assets Table" allocation dropdown being variable size
- adding dump to source ignores already present dumps
- updated no-wifi color to yellow (stands out against process color)
- Fixed no-wifi not appearing on "asset assignment" page
- fixed dig unit in source overflowing container
- removed moving dig units between sources as the functionality was flakey
- asset name on AssetTile is green when operator is logged in (can be orange for haul trucks)
- moved chime.mp3 to public folder
- added compass directions to heading on map tooltip
- add operator "create" button dimmed until name and employee id are filled
- create/edit time code disabled create/update button unless all requires fields are entered
- added reset button to pre-start editor
- pre-start category editor
  - now refreshes after submit
  - Alerts user to duplicate name
- engine hours sorts correctly on "entered by", "engine hours" and "entered at" columns
- Added dim and toasts for request hours submissions
- relative formats now includes year
- chat contacts now filterable by asset type and secondary type

## 0.10.13

- added ability to move dig unit from/to empty source square
- move trucks works for empty dumps
- added tooltip for locked "revoke" to give reason for inaccessibility
- asset tile context menu moved to right click
- added "has comments" to submissions that have additional comments
  - report buttons show comment icon if there are comments
- added "from another shift" to pre-starts that are pulled in over the boundary
- Renamed "failures" to "concerns" for the pre-start submissions page
  - passing comments and overall comments are now displayed
- ability to sort dnd assets by status or alphabetically
- ability to logout asset from asset tiles

## 0.10.12

- explicit timestamp ordering for operator time allocation calculations
- fixed undefined being considered a valid timezone
- Assignment modal width increased
- Dig Unit Assignment 'location' now called 'target location'
- Ability to search on multiple criteria on asset time allocation page
- Added asset overview page for large tv based displays
- Added time allocation group based coloring
  - ready + online -> green
  - ready + offline -> light blue
  - process -> orange
  - standby -> white
  - down -> gray with red cross
  - not ready + offline -> grey
- Added allocation duration to map tooltip
- Added 'eye' icons for asset type filter toggles
- Added day of week to shift selector
- Added tab banner notification when unread messages + notification sound
- Fixed pre-start submission reports staying open after shift change
- Added shifts to time allocation charts
- Added ability to lock/unlock entire shifts
- Fixed oversubmitting of time allocation elements on submit
- Added context menu to drag and drop asset tiles
- Added eslint
- Added toasts to time span editor functions
- Added "move trucks" functionality when clicking on drag and drop dump name
- Removed map street control icon to fix panning issue
- Fixed GPS tracks from tablet not appending current geofence
- Added appsignal page counter for routes
- track connecting tablet client version with update time (easier to tell updated during rollout)

## 0.10.11

- fixed map not loading markers on initial load
- added +- 1 hour to pre-start submission selection range
- fixed "Add Route" in location assignment not updating dig unit load location

## 0.10.10

- map clustering defaults to off

## 0.10.9

- added radio number to map tooltip (if available)
- added asset filters
- show all assets on map (regardless of tablet assignment)
- removed "No Allocation" alert from map

## 0.10.8

- increased map asset selector dropdown size (to allow for asset type)
- fixed "refresh assets" not going to dispatcher
- centered map asset label. Removed text-wrapping
- Tile Icons
  - Service Vehicle
  - Scratchy (just excavator)
  - Light Vehicle
  - Lighting Plant
- Map Icons
  - Service Vehicle
  - Scratchy (just excavator)
  - Light Vehicle
  - Lighting Plant

## 0.10.7

- added overhead labels to map assets (can be toggled on and off)
- fixed pre-start control categories not accepting new entries
- increased dropdown size for pre-start category selector
- added tooltip to pre-start category to show action
- red text for "Last Seen" in asset tile when using full timestamp format

## 0.10.6

- fixed adding asset to track failing when :name is not present

## 0.10.5

- fixed "use device GPS" not syncing of init
- added "min" and "max" inputs to dately selector to make it easier to determine min and max
- fixed time allocation report not rendering graph
- fixed haul truck map info window not showing valid location under assignment (when not assigned to dig unit)
- changed map info window showing "ago" to "Last GPS"
- fixed mass dispatch event not reducing "No Source => No Dump" to "Unassigned"
- only 1 pre-start notification at once
- mass message
  - fixed dig units not showing their current locations
  - changed "No source => No Dump" to "Unassigned"
- fixed get state not returning operator_id when not assigned to an asset

## 0.10.4

- fixed unassigned assets (dnd route) left padding
- fixed "clear dump" removing visual, but not updating asset
- fixed smooth assignments not merging correctly
- load style hidden for dig units
- added float icon
- fixed naive compare to string in track agent
- ability to toggle use device GPS

## 0.10.3

- fixed unassigned assets display (drag and drop)
  - component css was overriding custom in build version
- added device gps as supplement to factual source (configuarable)
- added conflicting assignments toasts that navigates to device assignment

## 0.10.2

- added toast notification when pre-starts come in
- fixed mass message modal not showing dig location as source
- fixed haul truck dispatch events in chat log not appearing
- fixed chart rendering on asset report (would show blank when opened)
- force logout will initialise to active if it is not ready
- asset assignment (haul trucks) can only have dig unit or location, not both
- added smoothing for device assignments
- added breakdown to operator time allocations
  - production for simplified ready codes
  - all groups for breakdown per type
- all references to time code group use alias where available
- added :device track mode to allow device locations as source
- added "ago" to map points and asset tile tooltips
  - latency easier to determine
- added update pre-start control categories
- improved 401 re-routing when auth fails on other than root path
- added notification when assets change time allocation
- alert icon when there are unclosed/unresolved pre-starts for the shift
- added ability to set dig unit location through the DND add route selector

## 0.10.1

- fixed ticket modal width
- fixed autosize textarea breaking words
- fixed drag and drag being presented as a table
- Added multiple assets for one device notification
- fixed pre-start section/control ordering
- added last update time for ticket statuses
- added colors for ticket statuses

## 0.10.0

- added centralised timezone selector
- haul trucks can be assigned to a dig_unit OR load location
  - came with complete re-styling of drag and drag (again ...)
- custom toast implementation
  - easier to style
  - prevents spamming of disconnect/reconnect when socket falls asleep
- better auth errors
- added quick select modal for dispatcher messages
- added unknown asset type icon
- added operator time allocation page
  - this is only inferred data, not fact
- implemented pre-starts, pre-start submissions, pre-start tickets, pre-start control categories

## 0.9.0

- first consolidated version

## < 0.9.0

Before 0.9.0, phx and vue were contained within separate repositories. As such, all versions prior to this should reference those
