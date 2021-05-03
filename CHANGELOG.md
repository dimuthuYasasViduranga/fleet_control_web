## Changelog

## pending [unreleased]
- added toast notifications when pre-starts come in
- added alert for unclosed tickets on the submission page
- fixed mass messaging not showing dig units as source
- fixed haul truck dispatch logs not showing all changes
- fixed time allocation editor not rendering for time_allocation_report shortcut
- fixed force logout requiring exception
  - initial set if already in exception (ie not ready)
- updated toaster again to fit customization
- ability to change dig unit location in one operation through DND page
- fixed haul truck assignment table only allowing EITHER dig_unit or load_id
- Added other asset types, regardless of tablet assignment
- smoothed operator time allocation segments
  - removed needless reconnect separations
- added breakdown table to operator time allocation page
- added production summary to simplify readies through the day
- added time code group alias to all locations
- allow track points to be sourced from devices

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
