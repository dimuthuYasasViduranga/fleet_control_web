## Changelog

## pending [unreleased]


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
