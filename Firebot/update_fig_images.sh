#!/bin/bash
REPO=$1

CURDIR=`pwd`
if [ "$REPO" == "" ]; then
  cd ../..
  REPO=`pwd`
  cd $CURDIR
fi

if [ ! -d  $REPO/fds ]; then
  echo "***error: $REPO/fds does not exist"
  exit
fi

if [ ! -d  $REPO/smv ]; then
  echo "***error: $REPO/smv does not exist"
  exit
fi

if [ ! -d  $REPO/fig ]; then
  echo "***error: $REPO/fig does not exist"
  exit
fi

echo getting fds repo revision
cd $REPO/fds
FDS_REPO=`pwd`
FDS_REVISION=`git describe --dirty --long`

echo getting smv repo revision
cd $REPO/smv
SMV_REPO=`pwd`
SMV_REVISION=`git describe --dirty --long`

FIG_DIR=$REPO/fig/compare/firebot/images

echo copying FDS user guide figures
cp $FDS_REPO/Manuals/FDS_User_Guide/SCRIPT_FIGURES/*.png $FIG_DIR/fig/user/.
echo $FDS_REVISION > $FIG_DIR/user/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/user/SMV_REVISION

echo copying FDS verificaiton guide figures
cp $FDS_REPO/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/*.png $FIG_DIR/verification/.
echo $FDS_REVISION > $FIG_DIR/verification/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/verification/SMV_REVISION



