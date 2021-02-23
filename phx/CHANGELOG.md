Changelog
---------

pending [unreleased]
-------

0.8.6
-------
- fixed current dig unit activity being reset after 24 hours

0.8.4
-------
- fixed device auth reject crash
- faster time usage queries

0.8.3
-------
- removed jobs
- added connection type (active, connected, with times) 

0.8.0
-------
- huge number of tests
- renamed 'dis_dispatch' to 'dis_haul_dispatch'
- logout redirect fix
- @authorized decorator to add authentication to channel topics
- ability to set device details on the device table
- ability to refresh agents (in case of race/waiting for slow update)
- send timezone within static data
- added tally sheet (grange)
- added excavator activities
- removed task_history
- edit time codes
- lock/unlock time allocations
- removed umbrella structure
- message editing
- prevent users multi-logging
- HpsDiaptchData merged into HpsData
- ability to mock asset tracks (dev only)

0.7.5
-------
- next location data fetch moved to tasks (prevents timeouts)

0.7.4
-------
- fixed tracks not being sent to tablet
- ability to specify latest gps data source (gps_gate or replicated)
- track broadcasting is now async
- fixed cluster routing returning invalid while at destination
- removed location matching with 'closed' locations

0.7.3
-------
- unassigning an asset sets its task to "no-task"
- fixed device assignment not removing operator

0.7.2
-------
- increased poll time for track sub (api issues)

0.7.1
-------
- null asset removed from device assignment
- migration added to change device-assignment centricity (device -> asset centric)
- fixed track sub using wrong asset id

0.7.0
-------
- topics changed from 'update' to 'set'
- track data stored
  - fixed ignition being incorrect
- send all operator messages to device, not just unread ones
- Added asset types and icons to device assignment page
- device assignment re-work to make it asset centric
- added fleetops data endpoints/store
- added time allocation report generation
- added answers/answer to dispatcher messages

0.6.1
----
- tables
  - time codes
  - time code groups
  - time code tree
  - exceptions
  - tasks
- fixed confusing relationship between 'asset' and 'dim asset' in some places
  - everything now uses 'asset'
- repo no longer starts automatically
- added ability to start/end/update time allocations
  - microseconds stripped to make it easier for uses to input values
- protection added if submitted dispatch has not changed
- added auto-updating
  - calendar agent
  - location agent
- migrations now start repo
- fixed culling agent not being called on override
- next_location
  - fixed tracking empty agents
  - fixed duplicate messagse
  - added 'change in observed location' message 

0.5.2
-----
- added authorization for operators page
- added authorization for whitelist

0.5.1
-----
- fixed culling agent not removing stale elmenets

0.5.0
-----
- added asset_radio agent
- updated asset radio to be a string (from int)
- operators
  - added nicknames
  - ability to restore deleted operator
- mass dispatch relationship added
- removed static data agent
- consolidated locations (updates periodically)
- device unassigned from asset when revoked
- fixed crash when sending dispatch to device with no asset
- dis_device_assignment
  - assigned_operator_id removed
  - active_operator_id renamed to operator_id
- location geofences broadcasted as strings for smaller transport footprint

0.4.0
-----

- protection against next location id being compared to nil in ecto query
- added mass dispatcher messages relationship

0.3.0
-----

- tables for asset assignment and activity
- added naive helper functions to convert between epoch and naive
- device information split out of dispatch into device_assignment
- device agent split into smaller agents
- changing asset -> device relationship clears the old dispatch for the asset
- fixes to authorization flow
- device uuid and id added to socket assignments
- various tables updated to naive from epoch
- removed circular coupling between dispatch and next location
- fixed changing device's asset assignment not sending the correct dispatch
- added engine hours table

0.2.2
-----

- created culling agent to prevent overload of data
- added appsignal

0.2.1
-----

- fixed device token validation when not a string (binary)
- re-write of next location monitoring
- refactored all broadcast statements into a single module
- next locations are observed at application start
- broadcast unread message information (for user feedback)

0.2.0
-----

- added dis_delay and dis_delay_source
- add/delete delays
- dis_device table updated for nbt. device_id renamed to name to avoid confusion
- device authorization
- ability to accept/reject devices
- mass refactor and formatting
- operator add/delete/upsert
- removed argon
- added encryption for operator names
- ability to force logout a device
- added config whitelist
- activity log sent in full (not incremenets as it updates)

0.1.0
-----

- project init
- created hps_dispatch_data (ecto). Tables:
  - dis_acknoweldge
  - dis_operator_message_type
  - dis_operator_message
  - dis_operator_delay
  - dis_operator
  - dis_message
  - dis_dispatcher_delay
  - dis_dispatch
  - dis_device
  - dis_delay_type
  - dim_asset_radio
- dispatcher channel
- operator channel
- basic 
  - messaging
  - delays