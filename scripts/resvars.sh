#!/bin/sh


show_help()
{
  echo
  echo "elf/out/bin file resolve variable address and type"
  echo "usage: resvars [options] -f file"
  echo -l - list all variables in rw memory range
  echo -r [varname] - resolve variable
  exit
}



resolve_struct()
{
elf_file=$1
local var_name=$2
#echo "varName $var_name"
#if [[ "$var_name" == "" ]] || [[ "$var_name" =~ [^A-Za-z\ |\']  ]]; then
#  return
#fi
var_list=$(gdb -q <<< "file ./$elf_file"$'\n'"ptype $var_name" 2> /dev/null) 

#echo $var_list
local var_struct="$(echo $var_list | cut -d"{" -f2 | cut -d"}" -f1)"
#if [[ "$var_name" = *"."*  ]] ; then
  #echo "exit" $var_list   
  #exit
#fi
#echo $var_struct
if [[ "$var_struct" = *";"*  ]] ; then
  #echo "semicolon"
  local var_struct="${var_struct::-1}"
  IFS=";"
else
  #echo "new line "
  IFS=$'\n'
fi  
for var in $var_struct
do
    var=$(echo $var | xargs)
    # echo $var
    if [[ "$var" != ""  ]] && [[ "$var" != *"*"* ]] && [[ "$var" != *"["* ]] && [[ "$var" != *"gdb"* ]]; then
      local vars=${var_name}.${var##*" "} 
      #echo $vars
      var_list=$(gdb -q <<< "file ./$elf_file"$'\n'"ptype $vars")
      var_type=$(echo "$var_list" | grep "type" | cut -d"=" -f2) 2> /dev/null
      #echo $var_type 
    
      if [[ "$var_type" == *"struct"* ]] ; then
        resolve_struct $elf_file $vars
      else
        var_address="$(gdb -q <<< "file ./$elf_file"$'\n'"p&$vars")"
        var_address=${var_address//$'\n'/}
        var_address=$(echo $var_address | cut -d"=" -f2 | cut -d"<" -f1 | cut -d")" -f2 | xargs)
        echo "${vars}, ${var_type}, ${var_address}"
      fi
    fi
done
}

list_vars()
{
  elf_file=$1
  LOWER_ADDR=$(printf %d $2)
  UPPER_ADDR=$(printf %d $3)
  readelf -s --wide $elf_file 2>/dev/null | grep OBJECT > ./memory_variables  
  size=$(wc -c ./memory_variables | cut -d" " -f1)
  if [ $size -lt 1 ]; then
    echo "no objects in elf file"
    exit
  fi
  echo "varname, address"
  while read pLine; do
    var_adr_hex=0x$(echo $pLine | cut -d" " -f2 )
    var_adr_dec=$(printf %d $var_adr_hex)

    if [ $var_adr_dec -gt $LOWER_ADDR ] && [ $var_adr_dec -lt $UPPER_ADDR ]; then
      main_var_name=${pLine##*" "}
      [[ "$main_var_name" != *":"* ]] && echo "$main_var_name, $var_adr_hex"
    fi
  done < ./memory_variables
}

resolve_vars()
{
  elf_file=$1
  res_vars=$2
  readelf -s --wide $elf_file | grep OBJECT | grep $res_vars > ./memory_variables
  size=$(wc -c ./memory_variables | cut -d" " -f1)
  if [ $size -lt 1 ]; then
    echo "no objects in elf file"
    exit
  fi
  echo "varname, type, address"
  while read pLine; do
    main_var_name=${pLine##*" "}
    #echo "$main_var_name, $var_adr_hex"
    var_address="$(gdb -q <<< "file ./$elf_file"$'\n'"p&$main_var_name")"
    if [ "$var_address" == "" ] ; then
      continue
    fi
    if [ $(echo $var_address |  tr -d -c '"*'  | wc -c) -gt 1 ]; then
      echo "Varable is a ptr to another variable"
      continue
    fi

    var_list=$(gdb -q <<< "file ./$main_elf_file"$'\n'"ptype $main_var_name" 2> /dev/null) 
    main_var_type=$(echo "$var_list" | grep "type" | cut -d"=" -f2 2> /dev/null)

    if [[ "$main_var_type" != ""  ]] && [[ "$main_var_type" != *"*"* ]] && [[ "$main_var_type" != *"["* ]] && [[ "$main_var_type" != *")"* ]] && [[ "$main_var_type" != *"gdb"* ]]; then
    
      if [[ "$main_var_type" == *"struct"* ]] ; then
        resolve_struct $elf_file $main_var_name
      else
          var_adr_hex=0x$(echo $pLine | cut -d" " -f2 )
         echo "$main_var_name, $var_adr_hex"
      fi
    fi

  done < ./memory_variables
}

#resolve_struct "tva_dd0.out" "RealBusVoltageSensorFilter"
#exit
elf_path=$1

LOWER_ADDR=0x20000000
UPPER_ADDR=0x20007000
list=0
resolve=""


while getopts "h?lr:v:f:" opt; do
  case "$opt" in
    h|\?)
      show_help
      exit 0
      ;;
    l)  list=1
      ;;
    r)  resolve=$OPTARG
      ;;
    v)  variable=$OPTARG
      ;;
    f)  elf_path=$OPTARG
      ;;
  esac
