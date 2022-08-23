
#!/usr/bin/env python

"""resvar.py: Resolve variable address and type from elf/out/bin file"""

__author__      = "Andreas d"
__version__ = "0.1.0"

from subprocess import Popen, PIPE
import os
from os.path import exists
import filecmp
from shutil import copyfile

gdb_exe = '../bin/gdb.exe'
elf_exe = '../bin/readelf.exe'
lbin = './tmp.out'
lbin_list = './tmp_out.list'

gdb_exists = exists(gdb_exe)
elf_exists = exists(elf_exe)

import logging
log = logging.getLogger('ResolveVars')

LOWER_ADDR=0x20000000
UPPER_ADDR=0x20007000

RES_NAME=0
RES_TYPE=1
RES_ADDRESS=2

def getbinfile(file):
    ret = False
    if(exists(lbin) is True):
        if(filecmp.cmp(file,lbin, shallow=True) is False):
            copyfile(file,lbin)
            ret = True
    else:
        copyfile(file, lbin)
        ret = True


def list_all(lower, upper, file):
    reuse = False
    ret = ""
    binfiletime = os.path.getmtime(file)
    if(getbinfile(file) is False):
        if(exists(lbin_list) is True):
            reuse = True

    if(exists(lbin) is True):
        if(filecmp.cmp(file,lbin, shallow=True) is False):
            copyfile(file,lbin)
        else:
            if(exists(lbin_list) is True):
                binlisttime = os.path.getmtime(lbin_list)
                if(binlisttime>binfiletime):
                    reuse = True
    else:
        copyfile(file, lbin)
    
    if(reuse is False):
        cmd = []
        cmd.append(elf_exe)
        cmd.append("-s")
        cmd.append("--w")
        cmd.append(lbin)
        pipe = Popen(cmd, stdout=PIPE, stdin=PIPE)
        result = pipe.stdout.read()
        #print (str(result))
        for line in result.splitlines():
            cols = line.split()
            if(len(cols) > 3):
                if(cols[4].decode() == 'GLOBAL'):
                    try:
                        address_str = "0x" + cols[1].decode()
                        size = int(cols[2].decode())
                        address = int(address_str, 16)
                        if( address >= lower and address <= upper and size > 0):
                            ret += cols[7].decode() + ", " + address_str + "\n"
                    except:
                        pass
        f = open(lbin_list, "w")
        f.write(ret)
                    #print(cols)
        #for line in result:
         #   print(str(line))
    else:
        f = open(lbin_list, "r")
        ret = f.read()
    return ret

def getList(lower, upper, file):
    ret = []
    ll = list_all(lower,upper,file).split('\n')
    for var in ll:
        ret.append(var.split(','))
    return ret


def getName(str):
    try:
        if (str.find("*") < 0):
            return str.split()[-1].replace(";","")
    except:
        pass
    return None

def getStruct(lstr, var):
    ret = []
    start = False
    for item in lstr.splitlines():
        itemstr = item.decode()
        if "{" in itemstr:
            start=True
        elif "}" in itemstr:
            if '[' in itemstr and ']' in itemstr:
                try:
                    arrlen = int(itemstr[itemstr.find('[')+1:itemstr.find(']')])
                    ret = []
                    for i in range(arrlen):
                        varname = var + '[' + str(i) + ']'
                        ret.append(varname)
                except:
                    log.warning("Failed to get array structure")
                return ret
            else:
                return ret
        elif start is True:
            varname = getName(item.decode())
            if varname is not None:
                ret.append( var + "." + varname )
        
    return ret

def resolve_struct(struct, var):
    # cmd = []
    # cmd.append(gdb_exe)
    # cmd.append("-q")
    # pipe = Popen(cmd, stdout=PIPE, stdin=PIPE)
    # stdinput = "file "+lbin+"\n"+"ptype "+var
    # pipe.stdin.write(stdinput.encode('utf-8'))
    # pipe.stdin.close()
    # result = pipe.stdout.read()
    # var_list=$(gdb -q <<< "file ./$elf_file"$'\n'"ptype $var_name" 2> /dev/null) 
    return getStruct(struct, var)

def getLine(str, key):
    for item in str.splitlines():
      if key in item.decode():
         return item.decode().replace("(gdb) ",'')

def getType(str):
    try:
        line = getLine(str,"type")
        if line is None:
            return None
    
        return line.split(" = ")[1]
    except:
        pass
    return None

def getAddress(str):
    try:
        ret = None
        line = getLine(str,"0x").replace("\"","")
        if(line is not None):
            arr = line.split()
            idx=-2
            size = len(arr)
            while (size + idx) > 0 :
                try:
                    val = int(arr[idx],0)
                    ret = arr[idx]
                    break
                except:
                    idx = idx-1
    except:
        pass
    return ret

#expected hex value return decimals
def getAddressValue(str):
    ret = None
    try:
        line = getLine(str,"0x")
        if(line is None):
            return ret

        
        line = line.split(":")
        if len(line) < 2:
            return ret

        if line[1].find("Cannot access") >= 0:
            log.error(line[1])
            return ret

        ret = int(line[1],0)
    except:
        pass
    return ret

#expected hex value return decimals
def getVarAddress(var, file):
    ret = None
    try:
        getbinfile(file)
        cmd = []
        cmd.append(gdb_exe)
        cmd.append("-q")
        stdinput = "file ./"+lbin+"\n"+"p&"+var
        pipe = Popen(cmd, stdout=PIPE, stdin=PIPE)
        pipe.stdin.write(stdinput.encode('utf-8'))
        pipe.stdin.close()
        result = pipe.stdout.read()

        ret = getAddress(result)
    except:
        pass
    return ret
    
