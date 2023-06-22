#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo ""
echo "$0 usage"
echo ""
echo "This script builds a smokeview bundle using the"
echo "smv repo revision from the latest smokebot pass."
echo ""
echo "Options:"
echo "-h - display this message"

#if [ "$MAILTO" != "" ]; then
#  echo "-m mailto - email address [default: $MAILTO]"
#else
#  echo "-m mailto - email address"
#fi
exit 0
}

#*** determine platform script is running on

platform=linux
platform2=lnx
comp=intel
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  platform2="osx"
  comp=gnu
fi

#---------------------------------------------
#               get options
#---------------------------------------------

while getopts 'h' OPTION
do
case $OPTION  in
  h)
   usage
   ;;
esac
done
shift $(($OPTIND-1))

curdir=`pwd`
cd ../../../..
reporoot=`pwd`
basereporoot=`basename $reporoot`
cd $curdir/output

outdir=`pwd`
cd $curdir

echo "*** get smv repo revision"

./get_hash_revisions.sh >& $outdir/stage1_hash
smv_hash=`head -1 $outdir/SMV_HASH`

./clone_repos.sh $smv_hash >& $outdir/stage2_clone
cd $reporoot/smv
smv_revision=`git describe --abbrev=7 --dirty --long`
echo "***     smv_hash: $smv_hash"
echo "*** smv_revision: $smv_revision"

echo "*** building libraries"

# build libraries
cd $reporoot/smv/Build/LIBS/${comp}_${platform}_64
./make_LIBS.sh >& $outdir/stage3_LIBS

echo "*** building applications"

progs="background flush hashfile smokediff smokezip wind2fds"

for prog in $progs; do 
  cd $reporoot/smv/Build/$prog/${comp}_${platform}_64
  echo "*** building $prog"
  ./make_${prog}.sh >& $outdir/stage4_$prog
done

echo "*** building smokeview"
cd $reporoot/smv/Build/smokeview/${comp}_${platform}_64
./make_smokeview.sh -t >& $outdir/stage5_smokeview

echo "*** bundling smokeview"

$reporoot/bot/Bundlebot/smv/scripts/make_bundle.sh test $smv_revision $basereporoot >& $outdir/stage6_bundle


echo "*** uploading smokeview bundle"

FILELIST=`gh release view $GH_SMOKEVIEW_TAG  -R github.com/$GH_OWNER/$GH_REPO | grep SMV | grep -v FDS | grep $platform2 | awk '{print $2}'`
for file in $FILELIST ; do
  gh release delete-asset $GH_SMOKEVIEW_TAG $file -R github.com/$GH_OWNER/$GH_REPO -y
done

uploaddir=.bundle/uploads
$reporoot/bot/Bundlebot/scripts/upload_smvbundle.sh $uploaddir ${smv_revision}_${platform2}.sh     $basereporoot/bot/Bundlebot/scripts $GH_SMOKEVIEW_TAG $GH_OWNER $GH_REPO --clobber
$reporoot/bot/Bundlebot/scripts/upload_smvbundle.sh $uploaddir ${smv_revision}_${platform2}.sha1   $basereporoot/bot/Bundlebot/scripts $GH_SMOKEVIEW_TAG $GH_OWNER $GH_REPO --clobber

echo "*** upload complete"
