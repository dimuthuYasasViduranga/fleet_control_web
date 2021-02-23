# Login
- [ ] error if no id entered
- [ ] Connection modal appears when no wifi (attempts increment)
- [ ] Successful connection while being offline
- [ ] 401 for invalid id
- [ ] 403 for device unauthorized
- [ ] changeing device assignment loads correct asset type

### Debug
- [ ] Hold down on "FleetControl" opens window
- [ ] Force crash restarts according to "mode"
- [ ] Location updates
- [ ] Battery shows information
- [ ] Restart works
- [ ] Clear cache works

### Info modal
- [ ] Client version and updated at time
- [ ] Clear cache triggers
- [ ] Authorize device error when window not open
- [ ] Authorize device accept closed window


### Battery modal
- [ ] Charging 'lightning' shown when charging
- Information
  - [ ] Level
  - [ ] Health
  - [ ] Status
  - [ ] Temperature
  - [ ] Voltage
  - [ ] Last Updated
- [ ] Last updated changes when plugged in/out

# No device
- [ ] show the no asset assigned screen
- [ ] can log out via button
- [ ] changing to another asset type loads

# All pages
- [ ] Grey outline on wifi down
- [ ] Orange outline on long wifi down
- [ ] successful reconnect once wifi is enabled
- [ ] Send message
- [ ] Set exception
- [ ] Set task
- Set engine hours
  - [ ] Check decimal entry
  - [ ] Check for prompt on entering less than hours
  - [ ] Check for really large prompt
  - [ ] Entering on prompt doesnt take two key presses
  - [ ] Error if no number
  - [ ] Error if negative number
- [ ] Notification on dispatcher message received
- [ ] Notification is dispatcher message on screen for too long
- [ ] Dispatcher messages page shows latest messages
- [ ] Dispatcher message acknowledge
- [ ] Dispatcher question cannot close without answer
- [ ] Operator and asset name shown in header bar
- [ ] Unread count on messages page
- [ ] All secondary pages (ones in more) revert to dispatch if dispatch changes
- [ ] Modals close if tablet is force slept


### Offline
Store and forward the following
- [ ] task
- exceptions
  - [ ] ending exception while no connection should remove red bar
  - [ ] end active one
  - [ ] start new one
  - [ ] start and end new one
- [ ] logout
- [ ] messages
- [ ] dispatcher message acknowledgement
- [ ] Engine hours (offline number should be shown on the page)


# Haul Truck Dispatch
- [ ] Yellow text for dispatch on load
- [ ] Yellow text of dispatch that has changed
- [ ] Notification on dispatch change
- [ ] Notification is not acknowledged after a period
- [ ] Acknowledge reflected on ui
- [ ] Battery icon shown and opens modal
- [ ] Engine hours icon opens engine hours page
- page reverting after inactivity
  - [ ] exceptions
  - [ ] messages
  - [ ] engine hours
- [ ] Ability to end active delay
- [ ] Logout does not ask for exception (when in one)
- [ ] Logout asks for exception (when not in one)
- [ ] Logout exception auto opens "standby" group
- [ ] Unread operator messages icon
- [ ] Acknowledge bar dims when no acknowledgement required


### Offline
- [ ] Store and forward acknowledge


# Haul truck map
- [ ] Recenter
- [ ] Reset zoom
- [ ] Reset bearing
- [ ] Free pan does not snap on update
- [ ] Free pan does not revert tilt
- [ ] Tilt screen
- [ ] set satellite
- [ ] toggle geofences (shoud see static ones)
- [ ] position updates in a timely manner
- [ ] Map does not frequently lag when trying to move it





