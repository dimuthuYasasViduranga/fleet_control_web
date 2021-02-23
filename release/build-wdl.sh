# ============== get application version from package.json ===============
version=$(cat package.json | jq -r .version)

major=`echo $version | cut -d. -f1`
minor=`echo $version | cut -d. -f2`
revision=`echo $version | cut -d. -f3`

versionCode=$(($major * 10000 + $minor * 100 + $revision))

# files to update 
manifestFile="app/App_Resources/Android/src/main/AndroidManifest.xml"
stringsFile="app/App_Resources/Android/src/main/res/values/strings.xml"
settingsFile="app/App_Resources/Android/settings.json"
gradleFile="app/App_Resources/Android/app.gradle"

# create a packup of the json files
cp package.json package_backup.json
cp $settingsFile settings_backup.json
cp $gradleFile app_backup.gradle

# replace version numbers
appName="Fleet Control WDL"
echo -e '\033[44m' Setting Android Manifest '\033[0m'
echo "* versionName -- $version"
echo "* versionCode -- $versionCode"
echo "* applicationName -- $appName"
echo ""

# # ====================== Update application id ====================
# package.json | settings.json | app.gradle
id="com.haultrax.fleetControlWdl"
jq -c ".nativescript.id = \"$id\"" package.json > tmp.$$.json && mv tmp.$$.json package.json
cat $settingsFile | jq -c ".appId = \"$id\"" > tmp.$$.json && mv tmp.$$.json "$settingsFile"          
sed -i "s/applicationId = \".*\"/applicationId = \"$id\"/" $gradleFile

# update version number
sed -i "s/versionCode=\".*\"/versionCode=\"$versionCode\" android:versionName=\"$version\"/" $manifestFile

# update app name
sed -i "s/\"app_name\">.*</\"app_name\">$appName</" $stringsFile
sed -i "s/\"title_activity_kimera\">.*</\"title_activity_kimera\">$appName</" $stringsFile

# ================= Build APK ==================
echo -e '\033[44m' Building Apk '\033[0m'
apk=fleet-control-wdl\($version\).apk
tns build android --bundle --env.url=https://hx-fleet-control-wdl.azurewebsites.net --env.version=$version \
  --env.production --copy-to release/apks/$apk

# ================ Reset any files changed ==================
echo -e '\033[44m' Resetting \'package.json\' and \'settings.json\' '\033[0m'
mv package_backup.json package.json
mv settings_backup.json $settingsFile
mv app_backup.gradle $gradleFile


# =============== reset version strings =============
echo -e '\033[44m' Resetting Strings.xml  '\033[0m'
sed -i "s/\"app_name\">.*</\"app_name\">Fleet Control</" $stringsFile
sed -i "s/\"title_activity_kimera\">.*</\"title_activity_kimera\">Fleet Control</" $stringsFile

echo -e '\033[32m' apk located at /release/apks/$apk '\033[0m'

# ============== Install on device ==================
echo -e '\033[44m' Installing on connected device '\033[0m'
adb install release/apks/$apk
