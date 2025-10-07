% Performance Profiling Howto v1.0  
% Tamás Dezső  
% Oct 7, 2025  
<!-- pandoc perf_howto.md -o perf_howto_v1.0.pdf \
    -V papersize:A4 \
    -V documentclass=article \
    -V geometry:margin=1in \
    -V colorlinks \
    --toc \
    --toc-depth=2 \
    --pdf-engine=xelatex \
    -V monofont='Ubuntu Mono'
-->


Perf
----

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


### Statistics

```bash
make
cd exec
rm /dev/shm/*_${USER} /dev/mqueue/*_${USER}
perf stat --detailed sfw_m -c mtest/sm_sip/perf/sfw.sm_sip.cfg -s sch/sfw.sm_sip.cfg.sch &
python/runTestFlow.py --keepMqsAndShms mtest/sm_sip/perf/perf_manual.tf
fg
# ctrl+C
```

E.g.,
```
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


### Branch Miss Profile

```bash
# perf_branch-misses.tf
#      "start" : "perf record -e branches,branch-misses -b sfw_m -c mtest/sm_sip/perf/sfw.sm_sip.cfg -s sch/sfw.sm_sip.cfg.sch"
#                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
python/runTestFlow.py mtest/sm_sip/perf/perf_branch-misses.tf
perf report
```

Then the report is browsable and even hot paths can be annotated with
assembly and C source lines.


FlameGraph
----------

FlameGraph is a visualization of stack traces of profiled software
so that the most frequent code-paths can be identified quickly and
accurately

- [Brendan Gregg's FlameGraph Page](https://www.brendangregg.com/flamegraphs.html)
- [FlameGraph on GitHub](https://github.com/brendangregg/FlameGraph)

```bash
git clone https://github.com/brendangregg/FlameGraph
FG=~/git/FlameGraph

# perf.tf
#      "start" : "perf record --call-graph lbr sfw_m -c mtest/sm_sip/perf/sfw.sm_sip.cfg -s sch/sfw.sm_sip.cfg.sch"
#                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
python/runTestFlow.py mtest/sm_sip/perf/perf.tf

perf script |
    ${FG}/stackcollapse-perf.pl |
    ${FG}/flamegraph.pl --title "XY Module CPU Profile" --subtitle "YYYY-MM-DD" >
    xy_module_flamegraph.svg
```


Call Graph
----------

`gprof2dot` is a Python script to convert the output from many
profilers (e.g., perf) into a dot graph. The call graph generated from
perf and gprof2dot visualizes how functions in the program call each
other and where the CPU time is spent.

Each node in the graph represents a function.

- The size or color intensity of a node corresponds to how much total
  CPU time that function (and its callees) consumed.
- Functions that appear larger or darker are typically performance hotspots.

Each edge (arrow) represents a function call.

- The direction shows the caller → callee relationship.
- The width or weight of an edge indicates how often that call occurred
  or how much time it contributed.

[gprof2dot on GitHub](https://github.com/jrfonseca/gprof2dot)

```bash
git clone https://github.com/jrfonseca/gprof2dot
G2D=~git/gprof2dot

perf script |
    ${G2D}/gprof2dot.py -f perf |
    dot -Tpdf -o xy_module_callgraph.pdf \
        -Glabel="XY Module CPU Profile\nYYYY-MM-DD" \
        -Gfontsize=24 -Glabelloc=top
```
