#!/bin/sh
# Must be executed in the root folder
# Must have 7z in PATH
# Input arg1 Filename
# Input arg2 Ico
# input arg3 Archive Name

FILENAME=$1
ICON=$2
ARCHIVE=$3

#check script dependencies
if [ ! $(command -v 7z) ]; then
    echo "Missing 7z"
    exit
fi

#check script dependencies
if [ ! $(command -v GoRC) ]; then
    echo "Missing GoRC"
    exit
fi

#check script dependencies
if [ ! $(command -v ResHacker) ]; then
    echo "Missing ResHacker"
    exit
fi

#check script dependencies
if [ ! -e ./bin/7zsd.sfx ]; then
    echo "Missing 7zsd.sfx"
    exit
fi

localpath=$(pwd)
PYTHONPATH="$(cygpath -d $localpath)"
export PYTHONPATH=$PYTHONPATH



# build python exe
pyinstaller.exe -F --onefile --icon="$ICON.ico" $FILENAME.py

if [ ! -e ./dist/$FILENAME.exe ] ; then
    echo "Missing $FILENAME.exe"
    exit 1
fi

#copy dependencies
cd dist
mkdir -p ./common/bin
cp -f -r ../common/bin/* ./common/bin/

mkdir -p ./common/Data_Base
cp -f -r ../common/Data_Base/* ./common/Data_Base/

cp -f   ../common/__init__.py ./common/

cp -f -r ../qss .

cp -f  -r ../UnitTest .

cp -f ../$ICON.ico .
cp -f ../Install_STM32Bootloader_DFU.bat .
cp -f ../UserGuide.pdf .

echo "Copy other dependencies (json config run script etc)"
read -p "Press any key to continue... " -n1 -s

7z a ../$ARCHIVE.7z ./* -m0=lzma -mx=9

echo "Configure sfx bin/config.txt"
read -p "Press any key to continue... " -s

if [ -e ../$ARCHIVE.exe ]; then
    rm -f ../$ARCHIVE.exe
fi

cat ../bin/7zsd.sfx ../bin/config.txt ../$ARCHIVE.7z > ../$ARCHIVE.exe
chmod 777 ../$ARCHIVE.exe

echo Configure sfx bin/versionInfo.rc
read -p "Press any key to continue... " -s

#Remove existing version info gen from sfx oleg
ResHacker -open ../$ARCHIVE.exe -save ../$ARCHIVE.exe -action delete -mask VERSIONINFO,, -log CONSOLE
#Remove existing icon
ResHacker -open ../$ARCHIVE.exe -save ../$ARCHIVE.exe -action delete -mask ICONGROUP,101, -log CONSOLE

GoRC /fo Resources.res ../bin/versionInfo.rc
ResHacker  -open ../$ARCHIVE.exe -save ../$ARCHIVE.exe -res ./Resources.res -action addoverwrite -mask VersionInfo,, -log con
ResHacker -open ../$ARCHIVE.exe -save ../$ARCHIVE.exe -action add -res ./$ICON.ico -mask ICONGROUP,1, -log CONSOLE

rm -f ./Resources.res
rm -f ../$ARCHIVE.7z
