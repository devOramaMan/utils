#!/bin/sh



show_help()
{
  echo
  echo "copy exe dependendencies (in cygwin env)"
  echo "usage: cygbundle [options] file.exe"
  echo "-l - list dependencies"
  echo "-o [folder] copy to folder (default ./tstStub)"
  exit
}

#PATH TO iar project
EXE=$1

if [ ! -s $EXE ] ; then
  echo "File doesn't exist $EXE"
  show_help
  exit 1
fi

which cygcheck 2>/dev/null 1>/dev/null
if [ $? -gt 0 ] ; then
  echo "Missing cygcheck. Only supported in cygwin"
  show_help
  exit 1
fi

list=0
output='./tstStub'

while getopts "h?lo:" opt; do
  case "$opt" in
    h|\?)
      show_help
      exit 0
      ;;
    l)  list=1
      ;;
    r)  output=$OPTARG
      ;;
  esac
done

if [ "$output" == "" ]; then
  echo "Missing output path"
  show_help
  exit 1
fi

if [ -e $output ]; then
  rm -rdf $output/*
  rm -rdf $output
fi

mkdir $output

file_list="$(cygcheck $EXE)"

pushd $output > /dev/null


while IFS= read -r file; do
    lfile=$(echo $file)
    echo "copy $lfile..."
    cp -rf  "$lfile" .
done <<< "$file_list"

popd  > /dev/null