done


if [ ! -e $elf_path ] || [ "$elf_path" == "" ]; then
  echo "missing filename (out\bin\elf) $elf_path"
  show_help
  exit
fi




main_elf_file=$(basename $elf_path)

cp $elf_path .

if [ $list -eq 1 ] ; then
  list_vars  $main_elf_file $LOWER_ADDR $UPPER_ADDR
  exit
fi


if [ "$resolve" != "" ] ; then
  resolve_vars $main_elf_file $resolve
  exit
fi

echo "missig option args"
exit

#readelf -s --wide $main_elf_file | grep OBJECT 1> ./memory_variables 2>/dev/null
#size=$(wc -c ./memory_variables)
#echo "name, type, address"
#echo "" > ./bad_var.txt
#while read pLine; do
#  #echo $pLine
#  main_var_name=${pLine##*" "}  
#  #$(echo $pLine | cut -d" " -f8)  2> /dev/null
#  if [[ "$main_var_name" == *"::"* ]] || [[ "$main_var_name" == "" ]]; then 
#    continue
#  fi
#  #echo "varName $var_name"
##  resolve_struct $main_elf_file $main_var_name
#
#
#  var_list=$(gdb -q <<< "file ./$main_elf_file"$'\n'"ptype $main_var_name" 2> /dev/null) 
#  main_var_type=$(echo "$var_list" | grep "type" | cut -d"=" -f2 2> /dev/null)
#  #echo $main_var_type
#  if [[ "$main_var_type" != ""  ]] && [[ "$main_var_type" != *"*"* ]] && [[ "$main_var_type" != *"["* ]] && [[ "$main_var_type" != *")"* ]] && [[ "$main_var_type" != *"gdb"* ]]; then
#    
#  
#    if [[ "$main_var_type" == *"struct"* ]] ; then
#      
#      resolve_struct $main_elf_file $main_var_name
#             
#    else
#      var_adr=$(echo $pLine | cut -d" " -f2) 2> /dev/null
#      var_size=$(echo $pLine | cut -d" " -f3) 2> /dev/null
#      echo "$main_var_name, $main_var_type, 0x$var_adr"
#      
#    fi
#  else
#    echo "BAD ------------- $main_var_name $main_var_type  --------------" >> ./bad_var.txt
#  fi
#
#done < ./memory_variables
#
#
#
##gdb -q <<< "file ./$main_elf_file"$'\n'"ptype ENCODER_M1"
#
#
##clean disk
##del ./memory_variables
#