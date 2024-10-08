#!/bin/bash
#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "update_fds_timings [options]"
echo "This scripts reads in two timing files generated by firebot or smokebot.  It then outputs the:"
echo "   1. number of cases that had decreased run times and the total decreased tun time amount"
echo "   2. number of cases that had increased run times and the total increased run time amount"
echo "   3. total number of cases and net increase or (decrease) run time amount"
echo ""
echo "Options:"
echo "-a file - file containing 'after' fds case times [default: $after]"
echo "-A dir - directory containing 'after' timing file [default: $afterdir]"
echo "-b file - file containing 'before' fds case times [default: $before]"
echo "-B dir - directory containing 'before' timing file [default: $beforedir]"
echo "-h - display this message"
echo "-o dir  - directory containing output [default: $OUTPUT]"
exit 0
}

filelist=/tmp/fds_times$$.txt

CURDIR=`pwd`

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPTDIR
SCRIPTDIR=`pwd`
OUTPUT=$SCRIPTDIR

cd $CURDIR
figrepo=../../fig
cd $figrepo
figrepo=`pwd`

cd $CURDIR

beforedir=$figrepo/fds/Reference_Times
before=base_times.csv

afterdir=~firebot/.firebot/history
after=`ls -rtlm $afterdir/*timing*csv | grep -v bench | tail -1 | awk -F',' '{print $1}'`
after=`basename $after`

#*** parse options

while getopts 'a:A:b:B:d:ho:s:' OPTION
do
case $OPTION  in
  a)
   after="$OPTARG"
   ;;
  A)
   afterdir="$OPTARG"
   ;;
  b)
   before="$OPTARG"
   ;;
  B)
   beforedir="$OPTARG"
   ;;
  o)
   OUTPUT="$OPTARG"
   ;;
  h)
   usage;
   ;;
esac
done
shift $(($OPTIND-1))

TIMING_ERRORS=$OUTPUT/timing_errors
TIMING_LIST=$OUTPUT/timing_list
DIFFERENCES=$OUTPUT/fds_timing_diffs
SUMMARY=$OUTPUT/fds_timing_summary

botrepo=../../bot
cd $botrepo
botrepo=`pwd`
cd $CURDIR
rm -f $DIFFERENCES
rm -f $SUMMARY
rm -f $TIMING_ERRORS
rm -f $TIMING_LIST

cat $beforedir/$before | head -n -2 | awk -F ',' '{if (NR!=1)  {print($1) }}' > $filelist

files_up=0
files_down=0
time_up=0.0
time_down=0.0
for file in `cat $filelist`; do
  line_before=`grep $file $beforedir/$before`
  line_after=`grep  $file $afterdir/$after`
  if [ "$line_after" == "" ]; then
    continue
  fi
  time_before=`echo $line_before | awk -F',' '{print $3}'`
  time_before=$(printf "%.14f" $time_before)
  time_before=`echo $time_before | sed 's/\.*00*$//'`
  bigger_than=$((`echo "$time_before > 60.0"| bc`))
  time_after=`echo $line_after |   awk -F',' '{print $3}'`
  time_after=$(printf "%.14f" $time_after)
  time_after=`echo $time_after | sed 's/\.*00*$//'`
  time_diff=`echo "$time_after - $time_before" | bc`
  if [ $bigger_than -eq 1 ]; then
    rel_time_diff=`echo "100.0*$time_diff / $time_before" | bc`
    echo $file,$rel_time_diff,$time_before,$time_after >> $TIMING_LIST
    if [ $rel_time_diff -gt 200 ]; then
        echo $file,$rel_time_diff,$time_before,$time_after >> $TIMING_ERRORS
    fi
    echo $rel_time_diff >> $DIFFERENCES
    got_smaller=$((`echo "$time_before > $time_after"| bc`))
    if [ $got_smaller -eq 1 ]; then
      files_down=$((files_down+1))
      time_down=`echo "$time_down - ($time_diff)" | bc`
    else
      files_up=$((files_up+1))
      time_up=`echo "$time_up + ($time_diff)" | bc`
    fi
  fi
done
files_total=`echo "$files_up+$files_down"|bc`
time_total=`echo "$time_up-$time_down"|bc`

if [ "$before" == "base_times.csv" ]; then
  before_rev=`cat $figrepo/fds/Reference_Times/FDS_REVISION`
else
  before_rev=`echo $before | awk -F'_' '{print $1}'`
fi
after_rev=`echo $after   | awk -F'_' '{print $1}'`

echo "faster,$files_down,$time_down"  >  $SUMMARY
echo "slower,$files_up,$time_up"      >> $SUMMARY
echo "total,$files_total,$time_total" >> $SUMMARY
echo "base,$before_rev"               >> $SUMMARY
echo "current,$after_rev"             >> $SUMMARY

rm $filelist
