#
# --------------------    EXPORT VARS -------------------
#
export VC_VAR_PATH='C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build'


#
# -------------------- Private functions -------------------
#

#
# Convert to date
#
posixFunc(){
 cmd=$*
 if [ "$(echo \"$cmd\" | grep \"\-h\")" != "" ] ; then
   echo "Convert seconds since 1970 to date"
   echo "posix [seconds]"
   echo "posix [seconds] %T"
   return 0
 fi
 arg1=$1
 arg2=$2
 if [ "$arg2" != "" ] ; then
  date -d @${arg1} +"$arg2"
 else
  date -d @${arg1} +"%d.%m.%y %H:%M:%S"
 fi
}

# Given envar return exports to source
#
# VcVarsAll.bat is a script that sets up environment variables for Visual
# Studio command-line builds:
#
#   https://msdn.microsoft.com/en-us/library/f2ccy3wt.aspx
#
query_vcvarsall() {

  (cd "$VC_VAR_PATH" && cmd /c "vcvarsall.bat $PROCESSOR_ARCHITECTURE >nul 2>&1 && C:\cygwin64\bin\bash -c 'export'")
}

# Set Python Home to current directory
pyhome_func()
{
  localpath=$(pwd)
  PYTHONPATH="$(cygpath -d $localpath)"
  export PYTHONPATH=$PYTHONPATH
}

# Kill Windows Proc
win_kill() {
  pName=$1
  ps -W | awk '$0~v,NF=1' v=$1 | xargs kill -f
}


#
# -------------------- alias -------------------
#
alias setpyhome=pyhome_func
alias wkill='win_kill $@'
alias getVsDev=query_vcvarsall
alias wpwd='cygpath -w "$PWD"'
alias ifconfig='ipconfig /all'
alias apt='cmd.exe /c apt-cyg'
alias lCom='cmd.exe /c mode.com'
alias posix=posixFunc

#
# -------------------- sources code -------------------
#

localpath=$(pwd)
if [ "$PYTHONPATH" == "" ] ; then
  PYTHONPATH="$(cygpath -d $localpath)"
else
  PYTHONPATH="$PYTHONPATH;$(cygpath -d $localpath)"
fi

if [ -e "./pypath.pth" ] ; then
        while IFS= read -r line
        do
          PYTHONPATH="$PYTHONPATH;$(cygpath -d "$localpath$line")"
        done < "./pypath.pth"
fi

export PYTHONPATH=$PYTHONPATH

#ssh agent
if [ "$(ps | grep "ssh-agent")" == "" ] ; then
        eval $(ssh-agent)
fi

#Get Win ENV to build w nmake
query_vcvarsall > vcvars.tmp
if [ -d ./vcvars.tmp ] ; then
  lPath=$(pwd)
  source ./vcvars.tmp >nul 2>&1
  #source ./vcvars.tmp changes path so cd back
  cd $lPath
  rm -f ./vcvars.tmp >nul 2>&1
fi


echo -n $PATH | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}'