def getCodeType(str):
    try:
        line = getLine(str,"0x")
        if(line is not None):
            if(line.find("(") != -1):            
                return line[line.find("(")+1 : line.find(")")]
            else:
                line.split()[2]
    except:
        pass
    return None

#Returns true if leaf
def resolve_vars(var, file):
    getbinfile(file)
    cmd = []
    cmd.append(gdb_exe)
    cmd.append("-q")
    pipe = Popen(cmd, stdout=PIPE, stdin=PIPE)
    stdinput = "file "+lbin+"\n"+"ptype "+var
    pipe.stdin.write(stdinput.encode('utf-8'))
    pipe.stdin.close()
    result = pipe.stdout.read()
    
    try:
        var_type = getType(result)
    except:
        return False, None
    if var_type is None:
        return False, None
        
    if(var_type.find("struct")>=0):
        return False, resolve_struct(result, var)
    else:
        stdinput = "file ./"+lbin+"\n"+"p&"+var
        pipe = Popen(cmd, stdout=PIPE, stdin=PIPE)
        pipe.stdin.write(stdinput.encode('utf-8'))
        pipe.stdin.close()
        result = pipe.stdout.read()
        var_address = getAddress(result)
        var_type = getCodeType(result)
        #var_address=${var_address//$'\n'/}
        #var_address=$(echo $var_address | cut -d"=" -f2 | cut -d"<" -f1 | cut -d")" -f2 | xargs)
        return True, [var, var_type, var_address]

#Returns true if leaf
def resolve_addr_val(cmdadr, file):
    getbinfile(file)
    cmd = []
    cmd.append(gdb_exe)
    cmd.append("-q")
    pipe = Popen(cmd, stdout=PIPE, stdin=PIPE)
    stdinput = "file "+lbin+"\n"+cmdadr
    pipe.stdin.write(stdinput.encode('utf-8'))
    pipe.stdin.close()
    result = pipe.stdout.read()
    
    return getAddressValue(result)

#Returns value
def resolve_var_val(cmd, file):
    ret =None
    arr = cmd.split()
    
    if len(arr) == 2:
        valcmd=arr[0]
        try:
            int(arr[1],0)
            adrcmd = arr[1]
        except:
            adrcmd = getVarAddress(arr[1], file)
        cmd = valcmd + " " + adrcmd
    else:
        return None

    if valcmd is not None and adrcmd is not None:
        ret = resolve_addr_val(cmd, file)

    return ret
    


    getbinfile(file)
    cmd = []
    cmd.append(gdb_exe)
    cmd.append("-q")
    pipe = Popen(cmd, stdout=PIPE, stdin=PIPE)
    stdinput = "file "+lbin+"\n"+cmdadr
    pipe.stdin.write(stdinput.encode('utf-8'))
    pipe.stdin.close()
    result = pipe.stdout.read()
    
    return getAddressValue(result)

def resolve_vars_valid(var, file):
    valid = True
    leaf , varlist = resolve_vars(var, file)
    if varlist is None:
        valid = False
    else:
        if leaf is True:
            if varlist[1].count("*") > 1:
                valid = False
            varlist[1] = varlist[1].replace("*","")
            varlist[1] = varlist[1].replace("(","")
    return leaf, valid, varlist




if __name__ == '__main__':
    import argparse
    from argparse import RawTextHelpFormatter
    import sys
    example_text = '''example:
  python resvar.py -l -f nucleo.out
  python resvar.py -r FOCVars[M2].Iqd.q -f nucleo.out
  python resvar.py -r ENCODER_M1._Super.wMecAngle -f nucleo.out'''
    
    parser = argparse.ArgumentParser(description='Resolve variable info form elf/out/bin', epilog=example_text, formatter_class=RawTextHelpFormatter)
    parser.add_argument( '-d','--d', type=int, help='log level (Levels: CRITICAL 50, ERROR 40, WARNING 30, INFO 20, DEBUG 10 and NOTSET 0)', default=10)
    parser.add_argument( '-l','--l', action='store_true', help='list all variables in rw memory range', default=False)
    parser.add_argument( '-r', '--r', type=str, help='name of variable to resolve', default='')
    parser.add_argument( '-f', '--f', type=str, help="binary file" ,required=True)

    try:
        args=parser.parse_args()
        log.setLevel(args.d)
        # create formatter and add it to the handlers
        formatter = logging.Formatter('%(asctime)-15s %(levelname)-8s %(lineno)-3s:%(module)-15s  %(message)s')
        # reate console handler for logger
        consolelog = logging.StreamHandler()
        consolelog.setLevel(level=args.d)
        consolelog.setFormatter(formatter)

        LogHandler.addHandler(consolelog)
    except:
        parser.print_help()
        sys.exit(1)

    if(exists(args.f) is False):
        log.error("Binary File doesn't exist %s", args.f)
        sys.exit(0)
        
    

    if(args.l == True):
        if(elf_exists is False):
            log.error("Missing dependencie readelf")
            sys.exit(0)
        str = list_all(LOWER_ADDR, UPPER_ADDR, args.f)
        print(str)
    else:
        if(gdb_exists is False):
            log.error("Missing dependencie gdb")
            sys.exit(1)

        if(args.r == ''):
            log.error("missing arguments")
            parser.print_help()
            sys.exit(1)
        
        leaf, varlist = resolve_vars(args.r, args.f)
        if leaf is True:
            print(varlist)
        else:
            for item in varlist:
                print(item)
        
