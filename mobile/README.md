# Operator Dispatch UI

> Dispatch UI for operator Android tablets


## Setup the Android Emulator

### Linux


``` bash
cd $ANDROID_HOME
cd emulator
./emulator -no-cache -avd test1
```

## Usage

``` bash
# Install dependencies
npm install

# Build for production
./rel/test.sh

# Build, watch for changes and debug the application
tns debug android --bundle

# Build, watch for changes and run the application
tns run android --bundle
```

### Windows

#### enable windows hypervisor platform
```
> Search "turn windows features on or off"
> Enable "Windows Hypervisor Platform"
```

#### kill docker
In order for this to run well, I recommend killing the docker service while testing

#### Install android studio
[android studio](https://developer.android.com/studio)

create a project (doesnt matter what one)
> Tools -> SDK manager
* install android 7.1.1
* install Intel x86 Emulator Accelerator (can be installed any other way)

> Tools -> AVD manager
* create virtual device
* new hardware profile
  * configure based on a known device
* next
  * select based on api level 25
* next
  * show advanced settings
    * graphics -> software
    * vm heap 512 MB or greater


#### Install native script cli
Follow the installation here [nativescript quickstart](https://docs.nativescript.org/start/ns-setup-win)
<br>
If any of the commands fail, run it in powercell/cmd

#### Install nativescript sidekick
[Install](https://www.nativescript.org/nativescript-sidekick)
This is an app that make it easier to build and push to multiple devices at once

#### launch device
In the AVD manager, click start. This can also be done through the CLI but this way will be easier on windows


#### Timeline view for profiling
Install the timeline view
```npm install -g timeline-view ```

Enable timeline view in `app/package.json" at the root level
```"profiling": "timeline"```

Run with profile
```tns debug android | timeline-view```

When you are done profiling, end connection with ctrl+c and a `times.html` file will be generated in the root directory