#!/bin/sh

if   [[ ! -r proc_hier_pbench.v ]] ; then
    echo "Can't find proc_hier_pbench.v, what are you smoking?"
    exit 0;
fi

echo "Running tests from
perf \
complex_demofinal \
rand_final \
rand_ldst \
rand_idcache \
rand_icache \
rand_dcache \
complex_demo1 \
complex_demo2 \
rand_complex \
rand_ctrl \
inst_tests";

rm table.log;

bdir="/u/s/i/sinclair/courses/cs552/spring2022/handouts/testprograms/public";
for dname in \
perf \
complex_demofinal \
rand_final \
rand_ldst \
rand_idcache \
rand_icache \
rand_dcache \
complex_demo1 \
complex_demo2 \
rand_complex \
rand_ctrl \
inst_tests; do
  lfile=$bdir/$dname/all.list;
  echo -n "---------- Found $lfile, running..."; 
  ntests=`cat $lfile | wc -l`; echo $ntests" tests";
  wsrun.pl -maxf 1000 -brief -pipe -align -list  $lfile proc_hier_pbench *.v
  logfile=$dname.summary.log;
  cp summary.log $logfile;
done

