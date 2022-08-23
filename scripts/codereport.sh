#!/bin/bash
#
# dependencies cloc:
# https://github.com/AlDanial/cloc/blob/master/README.md
# CYGWIN/LINUX/(etc) ENV 
# 
# make code size and code lines report.
#


#PROJ_DIR="."
#DEP1_DIR="../../../../../Common/DEP1"
#DEP2_DIR="../../../../../Common/DEP2"
#DEP3_DIR="../../../../../Common/DEP3"
#FOLDERS="$PROJ_DIR $DEP1_DIR $DEP2_DIR $DEP3_DIR"

FOLDERS=$@

LIST_FILE=$(pwd)"/file.list"

#Programming languages to include in the report
FILES_EXT="*.h *.c *.cpp *.S"


#$(find . -name "*.ui")
echo "" > $LIST_FILE

list_files()
{
    pushd "$1" > /dev/null
    for ext in $FILES_EXT
    do
      find $(pwd) -name "$ext" >> $LIST_FILE
    done
    popd > /dev/null
}

#find all files
for path in $FOLDERS
do
 list_files "$path"
done

cloc --list-file="$LIST_FILE"
totsize=0
file_size=0

while read p; do
  if [ -f "$p" ]; then
    file_size=$(stat -c%s $p)
    totsize=$((file_size + totsize))
    echo -en "Counting code file size: $totsize \r"
  fi
done <$LIST_FILE

echo "Total code file size $totsize"