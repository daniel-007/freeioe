# !/usr/bin/env sh

rm __release/* -rf
# Make the release folder
mkdir -p __release

# Clean up the cramfs folder
#sudo rm -rf __install
rm -rf __install
mkdir __install

# Copy files
cp -r lualib __install/lualib
cp -r service __install/service
cp -r snax __install/snax
cp config __install/
cp main.lua __install/
cp preload.lua __install/
cp README.md __install/

# copy lwf files

### Get the version by count the commits
VERSION=`git log --oneline | wc -l | tr -d ' '`

### Generate the revision by last commit
set -- $(git log -1 --format="%ct %h")
R_SECS="$(($1 % 86400))"
R_YDAY="$(date --utc --date="@$1" "+%y.%j")"
REVISION="$(printf 'git-%s.%05d-%s' "$R_YDAY" "$R_SECS" "$2")"

echo 'Version:'$VERSION
echo 'Revision:'$REVISION
echo $VERSION > __install/version
echo $REVISION >> __install/version

# For pre-installed applications
mkdir __install/apps
./scripts/pre_inst.sh iot iot 1.2.0

# Compile lua files
# ./scripts/compile_lua.sh 

#################################
# Count the file sizes
################################
du __install -sh

# Release example (modbus)
# Release iot
./scripts/release_app.sh iot

###################
##
##################
cd __install
find . -name '*~' -ok rm -f {} \;
tar czvf ../__release/skynet_iot-1.0.tar.gz * > /dev/null
cd - > /dev/null

# Clean up the rootfs files
#sudo rm -rf __install
rm -rf __install

# Release Skynet
./scripts/release_skynet.sh ~/mycode/skynet

# Done
echo 'May GOD with YOU always!'
