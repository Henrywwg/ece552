#!/bin/bash

if [[ ! -r proc_hier_pbench.v ]] ; then
    echo "Can't find proc_hier_pbench.v, what are you smoking?"
    exit 0;
fi

echo "Running tests from
inst_tests \
complex_demo1 \
rand_simple \
rand_complex \
rand_ctrl \
rand_mem \
complex_demo2";

rm table.log;

bdir="/u/s/w/swamit/public/html/courses/cs552/fall2024/handouts/testprograms/public";
for dname in \
inst_tests \
complex_demo1 \
rand_simple \
rand_complex \
rand_ctrl \
rand_mem \
complex_demo2; do
  lfile=$bdir/$dname/all.list;
  if [[ ! -r $lfile ]] ; then
    echo "Cannot find $lfile, this is not expected. Email TA or instructor";
    exit 0;
  fi
  echo -n "---------- Found $lfile, running..."; 
  ntests=`cat $lfile | wc -l`; echo $ntests" tests";
  wsrun.pl -maxf 1000 -brief -pipe -list  $lfile proc_hier_pbench *.v
  logfile=$dname.summary.log;
  mv summary.log $logfile;
done

