# get the version numbers
version=$(cat package.json | jq -r .version)

major=`echo $version | cut -d. -f1`
minor=`echo $version | cut -d. -f2`
revision=`echo $version | cut -d. -f3`

versionCode=$(($major * 10000 + $minor * 100 + $revision))

# replace 
file=app/App_Resources/Android/src/main/AndroidManifest.xml
echo -e '\033[44m' Setting Android Manifest '\033[0m'
echo "* versionName -- $version"
echo "* versionCode -- $versionCode"
echo ""
sed -i "s/versionCode=\".*\"/versionCode=\"$versionCode\" android:versionName=\"$version\"/" $file

echo -e '\033[44m' Building Apk '\033[0m'
apk=fleet-control-test\($version\).apk
sudo tns build android --bundle --env.url=https://hx-fleet-control-test.azurewebsites.net --env.version=$version \
  --copy-to release/apks/$apk
echo -e '\033[32m' apk located at /release/apks/$apk '\033[0m'
echo ""

echo -e '\033[44m' Installing on connected device '\033[0m'
adb install $apk
