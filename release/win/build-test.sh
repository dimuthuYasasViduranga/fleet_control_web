# get the version numbers
version=$(cat package.json | jq -r .version)

major=`echo $version | cut -d. -f1`
minor=`echo $version | cut -d. -f2`
revision=`echo $version | cut -d. -f3`

versionCode=$(($major * 10000 + $minor * 100 + $revision))

# replace version numbers
appName="Fleet Control"
echo -e '\033[44m' Setting Android Manifest '\033[0m'
echo "* versionName -- $version"
echo "* versionCode -- $versionCode"
echo "* applicationName -- $appName"
echo ""

# files to update 
manifestFile="app/App_Resources/Android/src/main/AndroidManifest.xml"
stringsFile="app/App_Resources/Android/src/main/res/values/strings.xml"

# update version number
sed -i "s/versionCode=\".*\"/versionCode=\"$versionCode\" android:versionName=\"$version\"/" $manifestFile

# update app name
sed -i "s/\"app_name\">.*</\"app_name\">$appName</" $stringsFile
sed -i "s/\"title_activity_kimera\">.*</\"title_activity_kimera\">$appName</" $stringsFile

echo -e '\033[44m' Building Apk '\033[0m'
apk=fleet-control-test\($version\).apk
tns build android --bundle --env.url=https://hx-fleet-control-test.azurewebsites.net --env.version=$version \
  --env.production --copy-to release/apks/$apk
echo -e '\033[32m' apk located at /release/apks/$apk '\033[0m'



