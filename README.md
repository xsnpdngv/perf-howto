% Performance Profiling v1.0  
% Tamás Dezső  
% Oct 13, 2025  


Abstract
========

`Per4M` is a Makefile based tool that helps creating call graphs and
flamegraphs from so called call-graph records saved by `perf`. To
produce such visualizations it uses the `flamegraph`, `gprof2dot` and
`dot` programs.


Perf
====

Perf is a universal performance measurement tool widely available on
Linux that does not need the code or the build system be modified to
work.

- [Perf Wiki](https://perfwiki.github.io/main/)
- [Brendan Gregg's Perf Examples](https://www.brendangregg.com/perf.html)

Profiling generally requires running the system under a representative
workload for a sufficient period of time to collect meaningful kernel
counters and stack traces. In practice, this means it’s best to create
an automated test that drives the module under test through a realistic
and broad usage scenario, ensuring that the collected performance data
accurately reflects typical behavior.


Statistics
----------

```bash
# Detailed CPU counter statistics (includes extras) for the specified command:
perf stat --detailed command

# CPU counter statistics for the process with the given PID, for 10 seconds:
perf stat -P PID sleep 10
```

E.g.,
```bash
perf stat --detailed sfw_m -c mtest/sm_sip/perf/sfw.sm_sip.cfg -s sch/sfw.sm_sip.cfg.sch
2025-10-03T23:56:43.371 sfw_m.c(685): Termination/interrupt signal received

 Performance counter stats for 'sfw_m -c mtest/sm_sip/perf/sfw.sm_sip.cfg -s sch/sfw.sm_sip.cfg.sch':

         18,892.05 msec task-clock:u              #    0.850 CPUs utilized          
                 0      context-switches:u        #    0.000 /sec                   
                 0      cpu-migrations:u          #    0.000 /sec                   
            77,230      page-faults:u             #    4.088 K/sec                  
    39,176,791,862      cycles:u                  #    2.074 GHz                      (50.02%)
    71,847,258,254      instructions:u            #    1.83  insn per cycle           (62.57%)
    16,428,509,700      branches:u                #  869.599 M/sec                    (62.51%)
        98,922,997      branch-misses:u           #    0.60% of all branches          (62.57%)
    17,082,532,700      L1-dcache-loads:u         #  904.218 M/sec                    (62.52%)
       991,169,722      L1-dcache-load-misses:u   #    5.80% of all L1-dcache accesses  (62.52%)
        10,095,019      LLC-loads:u               #  534.353 K/sec                    (49.96%)
           727,378      LLC-load-misses:u         #    7.21% of all LL-cache accesses  (49.89%)

      22.214520545 seconds time elapsed

      11.389845000 seconds user
       7.444356000 seconds sys
```


Diagnostics Report
------------------

```bash
perf list # shows available CPU performance measurement counters
perf record -e branches,branch-misses,cache-references,cache-misses -b command # writes perf.data
perf report # displays report from perf.data
```

Then the report is browsable and even hot paths can be annotated with
assembly and C source lines.

- `branches` and `branch-misses` measure how often branches occur and how frequently they are mispredicted.
- `cache-references` and `cache-misses` track overall cache accesses and misses across all cache levels.
- `L1-dcache-loads` and `L1-dcache-load-misses` show how often data loads miss in the L1 data cache.


FlameGraph
==========

FlameGraph is a visualization of stack traces of profiled software
so that the most frequent code-paths can be identified quickly and
accurately

- [Brendan Gregg's FlameGraph Page](https://www.brendangregg.com/flamegraphs.html)
- [FlameGraph on GitHub](https://github.com/brendangregg/FlameGraph)

```bash
git clone https://github.com/brendangregg/FlameGraph
FG=${PWD}/FlameGraph

perf record --call-graph lbr command # lbr: Last Branch Record

perf script \
    | ${FG}/stackcollapse-perf.pl \
    | ${FG}/flamegraph.pl \
    > xy_module_flamegraph.svg
```


Call Graph
==========

`gprof2dot` is a Python script to convert the output from many profilers
(e.g., perf) into a dot graph. The call graph is generated from perf and
gprof2dot visualizes how functions in the program call each other and
where the CPU time is spent.

[gprof2dot on GitHub](https://github.com/jrfonseca/gprof2dot)

```bash
git clone https://github.com/jrfonseca/gprof2dot
# gprof2dot/gprof2dot.py

# dot file output to interactively browse with xdot:
perf script \
    | gprof2dot -f perf \
    > callgraph.dot

# pdf output
dot -Tpdf -o callgraph.pdf < callgraph.dot
```


Per4M
=====

Record call graph data of the `command` and generate call graph and
flamegraph via the Makefile. Tune the parameters inside the Makefile if
needed.

```bash
perf record --call-graph lbr command
NAME=my_program SUB=subtitle make
# outputs:
# $(NAME)_callgraph_YYYY-MM-DD.dot
# $(NAME)_callgraph_YYYY-MM-DD.pdf
# $(NAME)_flamegraph_YYYY-MM-DD.svg
```

If `per4m`, `flamegraph` and `gprof2dot` are available elsewhere, make
`perf` produce text output from the recorded data, and use it on the
remote to create the graphs, e.g.,

```bash
perf script > perf.script
scp perf.script user@elswhere:path
ssh user@elsewhere
cd git/per4m
make
```

