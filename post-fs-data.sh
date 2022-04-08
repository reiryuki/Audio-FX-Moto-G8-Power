(

mount /data
mount -o rw,remount /data
MODPATH=${0%/*}

# debug
magiskpolicy --live "dontaudit system_server system_file file write"
magiskpolicy --live "allow     system_server system_file file write"
exec 2>$MODPATH/debug-pfsd.log
set -x

# run
FILE=$MODPATH/sepolicy.sh
if [ -f $FILE ]; then
  sh $FILE
fi

# etc
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi
ETC=$MAGISKTMP/mirror/system/etc
VETC=$MAGISKTMP/mirror/system/vendor/etc
VOETC="/odm/etc $MAGISKTMP/mirror/system/vendor/odm/etc"
MODETC=$MODPATH/system/etc
MODVETC=$MODPATH/system/vendor/etc
MODVOETC=$MODPATH/system/vendor/odm/etc

# conflict
AML=/data/adb/modules/aml
ACDB=/data/adb/modules/acdb
if [ -d $AML ] && [ ! -f $AML/disable ]\
&& [ -d $ACDB ] && [ ! -f $ACDB/disable ]; then
  touch $ACDB/disable
fi
rm -f /data/adb/modules/*/system/app/MotoSignatureApp/.replace

# directory
SKU=`ls $VETC/audio | grep sku_`
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    mkdir -p $MODVETC/audio/$SKUS
  done
fi
PROP=`getprop ro.build.product`
if [ -d $VETC/audio/"$PROP" ]; then
  mkdir -p $MODVETC/audio/"$PROP"
fi

# cleaning
rm -f `find $MODPATH/system -type f -name *audio*effects*.conf\
-o -name *audio*effects*.xml -o -name *audio*policy*.conf\
-o -name *stage*policy*.conf -o -name *audio*policy*.xml`

# audio files
AE=`find $ETC -maxdepth 1 -type f -name *audio*effects*.conf -o -name *audio*effects*.xml`
VAE=`find $VETC -maxdepth 1 -type f -name *audio*effects*.conf -o -name *audio*effects*.xml`
AP=`find $ETC -maxdepth 1 -type f -name *audio*policy*.conf -o -name *stage*policy*.conf -o -name *audio*policy*.xml`
VAP=`find $VETC -maxdepth 1 -type f -name *audio*policy*.conf -o -name *stage*policy*.conf -o -name *audio*policy*.xml`
VOA=`find $VOETC -maxdepth 1 -type f -name *audio*effects*.conf -o -name *audio*effects*.xml\
     -o -name *audio*policy*.conf -o -name *stage*policy*.conf -o -name *audio*policy*.xml`
VAA=`find $VETC/audio -maxdepth 1 -type f -name *audio*effects*.conf -o -name *audio*effects*.xml\
     -o -name *audio*policy*.conf -o -name *stage*policy*.conf -o -name *audio*policy*.xml`
VBA=`find $VETC/audio/"$PROP" -maxdepth 1 -type f -name *audio*effects*.conf -o -name *audio*effects*.xml\
     -o -name *audio*policy*.conf -o -name *stage*policy*.conf -o -name *audio*policy*.xml`
if [ ! -d $ACDB ] || [ -f $ACDB/disable ]; then
  if [ "$AE" ]; then
    cp -f $AE $MODETC
  fi
  if [ "$VAE" ]; then
    cp -f $VAE $MODVETC
  fi
fi
if [ "$AP" ]; then
  cp -f $AP $MODETC
fi
if [ "$VAP" ]; then
  cp -f $VAP $MODVETC
fi
if [ "$VOA" ]; then
  cp -f $VOA $MODVOETC
fi
if [ "$VAA" ]; then
  cp -f $VAA $MODVETC/audio
fi
if [ "$VBA" ]; then
  cp -f $VBA $MODVETC/audio/"$PROP"
fi
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    VSA=`find $VETC/audio/$SKUS -maxdepth 1 -type f -name *audio*effects*.conf -o -name *audio*effects*.xml\
         -o -name *audio*policy*.conf -o -name *stage*policy*.conf -o -name *audio*policy*.xml`
    if [ "$VSA" ]; then
      cp -f $VSA $MODVETC/audio/$SKUS
    fi
  done
fi

# aml fix
DIR=$AML/system/vendor/odm/etc
if [ "$VOA" ] && [ -d $AML ] && [ ! -f $AML/disable ] && [ ! -d $DIR ]; then
  mkdir -p $DIR
  cp -f $VOA $DIR
fi
magiskpolicy --live "dontaudit vendor_configs_file labeledfs filesystem associate"
magiskpolicy --live "allow     vendor_configs_file labeledfs filesystem associate"
magiskpolicy --live "dontaudit init vendor_configs_file dir relabelfrom"
magiskpolicy --live "allow     init vendor_configs_file dir relabelfrom"
magiskpolicy --live "dontaudit init vendor_configs_file file relabelfrom"
magiskpolicy --live "allow     init vendor_configs_file file relabelfrom"
chcon -R u:object_r:vendor_configs_file:s0 $DIR

# run
sh $MODPATH/.aml.sh

# cleaning
FILE=$MODPATH/cleaner.sh
if [ -f $FILE ]; then
  sh $FILE
  rm -f $FILE
fi

) 2>/dev/null


