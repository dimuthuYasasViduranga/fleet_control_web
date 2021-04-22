## Changelog

## pending [unreleased]
- added toast notifications when pre-starts come in
- added alert for unclosed tickets on the submission page
- fixed mass messaging not showing dig units as source

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

Before 0.9.0, phx and were contained within separate repositories. As such, all versions prior to this should reference those
