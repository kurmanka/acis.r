#!/bin/bash

if test -z $1; then 
    echo give a destination directory name as in:
    echo $0 /some/dir
    exit 1
fi

cwd=`pwd`

cd $1
dest=`pwd`

cd $cwd

self=$0
selfdir=${self%/install.sh}

if test $selfdir = $0; then 
    selfdir=.
fi

if test -z $selfdir; then 
    echo some error: can\'t find out installation package own directory
    echo but probably it is just current directory: `pwd`
    exit 1
fi

cd $selfdir
src=`pwd`


if test -d $dest; then
   upgrade=1
   echo "this is an upgrade"
else 
   upgrade=
   echo "You don't even yet have that directory: $dest"
   mkdir $dest
fi

cd $dest
dest=`pwd`

echo "installing to $dest directory"


if test -z $dest; then 
    echo "Can't get absolute path to $1"
    exit 1
fi

cd $dest
test -d bin           || mkdir bin
test -d bin/templates || mkdir bin/templates
test -d lib           || mkdir lib
test -d userdata      || mkdir userdata
test -d sessions      || mkdir sessions
test -d unconfirmed   || mkdir unconfirmed
test -d deleted-userdata || mkdir deleted-userdata
test -d doc           || mkdir doc

# the same assumption as in sysconfig 
test -d RI       || mkdir RI   
test -d RI/data  || mkdir RI/data   
test -d RI/backup || mkdir RI/backup
test -d SID      || mkdir SID 


if [ -f $dest/VERSION ]; then 
    OLDVERSION=`cat $dest/VERSION`
fi

cd $src
cp -r home/presentation        $dest/
cp -r home/bin/templates       $dest/bin/
cp -r lib/*                    $dest/lib/
cp -r sql_helper/*pm           $dest/lib/
cp -r home/plugins             $dest/
cp -r doc/img doc/*.html doc/style.css      $dest/doc/
cp home/screens.xml            \
   home/configuration.xml      \
   home/contributions.conf.xml \
   main.conf.eg                $dest/

### copy VERSION
cp VERSION     $dest/VERSION.NEW


###  And now I need to take all home/bin/ scripts and adapt them to the
###  home directory (I mean $dest)

echo -n installing scripts into $dest/bin: 
for i in home/bin/*; 
do
    name=${i##*/}
    test ! -d $i || continue
    destname="$dest/bin/$name"
    echo -n " $name"
    cat $i | sed -e "s!^homedir=\$!homedir=$dest!" -e "s!\\\$homedir=\;!\\\$homedir='$dest'\;!" -e "s!^#\!perl!#\!$perlbin! " > $destname
    chmod +x $destname
done
echo ""


RI=RePEc-Index-*.tar.gz
RIINSTALL=
if [ -f $RI ]; then 
   tar xzvf $RI > /dev/null
   RI=${RI%.tar.gz}
   $RI/install.sh $dest
   RIINSTALL=1
fi

AMFPerl=AMF-perl-*.tar.gz
if [ -f $AMFPerl ]; then
   tar xzvf $AMFPerl > /dev/null
   AMFPerl=${AMFPerl%.tar.gz}
   echo unpacked AMF-perl into dir $AMFPerl
   cd $AMFPerl
   cp -r lib/* $dest/lib/
   mkdir -p $dest/doc/AMF-perl
   cp -r doc/* $dest/doc/AMF-perl 
   cd ..
fi


if test ! -f "$dest/main.conf" ; then 
   echo "Now you might want to create main.conf file in $dest"
   echo Then run bin/setup there.
   exit 1
fi


$dest/bin/setup

if [ ! -f RI/daemon.pid ]; then 
    echo "You may want to start update daemon now; use: bin/rid start"
fi

if [ "$RIINSTALL" -a -f RI/daemon.pid ]; then 
    echo "RePEc-Index was upgraded; its time to restart the update daemon."
    echo Run: bin/rid restart
fi

