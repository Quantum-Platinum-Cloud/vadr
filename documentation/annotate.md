# <a name="top"></a> `v-annotate.pl` example usage, command-line options and alert information

* [`v-annotate.pl` example usage](#exampleusage)
  * [example annotation of norovirus sequences](#examplebasic)
  * [example of using `--alt_pass` to change alerts from fatal to non-fatal](#examplealtpass)
  * [example of using `-p` to run in parallel mode](#exampleparallel)
* [`v-annotate.pl` command-line options](#options)
  * [basic options](#options-basic)
  * [options for specifying expected sequence classification](#options-classification)
  * [options for controlling which alerts are fatal](#options-fatal)
  * [options related to model files](#options-modelfiles)
  * [options for controlling output feature table](#options-featuretable)
  * [options for controlling alert thresholds](#options-alerts)
  * [options for controlling the alignment stage](#options-align)
  * [options for controlling the blastx protein validation stage](#options-blastx)
  * [options for using hmmer instead of blastx for protein validation](#options-hmmer)
  * [options related to blastn-based seeded alignment acceleration strategy](#options-seed)
  * [options related to pre-processing to replace Ns with expected nucleotides](#options-replace)
  * [options related to parallelization on a compute farm/cluster](#options-parallel)
  * [options for skipping stages](#options-skip)
  * [options for additional output files](#options-output)
  * [additional expert options](#options-expert)
* [Basic Information on `v-annotate.pl` alerts](#alerts)
* [Additional information on `v-annotate.pl` alerts](#alerts2)

---

## `v-annotate.pl` example usage <a name="exampleusage"></a>

`v-annotate.pl` uses previously created VADR models from `v-build.pl`
to analyze and annotate sequences in an input sequence file. As part
of the analysis of the sequences, more than 40 types of unexpected
characteristics, or *alerts* are detected and reported in the
output. Most of the alerts are *fatal* in that if a sequence has one
or more fatal alerts, they will be designated as *failing*
sequences. Sequences with zero fatal alerts are designated as
*passing* sequences. The types of alerts are described further below.

To determine the command-line usage of 
`v-annotate.pl` (or any VADR script), use the `-h` option, like this:

```
v-annotate.pl -h 
```

You'll see something like the following output:
```
# v-annotate.pl :: classify and annotate sequences using a CM library
# VADR 1.1 (May 2020)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Wed May  6 07:30:55 2020
#
Usage: v-annotate.pl [-options] <fasta file to annotate> <output directory to create>
```

The first few lines are the banner which show the name of the VADR
script being run along with the version and release date. This is
followed by the time and date the command was executed.  The `Usage:`
line details the expected command line arguments.  `v-annotate.pl` takes
as input two command line arguments, a fasta file with sequences to 
analyze and annotate (`<fasta file to annotate>`) and and the name of the output directory you
want it to create (`<output directory to create>`) and
populate with output files.

After that comes a list of all available command-line options. These
are explained in more detail [below](#options).

<a name="examplebasic"></a>Here is an example `v-annotate.pl` command
using the fasta file
[vadr/documentation/annotate-files/noro.9.fa](annotate-files/noro.9.fa)
with 9 norovirus sequences, and creating an output directory with
`va-noro.9`:

```
v-annotate.pl $VADRSCRIPTSDIR/documentation/annotate-files/noro.9.fa va-noro.9
```
The standard output of `v-annotate.pl` that is printed to the screen
(which is also output to the `.log` output file) begins with the
banner and date again followed by a list of relevant environment
variables, the command line arguments used and any command line
options used:

```
# date:              Wed May  6 07:31:23 2020
# $VADRBIOEASELDIR:  /home/nawrocki/vadr-install-dir/Bio-Easel
# $VADRBLASTDIR:     /home/nawrocki/vadr-install-dir/ncbi-blast/bin
# $VADREASELDIR:     /home/nawrocki/vadr-install-dir/infernal/binaries
# $VADRINFERNALDIR:  /home/nawrocki/vadr-install-dir/infernal/binaries
# $VADRMODELDIR:     /home/nawrocki/vadr-install-dir/vadr-models
# $VADRSCRIPTSDIR:   /home/nawrocki/vadr-install-dir/vadr
#
# sequence file:     /home/nawrocki/vadr-install-dir/vadr/documentation/annotate-files/noro.9.fa
# output directory:  va-noro.9
```

No command line options were used in our example output, but if they
were information on them would have appeared after the `output
directory` line.

Next, information is output about each step the script is proceeding
through. When each step is completed, the elapsed time for that step
is output. 

`v-annotate.pl` will use the default VADR model library (CM file
`$VADRMODELDIR/vadr.cm`, model info file `$VADRMODELDIR/vadr.minfo`
and BLAST DBs in $VADRMODELDIR) to analyze the sequences in
`noro.9.fa`, and will create an output directory named `va-noro.9` and
populate it with [many output files](formats.md#annotate). 

There are four main stages to `v-annotate.pl`

1. Classification: each sequence `S` in the input file is compared
against all models in the model library to determine the best-matching
(highest-scoring) model `M(S)` for each sequence.

2. Coverage determination: each sequence `S` is compared again to
`M(S)` to determine the *coverage* of `S`, which is basically the
fraction of nucleotides in `S` that appear to be homologous
(sufficiently similar) to `M(S)`.

3. Alignment and feature mapping: each sequence `S` is aligned to
`M(S)` and based on that alignment, features of `M(S)` are mapped onto
`S`.

4. Protein validation of CDS features: for each sequence `S` that has
1 or more predicted CDS features, `blastx` or `hmmsearch` is used to
compare the predicted CDS and the full sequence `S` against the VADR
library BLAST or HMM DB.

The output of `v-annotate.pl` lists one or more steps per stage. The
first two steps are:

```
# Validating input                                                                        ... done. [    4.9 seconds]
# Classifying sequences (9 seqs)                                                          ... done. [   16.3 seconds]
```

The first step validates that the VADR library `.minfo` file being
used corresponds to the VADR library `.cm` file. Next, the
classification stage is performed. After that, each model that is 
`M(S)` for at least one `S` is run separately through the coverage
determination stage for all of its sequences:

```
# Determining sequence coverage (NC_001959: 1 seq)                                        ... done. [    0.5 seconds]
# Determining sequence coverage (NC_008311: 2 seqs)                                       ... done. [    1.8 seconds]
# Determining sequence coverage (NC_029645: 2 seqs)                                       ... done. [    0.6 seconds]
# Determining sequence coverage (NC_039477: 2 seqs)                                       ... done. [    1.8 seconds]
# Determining sequence coverage (NC_044854: 2 seqs)                                       ... done. [    0.4 seconds]
```

Next, the alignments are performed for each model, and used to map
feature annotation:

```
# Aligning sequences (NC_001959: 1 seq)                                                   ... done. [    0.5 seconds]
# Aligning sequences (NC_008311: 2 seqs)                                                  ... done. [    7.7 seconds]
# Aligning sequences (NC_029645: 2 seqs)                                                  ... done. [    1.0 seconds]
# Aligning sequences (NC_039477: 2 seqs)                                                  ... done. [    8.2 seconds]
# Aligning sequences (NC_044854: 2 seqs)                                                  ... done. [    0.5 seconds]
# Determining annotation                                                                  ... done. [    0.2 seconds]
```

The classification and alignment stages are typically the
slowest. The protein validation stage is usually relatively fast:

```
# Validating proteins with blastx (NC_001959: 1 seq)                                      ... done. [    0.4 seconds]
# Validating proteins with blastx (NC_008311: 2 seqs)                                     ... done. [    0.2 seconds]
# Validating proteins with blastx (NC_029645: 2 seqs)                                     ... done. [    0.1 seconds]
# Validating proteins with blastx (NC_039477: 2 seqs)                                     ... done. [    0.2 seconds]
# Validating proteins with blastx (NC_044854: 2 seqs)                                     ... done. [    0.1 seconds]
```

The only remaining steps are to create the output files:

```
# Generating tabular output                                                               ... done. [    0.0 seconds]
# Generating feature table output                                                         ... done. [    0.0 seconds]
```

After the output files are generated, a summary of the results is
output, starting with a list of all models that were 
the best matching model to one or more sequences: 

```
# Summary of classified sequences:
#
#                                      num   num   num
#idx  model      group      subgroup  seqs  pass  fail
#---  ---------  ---------  --------  ----  ----  ----
1     NC_008311  Norovirus  GV           2     1     1
2     NC_029645  Norovirus  GIII         2     2     0
3     NC_039477  Norovirus  GII          2     2     0
4     NC_044854  Norovirus  GI           2     2     0
5     NC_001959  Norovirus  GI           1     1     0
#---  ---------  ---------  --------  ----  ----  ----
-     *all*      -          -            9     8     1
-     *none*     -          -            0     0     0
#---  ---------  ---------  --------  ----  ----  ----
```

The above table is also saved to a file with the suffix `.mdl`,
and the format is described in more detail [here](formats.md#mdl).

The nine input sequences collectively had five different best-matching
models, all Norovirus models with the subgroups shown above. (The
groups and subgroups shown above were input as [command-line
options](build.md#options-attributes) to `v-build.pl` when the models
were built. An example is [here](build.md#1.0library-noro).  Eight of
the nine sequences *passed* and one *failed*.

Next, the alerts reported for the sequences are summarized:

```
# Summary of reported alerts:
#
#     alert     causes   short                            per    num   num  long
#idx  code      failure  description                     type  cases  seqs  description
#---  --------  -------  ---------------------------  -------  -----  ----  -----------
1     mutendcd  yes      MUTATION_AT_END              feature      1     1  expected stop codon could not be identified, predicted CDS stop by homology is invalid
2     cdsstopn  yes      CDS_HAS_STOP_CODON           feature      1     1  in-frame stop codon exists 5' of stop position predicted by homology to reference
3     cdsstopp  yes      CDS_HAS_STOP_CODON           feature      1     1  stop codon in protein-based alignment
4     indf5pst  yes      INDEFINITE_ANNOTATION_START  feature      1     1  protein-based alignment does not extend close enough to nucleotide-based alignment 5' endpoint
5     indf3pst  yes      INDEFINITE_ANNOTATION_END    feature      1     1  protein-based alignment does not extend close enough to nucleotide-based alignment 3' endpoint
#---  --------  -------  ---------------------------  -------  -----  ----  -----------
```

For the nine sequences, there were five different alert codes
reported, each with one case for a single sequence. This tabular
summary does not indicate to which sequence(s) each alert pertains.
We can find that out from other output files as discussed further
below.

Next, the list of output files created by `v-annotate.pl` is
printed, along with elapsed time:

```
# Output printed to screen saved in:                               va-noro.9.vadr.log
# List of executed commands saved in:                              va-noro.9.vadr.cmd
# List and description of all output files saved in:               va-noro.9.vadr.filelist
# copy of input fasta file saved in:                               va-noro.9.vadr.in.fa
# esl-seqstat -a output for input fasta file saved in:             va-noro.9.vadr.seqstat
# model NC_001959 feature gene#1 predicted seqs saved in:          va-noro.9.vadr.NC_001959.gene.1.fa
# model NC_001959 feature CDS#1 predicted seqs saved in:           va-noro.9.vadr.NC_001959.CDS.1.fa
# model NC_001959 feature gene#2 predicted seqs saved in:          va-noro.9.vadr.NC_001959.gene.2.fa
# model NC_001959 feature CDS#2 predicted seqs saved in:           va-noro.9.vadr.NC_001959.CDS.2.fa
# model NC_001959 feature mat_peptide#6 predicted seqs saved in:   va-noro.9.vadr.NC_001959.mat_peptide.6.fa
# model NC_008311 feature gene#1 predicted seqs saved in:          va-noro.9.vadr.NC_008311.gene.1.fa
# model NC_008311 feature CDS#1 predicted seqs saved in:           va-noro.9.vadr.NC_008311.CDS.1.fa
# model NC_008311 feature gene#2 predicted seqs saved in:          va-noro.9.vadr.NC_008311.gene.2.fa
# model NC_008311 feature CDS#2 predicted seqs saved in:           va-noro.9.vadr.NC_008311.CDS.2.fa
# model NC_008311 feature gene#3 predicted seqs saved in:          va-noro.9.vadr.NC_008311.gene.3.fa
# model NC_008311 feature CDS#3 predicted seqs saved in:           va-noro.9.vadr.NC_008311.CDS.3.fa
# model NC_008311 feature mat_peptide#6 predicted seqs saved in:   va-noro.9.vadr.NC_008311.mat_peptide.6.fa
# model NC_008311 feature gene#4 predicted seqs saved in:          va-noro.9.vadr.NC_008311.gene.4.fa
# model NC_008311 feature CDS#4 predicted seqs saved in:           va-noro.9.vadr.NC_008311.CDS.4.fa
# model NC_008311 feature mat_peptide#1 predicted seqs saved in:   va-noro.9.vadr.NC_008311.mat_peptide.1.fa
# model NC_008311 feature mat_peptide#2 predicted seqs saved in:   va-noro.9.vadr.NC_008311.mat_peptide.2.fa
# model NC_008311 feature mat_peptide#3 predicted seqs saved in:   va-noro.9.vadr.NC_008311.mat_peptide.3.fa
# model NC_008311 feature mat_peptide#4 predicted seqs saved in:   va-noro.9.vadr.NC_008311.mat_peptide.4.fa
# model NC_008311 feature mat_peptide#5 predicted seqs saved in:   va-noro.9.vadr.NC_008311.mat_peptide.5.fa
# model NC_029645 feature gene#1 predicted seqs saved in:          va-noro.9.vadr.NC_029645.gene.1.fa
# model NC_029645 feature CDS#1 predicted seqs saved in:           va-noro.9.vadr.NC_029645.CDS.1.fa
# model NC_029645 feature gene#2 predicted seqs saved in:          va-noro.9.vadr.NC_029645.gene.2.fa
# model NC_029645 feature CDS#2 predicted seqs saved in:           va-noro.9.vadr.NC_029645.CDS.2.fa
# model NC_029645 feature mat_peptide#6 predicted seqs saved in:   va-noro.9.vadr.NC_029645.mat_peptide.6.fa
# model NC_039477 feature gene#1 predicted seqs saved in:          va-noro.9.vadr.NC_039477.gene.1.fa
# model NC_039477 feature CDS#1 predicted seqs saved in:           va-noro.9.vadr.NC_039477.CDS.1.fa
# model NC_039477 feature gene#2 predicted seqs saved in:          va-noro.9.vadr.NC_039477.gene.2.fa
# model NC_039477 feature CDS#2 predicted seqs saved in:           va-noro.9.vadr.NC_039477.CDS.2.fa
# model NC_039477 feature gene#3 predicted seqs saved in:          va-noro.9.vadr.NC_039477.gene.3.fa
# model NC_039477 feature CDS#3 predicted seqs saved in:           va-noro.9.vadr.NC_039477.CDS.3.fa
# model NC_039477 feature mat_peptide#1 predicted seqs saved in:   va-noro.9.vadr.NC_039477.mat_peptide.1.fa
# model NC_039477 feature mat_peptide#2 predicted seqs saved in:   va-noro.9.vadr.NC_039477.mat_peptide.2.fa
# model NC_039477 feature mat_peptide#3 predicted seqs saved in:   va-noro.9.vadr.NC_039477.mat_peptide.3.fa
# model NC_039477 feature mat_peptide#4 predicted seqs saved in:   va-noro.9.vadr.NC_039477.mat_peptide.4.fa
# model NC_039477 feature mat_peptide#5 predicted seqs saved in:   va-noro.9.vadr.NC_039477.mat_peptide.5.fa
# model NC_039477 feature mat_peptide#6 predicted seqs saved in:   va-noro.9.vadr.NC_039477.mat_peptide.6.fa
# model NC_044854 feature gene#1 predicted seqs saved in:          va-noro.9.vadr.NC_044854.gene.1.fa
# model NC_044854 feature CDS#1 predicted seqs saved in:           va-noro.9.vadr.NC_044854.CDS.1.fa
# model NC_044854 feature mat_peptide#6 predicted seqs saved in:   va-noro.9.vadr.NC_044854.mat_peptide.6.fa
# model NC_044854 feature gene#2 predicted seqs saved in:          va-noro.9.vadr.NC_044854.gene.2.fa
# model NC_044854 feature CDS#2 predicted seqs saved in:           va-noro.9.vadr.NC_044854.CDS.2.fa
# per-sequence tabular annotation summary file saved in:           va-noro.9.vadr.sqa
# per-sequence tabular classification summary file saved in:       va-noro.9.vadr.sqc
# per-feature tabular summary file saved in:                       va-noro.9.vadr.ftr
# per-model-segment tabular summary file saved in:                 va-noro.9.vadr.sgm
# per-model tabular summary file saved in:                         va-noro.9.vadr.mdl
# per-alert tabular summary file saved in:                         va-noro.9.vadr.alt
# alert count tabular summary file saved in:                       va-noro.9.vadr.alc
# 5 column feature table output for passing sequences saved in:    va-noro.9.vadr.pass.tbl
# 5 column feature table output for failing sequences saved in:    va-noro.9.vadr.fail.tbl
# list of passing sequences saved in:                              va-noro.9.vadr.pass.list
# list of failing sequences saved in:                              va-noro.9.vadr.fail.list
# list of alerts in the feature tables saved in:                   va-noro.9.vadr.alt.list
#
# All output files created in directory ./va-noro.9/
#
# Elapsed time:  00:00:45.57
#                hh:mm:ss
# 
[ok]
```

All of these files were created in the newly created directory
`va-noro.9`.  What follows is a brief discussion of some of these
output file types.  More information on these files and their formats
can be found [here](formats.md#annotate).

The first three files are the [`.log` file](formats.md#log), which is
the same as the standard output printed to the screen currently being
discussed, the [`.cmd` file](formats.md#cmd), and the [`.filelist`
file](formats.md#filelist) which lists the output files created by
`v-annotate.pl`. Next comes a [`.seqstat` file](annotate.md#seqstat)
with lengths for each sequence in the input file.

Then come about 40 FASTA-formatted sequence files with subsequences
of the predicted features for each sequence, grouped by each
model. There will be one file for each model/feature pair that is
annotated in at least one sequence.  Each file will contain all
subsequences of input sequences that match best to the corresponding
model, and that have the corresponding feature annotated. An example
of this type of file is `va-noro.9.vadr.NC_039477.CDS.2.fa`, which
contains the predicted CDS sequences for CDS #2 for the sequences for
which the best matching model was `NC_039477`. The convention used for
naming the sequences in these files is explained
[here](formats#seqnames).

After the FASTA files are seven tabular summary files that end with
three letter suffixes:

| suffix | description | reference | 
|--------|-------------|-----------|
| `.alc` | per-alert code information (counts)     | [description of format](formats.md#alc) |
| `.alt` | per-alert instance information          | [description of format](formats.md#alt) |
| `.ftr` | per-feature information                 | [description of format](formats.md#ftr) |
| `.mdl` | per-model information                   | [description of format](formats.md#mdl) |
| `.sgm` | per-segment information                 | [description of format](formats.md#sgm) |
| `.sqa` | per-sequence annotation information     | [description of format](formats.md#sqa) |
| `.sqc` | per-sequence classification information | [description of format](formats.md#sqc) |

The contents of the `.mdl` and `.alc` files were already output by
`v-annotate.pl` as covered above. To get more information on each
sequence, see the `.sqa` and `.sqc` files. The `.sqc` file
(`va-noro.9.vadr.sqc`) includes
information on the classification of each sequence:

```
#seq  seq          seq                                   sub                    seq    mdl         num                             sub     score  diff/  seq   
#idx  name         len  p/f   ant  model1     grp1       grp1   score  sc/nt    cov    cov  bias  hits  str  model2     grp2       grp2     diff     nt  alerts
#---  ----------  ----  ----  ---  ---------  ---------  ----  ------  -----  -----  -----  ----  ----  ---  ---------  ---------  -----  ------  -----  ------
1     KY887602.1  7547  PASS  yes  NC_039477  Norovirus  GII   8142.8  1.079  1.000  0.997  12.5     1    +  NC_044046  Norovirus  GVIII  4348.2  0.576  -     
2     KT818729.1   243  PASS  yes  NC_044854  Norovirus  GI     170.4  0.701  0.996  0.031     0     1    +  NC_044932  Norovirus  GII      90.0  0.370  -     
3     EU437710.1   291  PASS  yes  NC_001959  Norovirus  GI     249.4  0.857  1.000  0.038     0     1    +  NC_044855  Norovirus  GIV     161.5  0.555  -     
4     DQ288307.1  1094  PASS  yes  NC_029645  Norovirus  GIII   973.4  0.890  1.000  0.150   6.2     1    +  NC_001959  Norovirus  GI      671.1  0.613  -     
5     AY237464.1   255  PASS  yes  NC_039477  Norovirus  GII    221.1  0.867  1.000  0.034     0     1    +  NC_044047  Norovirus  GVII    113.5  0.445  -     
6     KF475958.1   275  PASS  yes  NC_044854  Norovirus  GI     248.0  0.902  1.000  0.036     0     1    +  NC_044932  Norovirus  GII     164.0  0.596  -     
7     AB713840.1   347  PASS  yes  NC_008311  Norovirus  GV     330.6  0.953  1.000  0.047   0.2     1    +  NC_040876  Norovirus  GII     239.5  0.690  -     
8     JN585032.1   286  PASS  yes  NC_029645  Norovirus  GIII   242.3  0.847  0.997  0.039   0.1     1    +  NC_039897  Norovirus  GI      154.8  0.541  -     
9     JN975492.1  7286  FAIL  yes  NC_008311  Norovirus  GV    4666.2  0.640  1.000  0.987  16.8     1    +  NC_044047  Norovirus  GVII   3382.8  0.464  -    
```

This file includes per-sequence information on whether each sequence
passed or failed, its best and second-best matching model, and scores
and coverage. The difference in score between the best and second-best
model gives an indication of how confidently classified the sequence
is to the best-matching model. (The `qstgroup` and `qstsbgrp` alerts
are reported if these scores are not sufficiently far apart to alert
the user that a sequence is not confidently classified.) Note that the
sequence `JN975492.1` is the only sequence that failed. It has no `seq
alerts` listed in the final field, so the fatal alerts that caused it
to fail must have been per-feature alerts. These can be seen in the
`.ftr` and `.alt` files. An explanation of all fields in the `.sqc`
file type is [here](formats.md#sqc).

Next, take a look at the first few lines of the `.ftr` file (`va-noro.9.vadr.ftr`):

```
#     seq          seq                   ftr          ftr                         ftr  ftr                                                                                     seq         model  ftr   
#idx  name         len  p/f   model      type         name                        len  idx  str  n_from  n_to  n_instp  trc    p_from  p_to  p_instp  p_sc  nsa  nsn        coords        coords  alerts
#---  ----------  ----  ----  ---------  -----------  -------------------------  ----  ---  ---  ------  ----  -------  -----  ------  ----  -------  ----  ---  ---  ------------  ------------  ------
1.1   KY887602.1  7547  PASS  NC_039477  gene         ORF1                       5083    1    +       1  5083        -  5'          -     -        -     -    1    0     1..5083:+    22..5104:+  -     
1.2   KY887602.1  7547  PASS  NC_039477  CDS          nonstructural_polyprotein  5083    2    +       1  5083        -  5'          2  5080        -  9094    1    0     1..5083:+    22..5104:+  -     
1.3   KY887602.1  7547  PASS  NC_039477  gene         ORF2                       1623    3    +    5064  6686        -  no          -     -        -     -    1    0  5064..6686:+  5085..6707:+  -     
1.4   KY887602.1  7547  PASS  NC_039477  CDS          VP1                        1623    4    +    5064  6686        -  no       5064  6683        -  2878    1    0  5064..6686:+  5085..6707:+  -     
1.5   KY887602.1  7547  PASS  NC_039477  gene         ORF3                        807    5    +    6686  7492        -  no          -     -        -     -    1    0  6686..7492:+  6707..7513:+  -     
1.6   KY887602.1  7547  PASS  NC_039477  CDS          VP2                         807    6    +    6686  7492        -  no       6686  7486        -  1393    1    0  6686..7492:+  6707..7513:+  -     
1.7   KY887602.1  7547  PASS  NC_039477  mat_peptide  p48                         979    7    +       1   979        -  5'          -     -        -     -    1    0      1..979:+    22..1000:+  -     
1.8   KY887602.1  7547  PASS  NC_039477  mat_peptide  NTPase                     1098    8    +     980  2077        -  no          -     -        -     -    1    0   980..2077:+  1001..2098:+  -     
1.9   KY887602.1  7547  PASS  NC_039477  mat_peptide  p22                         531    9    +    2078  2608        -  no          -     -        -     -    1    0  2078..2608:+  2099..2629:+  -     
1.10  KY887602.1  7547  PASS  NC_039477  mat_peptide  VPg                         399   10    +    2609  3007        -  no          -     -        -     -    1    0  2609..3007:+  2630..3028:+  -     
1.11  KY887602.1  7547  PASS  NC_039477  mat_peptide  Pro                         543   11    +    3008  3550        -  no          -     -        -     -    1    0  3008..3550:+  3029..3571:+  -     
1.12  KY887602.1  7547  PASS  NC_039477  mat_peptide  RdRp                       1530   12    +    3551  5080        -  no          -     -        -     -    1    0  3551..5080:+  3572..5101:+  -     
#
```
This file includes information on each annotated feature, organized by
sequence. The lines above show the annotated features for the first
sequence `KY887602.1` and include information on the feature length,
strand, positions in the sequence and in the reference model, whether
it is truncated or not, and where the blastx protein validation stage
predicted coordinates are. The `seq coords` and `mdl coords` lines
near the end show the sequence and model coordinates of each feature
in the VADR coordinate string format, described
[here](formats.md#coords). 
The final column lists any alerts
pertaining to each feature. For the features in this sequence there
are no alerts, but for the final sequence, some alerts are listed for the
second CDS. An explanation of all fields in the `.ftr`
file type is [here](formats.md#ftr).

Another important file is the `.alt` output file (`va-noro9.vadr.alt`)
which includes one line per alert reported:

```
#      seq                    ftr   ftr   ftr  alert           alert                        alert 
#idx   name        model      type  name  idx  code      fail  desc                         detail
#----  ----------  ---------  ----  ----  ---  --------  ----  ---------------------------  ------
9.1.1  JN975492.1  NC_008311  CDS   VF1     6  mutendcd  yes   MUTATION_AT_END              expected stop codon could not be identified, predicted CDS stop by homology is invalid [TCA ending at position 5685 on + strand is not a valid stop]
9.1.2  JN975492.1  NC_008311  CDS   VF1     6  cdsstopn  yes   CDS_HAS_STOP_CODON           in-frame stop codon exists 5' of stop position predicted by homology to reference [revised to 5044..5277 (stop shifted 408 nt)]
9.1.3  JN975492.1  NC_008311  CDS   VF1     6  cdsstopp  yes   CDS_HAS_STOP_CODON           stop codon in protein-based alignment [stop codon(s) end at position(s) 5277]
9.1.4  JN975492.1  NC_008311  CDS   VF1     6  indf3pst  yes   INDEFINITE_ANNOTATION_END    protein-based alignment does not extend close enough to nucleotide-based alignment 3' endpoint [36 > 5 (strand:+ CM:5685 blastx:5649, no valid stop codon in CM prediction)]
9.2.1  JN975492.1  NC_008311  CDS   VP2     8  indf5pst  yes   INDEFINITE_ANNOTATION_START  protein-based alignment does not extend close enough to nucleotide-based alignment 5' endpoint [54 > 5 (strand:+ CM:6656 blastx:6710)]
```     

All alerts are for the `JN975492.1` sequence. Four are for the VF1 CDS
and 1 is for the VP2 CDS. The alert codes are listed in the seventh
column, along with a brief description in the eight column followed by
a more detailed description, sometimes with positional information, at
the end of the line. All possible alerts are listed in the [alert
table](#alerttable).

In addition to the tabular output files, `v-annotate.pl` also creates 
5-column tab-delimited feature table files that end with the suffix
`.tbl`. There is a separate file for passing
(`va-noro9.vadr.pass.tbl`) and failing (`va-noro9.vadr.fail.tbl`)
sequences. 
The format of the `.tbl` files is described here:
https://www.ncbi.nlm.nih.gov/Sequin/table.html.
These files contain some of the same information as the `.ftr` files
discussed above, with some additional information on *qualifiers* for
features read from the [model info file](formats.md#minfo). 
From the `va-noro9.vadr.pass.tbl` file, the feature table for
`KY887602` is: 

```
>Feature KY887602.1
<1	5083	gene
			gene	ORF1
<1	5083	CDS
			product	nonstructural polyprotein
			codon_start	2
			protein_id	KY887602.1_1
<1	979	mat_peptide
			product	p48
			protein_id	KY887602.1_1
980	2077	mat_peptide
			product	NTPase
			protein_id	KY887602.1_1
2078	2608	mat_peptide
			product	p22
			protein_id	KY887602.1_1
2609	3007	mat_peptide
			product	VPg
			protein_id	KY887602.1_1
3008	3550	mat_peptide
			product	Pro
			protein_id	KY887602.1_1
3551	5080	mat_peptide
			product	RdRp
			protein_id	KY887602.1_1
5064	6686	gene
			gene	ORF2
5064	6686	CDS
			product	VP1
			protein_id	KY887602.1_2
6686	7492	gene
			gene	ORF3
6686	7492	CDS
			product	VP2
			protein_id	KY887602.1_3
```

In the `.fail.tbl` file, each sequence's feature table contains a
special section at the end of the table that lists errors
due to reported fatal alerts. For example, at the end of
`va-noro9.vadr.fail.tbl`:

```
Additional note(s) to submitter:
ERROR: CDS_HAS_STOP_CODON: (VF1) in-frame stop codon exists 5' of stop position predicted by homology to reference [revised to 5044..5277 (stop shifted 408 nt)]
ERROR: CDS_HAS_STOP_CODON: (VF1) stop codon in protein-based alignment [stop codon(s) end at position(s) 5277]
ERROR: INDEFINITE_ANNOTATION_END: (VF1) protein-based alignment does not extend close enough to nucleotide-based alignment 3' endpoint [36 > 5 (strand:+ CM:5685 blastx:5649, no valid stop codon in CM prediction)]
ERROR: INDEFINITE_ANNOTATION_START: (VP2) protein-based alignment does not extend close enough to nucleotide-based alignment 5' endpoint [54 > 5 (strand:+ CM:6656 blastx:6710)]
```

Note that this file lists only four ERRORs while the `.alt` output
file above listed five alerts. **Not all** fatal alerts will be
printed to this `.fail.tbl` file, because when specific pairs of
alerts occur, only one is output to reduce the number of overlapping
or redundant problems reported to the submitter/user. In this case the
`mutendcd` (`MUTATION_AT_END`) alert is omitted in the `.fail.tbl`
file because it occurs in combination with a `cdsstopn`
(`CDS_HAS_STOP_CODON`) alert. But this is rare, as only one alert
(`mutendcd`) can possibly be omitted. See the
far right column of the [this table](#alerts2) for which alerts,
when present in combination with `mutendcd` causes it
to be omitted. Only alerts output to the `.fail.tbl`
table are output to the `.alt.list` file. 

The final three output files all end in `.list`. The `.pass.list` and
`.fail.list` files are simply lists of all passing and failing
sequences, respectively, with each sequence listed on a separate
line. The `.alt.list` file lists all alerts that cause errors in the
`.fail.tbl` file in a four field  tab-delimited format described
[here](formats.md#altlist). The `va-noro9.vadr.alt.list` file lists
the four alerts/errors in the `.fail.tbl` file shown above:

```
#sequence	error	feature	error-description
JN975492.1	CDS_HAS_STOP_CODON	VF1	in-frame stop codon exists 5' of stop position predicted by homology to reference [revised to 5044..5277 (stop shifted 408 nt)]
JN975492.1	CDS_HAS_STOP_CODON	VF1	stop codon in protein-based alignment [stop codon(s) end at position(s) 5277]
JN975492.1	INDEFINITE_ANNOTATION_END	VF1	protein-based alignment does not extend close enough to nucleotide-based alignment 3' endpoint [36 > 5 (strand:+ CM:5685 blastx:5649, no valid stop codon in CM prediction)]
JN975492.1	INDEFINITE_ANNOTATION_START	VP2	protein-based alignment does not extend close enough to nucleotide-based alignment 5' endpoint [54 > 5 (strand:+ CM:6656 blastx:6710)]
```

##  <a name="examplealtpass"></a>Example of using the `v-annotate.pl` `--alt_pass` and `--alt_fail` to change alerts from fatal to non-fatal and vice versa

One way to change the behavior of `v-annotate.pl` is to change which
alerts are fatal or non-fatal.  Most alerts are fatal by default, but
some are not, as shown in the [alert table](#alerts).  Some alerts are
*always fatal* in that they cannot be changed, but all others can be
toggled between fatal or non-fatal using the `--alt_pass` and `--alt_fail` options.

For example, we can make the `JN976492.1` sequence above pass by
making the five observed alerts (*mutendcd*, *cdsstopn*, *cdsstopp*,
*indf3pst*, and *indf5pst*) by rerunning the `v-annotate.pl` above with this command: 

```
v-annotate.pl --alt_pass mutendcd,cdsstopn,cdsstopp,indf3pst,indf5pst $VADRSCRIPTSDIR/documentation/annotate-files/noro.9.fa va-pass-noro.9
```

To supply multiple alerts with `--alt_pass` or `--alt_fail`, separate them by a `,` without any whitespace, like above.

The output will look very similar to the earlier run, but the summary
information printed at the end will show that no sequences fail this
time, despite the same alerts being reported.

```
# Summary of classified sequences:
#
#                                      num   num   num
#idx  model      group      subgroup  seqs  pass  fail
#---  ---------  ---------  --------  ----  ----  ----
1     NC_008311  Norovirus  GV           2     2     0
2     NC_039477  Norovirus  GII          2     2     0
3     NC_044854  Norovirus  GI           2     2     0
4     NC_029645  Norovirus  GIII         2     2     0
5     NC_001959  Norovirus  GI           1     1     0
#---  ---------  ---------  --------  ----  ----  ----
-     *all*      -          -            9     9     0
-     *none*     -          -            0     0     0
#---  ---------  ---------  --------  ----  ----  ----
#
# Summary of reported alerts:
#
#     alert     causes   short                            per    num   num  long
#idx  code      failure  description                     type  cases  seqs  description
#---  --------  -------  ---------------------------  -------  -----  ----  -----------
1     mutendcd  no       MUTATION_AT_END              feature      1     1  expected stop codon could not be identified, predicted CDS stop by homology is invalid
2     cdsstopn  no       CDS_HAS_STOP_CODON           feature      1     1  in-frame stop codon exists 5' of stop position predicted by homology to reference
3     cdsstopp  no       CDS_HAS_STOP_CODON           feature      1     1  stop codon in protein-based alignment
4     indf5pst  no       INDEFINITE_ANNOTATION_START  feature      1     1  protein-based alignment does not extend close enough to nucleotide-based alignment 5' endpoint
5     indf3pst  no       INDEFINITE_ANNOTATION_END    feature      1     1  protein-based alignment does not extend close enough to nucleotide-based alignment 3' endpoint
#---  --------  -------  ---------------------------  -------  -----  ----  -----------
```

The `--alt_fail <s>` option works the same way as `alt_pass <s>` but alert codes
in `<s>` should be [non-fatal by default](#nonfatal1).

---
## <a name="exampleparallel"></a>Example of using the `-p` option to parallelize `v-annotate.pl`

The most time-consuming stages of `v-annotate.pl` (classification,
coverage determination and alignment) can be parallelized on a cluster
by splitting up the input sequence file randomly into multiple files,
and running each as a separate job. This is most beneficial for large
input sequence files. Parallel mode is invoked with the `-p` option.
By default, `v-annotate.pl` will consult the file
`$VADRSCRIPTSDIR/vadr.qsubinfo` to read the command prefix and suffix
for submitting jobs to the cluster.  This file is set up to use Univa
Grid Engine (UGE 8.5.5) and specific flags used on the NCBI system,
but you can either modify this file to work with your own cluster or
create a new file `<s>` and use the option `-q <s>` to read that file.
The `$VADRSCRIPTSDIR/vadr.qsubinfo` has comments at the top that
explain the format of the file. Email eric.nawrocki@nih.gov for help.

To repeat the above `v-annotate.pl` run in parallel mode, use this command: 

```
v-annotate.pl -p $VADRSCRIPTSDIR/documentation/annotate-files/noro.9.fa va-parallel-noro.9
```

The output will look very similar to the run without `-p`, but with additional lines of 
output explaining that jobs have been submitted and are running on the compute farm:

```
# Submitting 1 cmscan classification job(s) to the farm                               ... 
# Waiting a maximum of 500 minutes for all farm jobs to finish                        ... 
#	   0 of    1 jobs finished (0.2 minutes spent waiting)
#	   0 of    1 jobs finished (0.5 minutes spent waiting)
#	   0 of    1 jobs finished (0.8 minutes spent waiting)
#	   0 of    1 jobs finished (1.0 minutes spent waiting)
#	   1 of    1 jobs finished (1.2 minutes spent waiting)
# done. [   75.7 seconds]
# Submitting 1 cmsearch coverage determination job(s) (NC_001959: 1 seqs) to the farm ... 
# Waiting a maximum of 500 minutes for all farm jobs to finish                        ... 
#	   1 of    1 jobs finished (0.2 minutes spent waiting)
# done. [   15.2 seconds]
```

Usage of `-p` will not affect the output of `v-annotate.pl` other than
these lines about the status of jobs, but it can make processing of
large sequence files significantly faster depending on how busy the
cluster is.

---
## `v-annotate.pl` command-line options<a name="options"></a>

To get a list of command-line options, execute:

`v-annotate.pl -h`

This will output the usage and available command-line options. 
Each option has a short description, but additional information on some
of these options can be found below.
For `v-annotate.pl` the available options are split into nine different categories, 
each explained in their own subsection below.

In the tables describing options below, `<s>` represents a string,
`<x>` indicates a floating point number and `<n>` represents an
integer. 

### `v-annotate.pl` basic options<a name="options-basic"></a>

| ......option.... | explanation | 
|------------------|-------------|
| `-f`             | if `<output directory>` already exists, then using this option will cause it to be overwritten, otherwise the progam exits in error |
| `-v`             | *verbose* mode: all commands will be output to standard output as they are run | 
| `--atgonly`      | only consider ATG as a valid start codon, regardless of model's translation table <a name="options-basic-atgonly"></a> |
| `--minpvlen <n>` | set the minimum length in nucleotides for CDS/mat_peptide/gene features to be output to feature tables and for protein validation analysis to `<n>`, default `<n>` is 30 |
| `--keep`         | keep [additional output files](formats.md#annotate-keep) that are normally removed |

### `v-annotate.pl` options for specifying expected sequence classification<a name="options-classification"></a>

| ..........option.......... | explanation | 
|--------|-------------| 
| `--group <s>`     | specify that the expected classification of all sequences is group `<s>`, sequences determined to *not* be in this group will trigger an *incgroup* alert |
| `--subgroup <s2>` | specify that the expected classification of all sequences is subgroup `<s>` within group `<s2>` from `--group <s2>`, sequences determined to *not* be in this group will trigger an *incsubgrp* alert; requires `--group` |

### `v-annotate.pl` options for controlling which alerts are *fatal* and cause a sequence to FAIL <a name="options-fatal"></a>

| ..........option.......... | explanation | 
|--------|-------------| 
| `--alt_list`     | output [summary of all alerts](#alerts) and then exit | 
| `--alt_pass <s>` | specify that alert codes in comma-separated string `<s>` are non-fatal (do not cause a sequence to fail), all alert codes listed must be fatal by default |
| `--alt_fail <s>` | specify that alert codes in comma-separated string `<s>` are fatal (cause a sequence to fail), all alert codes listed must be non-fatal by default |

### `v-annotate.pl` options related to model files<a name="options-modelfiles"></a>

| .......option....... | explanation | 
|--------|-------------| 
| `-m <s>` | use the CM file `<s>`, instead of the default CM file ($VADRMODELDIR/vadr.cm) |
| `-a <s>` | use HMM file `<s>` instead of the default HMM file ($VADRMODELDIR/vadr.hmm) |
| `-i <s>` | use the VADR model info file `<s>`, instead of the default model info file ($VADRMODELDIR/vadr.minfo) |
| `-n <s>` | use the blastn DB file `<s>` when necessary, instead of the default blastn DB file ($VADRMODELDIR/vadr.fa), only used if `-s` or `-r` is also used |
| `-x <s>` | specify that the blastx database files to use for protein validation are in dir `<s>`, instead of the default directory ($VADRMODELDIR) |
| `--mkey <s>` | specify that .cm, .minfo, and blastn .fa files in $VADRMODELDIR start with key `<s>`, not 'vadr' |
| `--mdir <s>` | specify that all model files to use are in the directory `<s>`, not in $VADRMODELDIR |
| `--mlist <s>` | specify that only the subset of models listed in the file `<s>` be used |

### `v-annotate.pl` options for controlling output feature table <a name="options-featuretable"></a>
| .......option....... | explanation | 
|--------|-------------| 
| `--nomisc`        | in feature table, never change feature to `misc_feature` | 
| `--notrim`        | <a name="options-alert-ambg"></a> in feature table, do not trim coordinate start and stops due to Ns at beginning or end of features for all feature types | 
| `--noftrtrim <s>` | in feature table, do not trim coordinate start and stops due to Ns at beginning or end of features for feature types listed in the comma-delimited string `<s>` (no spaces) | 
| `--noprotid`      | in feature table, don't add protein_id for CDS and mat_peptide features |
| `--forceprotid`   | in feature table, force protein_id value to be sequence name, then idx |

### `v-annotate.pl` options for controlling thresholds related to alerts <a name="options-alerts"></a>

In the table below, `<n>` represents a positive interger argument and
`<x>` represents a positive floating-point argument. 

| ...........option........... | relevant alert code(s) | relevant error(s) | default value that triggers alert | explanation |
|---------------------|---------------------|----------------|-----------------------------------|-------------|
| `--lowsc <x>`       | [*lowscore*](#lowscore1)                             | LOW_SCORE                              | < 0.3  | <a name="options-alerts-lowsc"></a> set bits per nt threshold for alert to `<x>` | 
| `--indefclass <x>`  | [*indfclas*](#indfclas1)                             | INDEFINITE_CLASSIFICATION              | < 0.03 | <a name="options-alerts-indefclas"></a> set bits per nt difference threshold for alert between top two models (not in same subgroup) to `<x>` |
| `--incspec <x>`     | [*incgroup*](#incgroup1), [*incsubgrp*](#incsubgrp1) | INCORRECT_SPECIFIED_GROUP, INCORRECT_SPECIFIED_SUBGROUP | < 0.2   | <a name="options-alerts-incspec"></a> set bits per nt difference threshold for alert between best-matching model `<m>` and highest-scoring model in specified group `<s1>` (from `--group <s1>`) or subgroup `<s2>` (from `--subgroup <s2>`), where `<m>` is not in group/subgroup `<s1>`/`<s2>` to `<x>` |
| `--lowcov <x>`      | [*lowcovrg*](#lowcovrg1)                             | LOW_COVERAGE                           | < 0.9  | <a name="options-alerts-lowcov"></a> set fractional coverage threshold for alert to `<x>` |
| `--dupregolp <n>`   | [*dupregin*](#dupregin1)                             | DUPLICATE_REGIONS                      | >= 20  | <a name="options-alerts-dupreg"></a>set min number of model position overlap for alert to  `<n>` positions | 
| `--dupregsc <x>`    | [*dupregin*](#dupregin1)                             | DUPLICATE_REGIONS                      | >= 10.0| <a name="options-alerts-dupreg"></a> set min bit score of weaker overlapping hit to  `<x>` bits | 
| `--indefstr <x>`    | [*indfstrn*](#indfstrn1)                             | INDEFINITE_STRAND                      | >= 25.0| <a name="options-alerts-indefstr"></a> set bit score of weaker strand hit for alert to `<x>` |
| `--lowsim5term <n>` | [*lowsim5s*](#lowsim5s1), [*lowsim5f*](#lowsim5f1)   | LOW_SIMILARITY_START, LOW_FEATURE_SIMILARITY_START | >= 15  | <a name="options-alerts-lowsim5term"></a> set length (nt) threshold for alert to `<n>` |
| `--lowsim3term <n>` | [*lowsim3s*](#lowsim3s1), [*lowsim3f*](#lowsim3f1)   | LOW_SIMILARITY_END, LOW_FEATURE_SIMILARITY_END     | >= 15  | <a name="options-alerts-lowsim3term"></a> set length (nt) threshold for alert to `<n>` |
| `--lowsimint <n>`   | [*lowsimis*](#lowsimis1), [*lowsimif*](#lowsimif1)   | LOW_SIMILARITY, LOW_FEATURE_SIMILARITY | >= 1   | <a name="options-alerts-lowsimint"></a> set length (nt) threshold for alert to `<n>` |
| `--biasfrac <x>`    | [*biasdseq*](#biasdseq1)                             | BIASED_SEQUENCE                        | >= 0.25| <a name="options-alerts-biasfrac"></a>  set fractional bit score threshold for biased score/total score for alert to `<x>` |
| `--indefann <x>`    | [*indf5loc*](#indf5loc1), [*indf3loc*](#indf3loc1)   | INDEFINITE_ANNOTATION_START, INDEFINITE_ANNOTATION_END | < 0.8 | <a name="options-alerts-indefann"></a> set posterior probability threshold for non-mat_peptide features for alert to `<x>` |
| `--indefann_mp <x>` | [*indf5loc*](#indf5loc1), [*indf3loc*](#indf3loc1)   | INDEFINITE_ANNOTATION_START, INDEFINITE_ANNOTATION_END | < 0.6 | <a name="options-alerts-indefann_mp"></a> set posterior probability threshold for mat_peptide features for alert to `<x>` |
| `--fstminnt <n>`    | [*fsthicnf*](#fsthicnf1), [*fstlocnf*](#fstlocnf1)   | POSSIBLE_FRAMESHIFT_HIGH_CONF, POSSIBLE_FRAMESHIFT_LO_CONF | >= 6 | <a name="options-alerts-fstminnt"></a> set maximum allowed length of aligned region in different frame to `<n>` |
| `--fsthighthr <x>`  | [*fsthicnf*](#fsthicnf1)                             | POSSIBLE_FRAMESHIFT_HIGH_CONF         | >= 0.8  | <a name="options-alerts-fsthighthr"></a> set average posterior probability threshold for potentially frameshifted region for high confidence alert to `<x>` |
| `--fstlowthr <x>`   | [*fstlocnf*](#fstlocnf1)                             | POSSIBLE_FRAMESHIFT_LOW_CONF          | >= 0.3  | <a name="options-alerts-fstlowthr"></a> set average posterior probability threshold for potentially frameshifted region for low confidence alert to `<x>` |
| `--xalntol <n>`     | [*indf5pst*](#indf5pst1), [*indf3pst*](#indf3pst1)   | INDEFINITE_ANNOTATION_START, INDEFINITE_ANNOTATION_END | > 5 | <a name="options-alerts-xalntol"></a> set maximum allowed difference in nucleotides between predicted blastx and CM start/end without alert to `<n>` (blastx coordinates must be internal to CM coordinates) |
| `--xmaxins <n>`     | [*insertnp*](#insertnp1)                             | INSERTION_OF_NT                       | > 27    | <a name="options-alerts-xmaxins"></a> set maximum allowed nucleotide insertion length in blastx validation alignment without alert to `<n>` |
| `--xmaxdel <n>`     | [*deletinp*](#deletinp1)                             | DELETION_OF_NT                        | > 27    | <a name="options-alerts-xmaxdel"></a> set maximum allowed nucleotide deletion length in blastx validation alignment without alert to `<n>` |
| `--nmaxins <n>`     | [*insertnn*](#insertnn1)                             | INSERTION_OF_NT                       | > 27    | <a name="options-alerts-nmaxins"></a> set maximum allowed nucleotide insertion length in CDS nt alignment without alert to `<n>`  |
| `--nmaxdel <n>`     | [*deletinn*](#deletinn1)                             | DELETION_OF_NT                        | > 27    | <a name="options-alerts-nmaxdel"></a> set maximum allowed nucleotide deletion length in CDS nt  alignment without alert to `<n>` |
| `--xlonescore <n>`  | [*indfantp*](#indfantp1)                             | INDEFINITE_ANNOTATION                 | >= 80   | <a name="options-alerts-xlonescore"></a> set minimum blastx *raw* score for a lone blastx hit not supported by CM analysis for alert to `<n>` | 
| `--hlonescore <n>`  | [*indfantp*](#indfantp1)                             | INDEFINITE_ANNOTATION                 | >= 10   | <a name="options-alerts-hlonescore"></a>  set minimum hmmer bit score for a lone hmmsearch hit not supported by CM analysis for alert to `<n>` | 

### `v-annotate.pl` options for controlling cmalign alignment stage <a name="options-align"></a>

Several options exist for controlling the command-line options that will be passed
to Infernal's `cmalign` program in the alignment stage. For more information on these options and how 
they control `cmalign`, see the Infernal 
User's Guide manual page for `cmalign` (section 8 of http://eddylab.org/infernal/Userguide.pdf)

| .........option......... | explanation |
|---------------------|--------------------|
| `--mxsize <n>`      | set maximum allowed cmalign DP matrix size to `<n>` Mb before triggering an unexpdivg alert, default `<n>` is `16000` | 
| `--tau <x>`         | set the initial tau (probability loss) value to `<x>` (sets the `cmalign --tau` option), default `<x>` is `0.001` | 
| `--nofixedtau`      | do not fix the tau value, allow it to increase if necessary (removes the `cmalign --fixedtau` option), default is to fix tau with `cmalign --fixedtau` |
| `--nosub`           | use alternative alignment strategy for truncated sequences (removes the `cmalign --sub --notrunc` options), default is use sub-CM alignment strategy with `cmalign --sub --notrunc` |
| `--noglocal`        | run in local mode instead of glocal mode (removes the `cmalign -g` option), default is to use glocal mode with `cmalign -g` |
---

### `v-annotate.pl` options for controlling blastx protein validation stage<a name="options-blastx"></a>

Below is a list of options for controlling the blastx protein
validaation stage. Several of these control command-line options that
will be passed to `blastx`. For more information on these options and
how they control `blastx`, see the NCBI BLAST documentation
(tables C1 and C4 of https://www.ncbi.nlm.nih.gov/books/NBK279684/).

| .........option......... | explanation |
|---------------------|--------------------|
| `--xmatrix <s>`     | use the substitution matrix `<s>` (sets the `blastx -matrix <s>` option), default is to use the default `blastx` matrix | 
| `--xdrop <n>`       | set the xdrop options to `<n>` (sets the `blastx` `-xdrop_ungap <n>`, `-xdrop_gap <n>` and `-xdrop_gap_final <n>` with the same `<n>`), default is to use default `blastx` values |
| `--xnumali <n>`     | specify that the top `<n>` alignments are output by `blastx`, mostly relevant in combination with `--xlongest` (sets the `blastx -num_alignments <n>` option), default `<n>` is 20 | 
| `--xlongest`        | use the longest `blastx` alignment of those returned (controlled by `--xnumali <n>`), default is to use the highest scoring alignment | 

### `v-annotate.pl` options for using hmmer instead of blastx for protein validation <a name="options-hmmer"></a>

Optionally, HMMER's hmmsearch program can be used instead of blastx for the protein validation stage.
**CAUTION:** This feature is relatively new and untested.
validaation stage. Several of these control command-line options that
will be passed to `blastx`. For more information on HMMER, see
the HMMER user's guide (http://eddylab.org/software/hmmer/Userguide.pdf).

| ......option......  | explanation |
|---------------------|--------------------|
| `--hmmer`           | use hmmer instead of blastx for protein validation |
| `--h_max`           | use the `--max` option with hmmsearch |
| `--h_minbit <x>`    | set the minimum hmmsearch bit score threshold to `<x>`, the default `<x>` is `-10`.

### <a name="options-seed"></a>`v-annotate.pl` options related to blastn-derived seeded alignment acceleration

The `-s` option turns on an acceleration heuristic based on a
first-pass blastn alignment of each input sequence.  With `-s`,
blastn is used instead of cmscan for sequence classification,
and the largest ungapped alignment region, called the 'seed', is
extracted from the top hit blastn hit, and fixed for the alignment
stage, such that only the sequence before and after the fixed seed is
aligned with cmalign. This option was originally developed for
SARS-CoV-2, for which it offers significant acceleration for many
sequences which are highly similar to the SARS-CoV-2 RefSeq model.

When `-s` option is used, an additional output file with suffix `.sda` is created,
with format described [here](formats.md#sda).

| .........option.........  | explanation |
|---------------------|--------------------|
| `-s`                | turn on the seed acceleration heuristic: use the max length ungapped region from blastn to seed the alignment |
| `--s_blastnws <n>`  | with `-s`, set the blastn `-word_size` parameter to `<n>`, the default value for `<n>` is `7` |
| `--s_blastnsc <x>`  | with `-s`, set the blastn minimum HSP score to consider to `<x>`, the default value for `<x>` is `50.0` |
| `--s_overhang <n>`  | with `-s`, set the length, in nt, of overlap between the 5' and 3' regions that are aligned with cmalign and the seed region to `<n>`, the default value for `<n>` is `100` |

### <a name="options-replace"></a> `v-annotate.pl` options related to replacing Ns with expected nucleotides

The `-r` option adds a pre-processing step to `v-annotate.pl` in which
stretches of Ns are identified in each sequence and replaced with the
expected nucleotides at the corresponding positions, when possible.
This can sidestep problems with annotation that the Ns would normally
cause.  However, this option should be used with caution because it is
based on the assumption that the missing regions match exactly to the
expected nucleotide sequence that correspond to those missing regions.

Regions of Ns are identified using blastn and examining regions
between hits for content of Ns. Ns in regions that satisfy the following three criteria
are then replaced with the expected nucleotide at each corresponding position:

* missing sequence region must be at least 5 nt
  (controllable with `--r_minlen` option)

* length of missing sequence region must equal length of
   missing model region

* missing sequence region must be `>= 0.50` fraction Ns
  (controllable with `--r_minfract` option)

When `-r` is used, an additional output file with suffix `.rpn` is created,
with format described [here](formats.md#rpn).

| ........option........  | explanation |
|---------------------|--------------------|
| `-r`                | turn on the replace-N strategy: replace stretches of Ns with expected nucleotides, where possible |
| `--r_minlen <n>`    | with `-r`, set minimum length subsequence to possibly replace Ns in to `<n>`, the default value for `<n>` is `5` |
| `--r_minfract <n>`  | with `-r`, set the minimum fraction of nucleotides in a subsequence to trigger N replacement to `<x>`, the default value for `<x>` is `0.5` |
| `--r_fetchr`        | with `-r`, fetch features to fasta files from sequences *with Ns replaced*, instead of original input sequences *without Ns replaced* |
| `--r_cdsmpr`        | with `-r`, identify CDS- and mat_peptide-specific alerts using subsequences fetched from sequences *with Ns replaced*, instead of original input sequences *without Ns replaced* |
| `--r_pvorig`        | with `-r`, use original input sequences *without Ns replaced* in protein validation stage, instead of sequences *with Ns replaced* |
| `--r_prof`          | with `-r`, use slower profile methods, not blastn, to identify Ns to replaced |

### `v-annotate.pl` options related to parallelization on a compute farm/cluster<a name="options-parallel"></a>

The `-p` option specifies that `v-annotate.pl` should be run in [parallel mode](#exampleparallel).
The following options are related to parallel mode.

| ........option........ | explanation |
|---------------------|--------------------|
| `-p`           | run in parallel mode so that classification, and each per-model coverage determination and alignment step is split into multiple jobs and run in parallel on a cluster | 
| `-q <s>`       | read cluster information file from file `<s>` instead of from the default file `$VADRSCRIPTSDIR/vadr.qsubinfo` |
| `--nkb <n>`    | set the target size for split-up sequence files to `<n>` Kb (thousand nucleotides), higher values will result in fewer parallel jobs and slower total run times, default `<n>` is `10` |
| `--wait <n>`   | set the total number of minutes to wait for all jobs to finish at each stage to `<n>`, if any job is not finished this many minutes after being *submitted* (as indicated by the existence of an expected output file) then `v-annotate.pl` will exit in error, default `<n>` is `500` | 
| `--errcheck`   | consider any output to STDERR from a parallel job as an indication the job has failed, this will cause `v-annotate.pl` to exit, default is to ignore output to STDERR | 
| `--maxnjobs <n>` | set the maximum number of jobs at *each stage* to `<n>`, default `<n>` is 2500 | 

### `v-annotate.pl` options for skipping stages<a name="options-skip"></a>

| ......option...... | explanation | 
|--------|-------------| 
| `--skip_align` | skip the `cmalign` stage, use results from previous run, this is mostly useful for debugging purposes | 
| `--skip_pv`    | do not perform protein validation stage for CDS |

### `v-annotate.pl` options for optional output files<a name="options-output"></a>

| .......option....... | explanation | 
|--------|-------------| 
| `--out_stk`     | create additional per-model output [stockholm](formats.md#stockholmformat) alignments with `.stk` suffix |
| `--out_afa`     | create additional per-model output aligned fasta alignments with `.afa` suffix |
| `--out_rpstk`   | with `-r`, create additional per-model output [stockholm](formats.md#stockholmformat) alignments with sequences *with Ns replaced* with `.rpstk` suffix |
| `--out_rpafa`   | create additional per-model output aligned fasta alignments with sequences *with Ns replaced* with `.rpafa` suffix |
| `--out_nofs`    | do not output frameshift [stockholm](formats.md#stockholmformat) alignment files with `.frameshift.stk` suffix |
| `--out_ftrinfo` | create additional output file with `.ftrinfo` suffix with per-model feature information, mainly useful for debugging |
| `--out_sgminfo` | create additional output file with `.sgminfo` suffix with per-model segment information, mainly useful for debugging |
| `--out_altinfo` | create additional output file with `.altinfo` suffix with alert information, mainly useful for debugging |

### Other `v-annotate.pl` expert options<a name="options-expert"></a>

| .........option......... | explanation | 
|--------|-------------| 
| `--execname <s>` | in banner and usage output, replace `v-annotate.pl` with `<s>` |
| `--alicheck`     | for debugging purposes, check aligned sequence versus input sequence for identity |
| `--noseqnamemax` | do not enforce the GenBank maximum length of 50 characters for sequence names |
| `--minbit <x>`   | set minimum cmsearch/cmscan bit score threshold to `<x>`, the default value for `<x>` is `-10` |
| `--origfa`       | do not copy the input fasta file into output directory prior to analysis, use the original |
| `--msub <s>`     | specify that file `<s>` lists models to substitute, each line should contain two space-delimited tokens, model listed in token 2 will substitute as best-matching model for all sequences classified as the model listed in token 1 |
| `--xsub <s>`     | specify that file `<s>` lists blastx dbs to substitute, each line should contain two space-delimited tokens, blastx db for model listed in token 2 will substitute as blastx db for all sequences classified as the model listed in token 1 |

## Information on `v-annotate.pl` alerts <a name="alerts"></a>

To see a table with information on alerts, use the `--alt_list` option, like this:

```
v-annotate.pl --alt_list 
```

The table below contains the same information as in the `--alt_list` output,
with sequences organized according to whether they are fatal or not. 
[*Always fatal*](#alertlist-always) alert codes are always fatal and cannot be changed using the 
`--alt_pass` options. All other alert codes can be changed from *fatal* to *non-fatal*
by using the `--alt_pass` option, or from *non-fatal* to *fatal* using the `--alt_fail` option.
An example is included [below](#alerttoggle).

In the table below, the **type** column reports if each alert pertains to an entire
`sequence` or a specific annotated `feature` within a sequence. The
**relevant feature types** column

#### Description of *always fatal* alert codes <a name="always1"></a>
| alert code | type | short description/error name | long description |
|------------|-------|------------------------------|------------------|
| [*noannotn*](#noannotn2)  | sequence | NO_ANNOTATION                   | <a name="noannotn1"></a> no significant similarity detected  |
| [*revcompl*](#revcompl2)  | sequence | REVCOMPLEM                      | <a name="revcompl1"></a> sequence appears to be reverse complemented  |
| [*unexdivg*](#unexdivg2)  | sequence | UNEXPECTED_DIVERGENCE           | <a name="unexdivg1"></a> sequence is too divergent to confidently assign nucleotide-based annotation  |
| [*noftrann*](#noftrann2)  | sequence | NO_FEATURES_ANNOTATED           | <a name="noftrann1"></a> sequence similarity to homology model does not overlap with any features |
| [*noftrant*](#noftrant2)  | sequence | NO_FEATURES_ANNOTATED           | <a name="noftrant1"></a> all annotated features are too short to be output to feature table |

#### Description of alerts that are *fatal* by default <a name="fatal1"></a>
| alert code | type | short description/error name | long description |
|------------|-------|------------------------------|------------------|
| [*incsbgrp*](#incsbgrp2)  | sequence | INCORRECT_SPECIFIED_SUBGROUP    | <a name="incsbgrp1"></a> score difference too large between best overall model and best specified subgroup model |
| [*incgroup*](#incgroup2)  | sequence | INCORRECT_SPECIFIED_GROUP       | <a name="incgroup1"></a> score difference too large between best overall model and best specified group model |
| [*lowcovrg*](#lowcovrg2)  | sequence | LOW_COVERAGE                    | <a name="lowcovrg1"></a> low sequence fraction with significant similarity to homology model |
| [*dupregin*](#dupregin2)  | sequence | DUPLICATE_REGIONS               | <a name="dupregin1"></a> similarity to a model region occurs more than once |
| [*discontn*](#discontn2)  | sequence | DISCONTINUOUS_SIMILARITY        | <a name="discontn1"></a> not all hits are in the same order in the sequence and the homology model |
| [*indfstrn*](#indfstrn2)  | sequence | INDEFINITE_STRAND               | <a name="indfstrn1"></a> significant similarity detected on both strands |
| [*lowsim5s*](#lowsim5s2)  | sequence | LOW_SIMILARITY_START            | <a name="lowsim5s1"></a> significant similarity not detected at 5' end of the sequence | 
| [*lowsim3s*](#lowsim3s2)  | sequence | LOW_SIMILARITY_END              | <a name="lowsim3s1"></a> significant similarity not detected at 3' end of the sequence | 
| [*lowsimis*](#lowsimis2)  | sequence | LOW_SIMILARITY                  | <a name="lowsimis1"></a> internal region without significant similarity | 
| [*deletins*](#deletins2)  | sequence | DELETION_OF_FEATURE             | <a name="deletins1"></a> internal deletion of a complete feature |
| [*mutstart*](#mutstart2)  | feature  | MUTATION_AT_START               | <a name="mutstart1"></a> expected start codon could not be identified | 
| [*mutendcd*](#mutendcd2)  | feature  | MUTATION_AT_END                 | <a name="mutendcd1"></a> expected stop codon could not be identified, predicted CDS stop by homology is invalid | 
| [*mutendns*](#mutendns2)  | feature  | MUTATION_AT_END                 | <a name="mutendns1"></a> expected stop codon could not be identified, no in-frame stop codon exists 3' of predicted valid start codon | 
| [*mutendex*](#mutendex2)  | feature  | MUTATION_AT_END                 | <a name="mutendex1"></a> expected stop codon could not be identified, first in-frame stop codon exists 3' of predicted stop position | <a name="mutendex1"></a> |
| [*unexleng*](#unexleng2)  | feature  | UNEXPECTED_LENGTH               | <a name="unexleng1"></a> length of complete coding (CDS or mat_peptide) feature is not a multiple of 3 | 
| [*cdsstopn*](#cdsstopn2)  | feature  | CDS_HAS_STOP_CODON              | <a name="cdsstopn1"></a> in-frame stop codon exists 5' of stop position predicted by homology to reference | 
| [*cdsstopp*](#cdsstopp2)  | feature  | CDS_HAS_STOP_CODON              | <a name="cdsstopp1"></a> stop codon in protein-based alignment |
| [*fsthicnf*](#fsthicnf2)  | feature  | POSSIBLE_FRAMESHIFT_HIGH_CONF   | <a name="fsthicnf1"></a> high confidence potential frameshift in CDS |
| [*peptrans*](#peptrans2)  | feature  | PEPTIDE_TRANSLATION_PROBLEM     | <a name="peptrans1"></a> mat_peptide may not be translated because its parent CDS has a problem |
| [*pepadjcy*](#pepadjcy2)  | feature  | PEPTIDE_ADJACENCY_PROBLEM       | <a name="pepadjcy1"></a> predictions of two mat_peptides expected to be adjacent are not adjacent |
| [*indfantp*](#indfantp2)  | feature  | INDEFINITE_ANNOTATION           | <a name="indfantp1"></a> protein-based search identifies CDS not identified in nucleotide-based search |
| [*indfantn*](#indfantn2)  | feature  | INDEFINITE_ANNOTATION           | <a name="indfantn1"></a> nucleotide-based search identifies CDS not identified in protein-based search | 
| [*indf5gap*](#indf5gap2)  | feature  | INDEFINITE_ANNOTATION_START     | <a name="indf5gap1"></a> alignment to homology model is a gap at 5' boundary |
| [*indf5loc*](#indf5loc2)  | feature  | INDEFINITE_ANNOTATION_START     | <a name="indf5loc1"></a> alignment to homology model has low confidence at 5' boundary |
| [*indf5plg*](#indf5plg2)  | feature  | INDEFINITE_ANNOTATION_START     | <a name="indf5plg1"></a> protein-based alignment extends past nucleotide-based alignment at 5' end | 
| [*indf5pst*](#indf5pst2)  | feature  | INDEFINITE_ANNOTATION_START     | <a name="indf5pst1"></a> protein-based alignment does not extend close enough to nucleotide-based alignment 5' endpoint | 
| [*indf3gap*](#indf3gap2)  | feature  | INDEFINITE_ANNOTATION_END       | <a name="indf3gap1"></a> alignment to homology model is a gap at 3' boundary | 
| [*indf3loc*](#indf3loc2)  | feature  | INDEFINITE_ANNOTATION_END       | <a name="indf3loc1"></a> alignment to homology model has low confidence at 3' boundary | 
| [*indf3plg*](#indf3plg2)  | feature  | INDEFINITE_ANNOTATION_END       | <a name="indf3plg1"></a> protein-based alignment extends past nucleotide-based alignment at 3' end | 
| [*indf3pst*](#indf3pst2)  | feature  | INDEFINITE_ANNOTATION_END       | <a name="indf3pst1"></a> protein-based alignment does not extend close enough to nucleotide-based alignment 3' endpoint | 
| [*indfstrp*](#indfstrp2)  | feature  | INDEFINITE_STRAND               | <a name="indfstrp1"></a> strand mismatch between protein-based and nucleotide-based predictions | 
| [*insertnp*](#insertnp2)  | feature  | INSERTION_OF_NT                 | <a name="insertnp1"></a> too large of an insertion in protein-based alignment | 
| [*insertnp*](#insertnn2)  | feature  | INSERTION_OF_NT                 | <a name="insertnn1"></a> too large of an insertion in nucleotide-based alignment of CDS feature |
| [*deletinp*](#deletinp2)  | feature  | DELETION_OF_NT                  | <a name="deletinp1"></a> too large of a deletion in protein-based alignment | 
| [*insertnp*](#deletinn2)  | feature  | DELETION_OF_NT                  | <a name="insertnn1"></a> too large of a deletion in nucleotide-based alignment of CDS feature |
| [*deletinf*](#deletinf2)  | feature  | DELETION_OF_FEATURE_SECTION     | <a name="deletinf1"></a> internal deletion of a complete section in a multi-section feature with other section(s) annotated |
| [*lowsim5f*](#lowsim5f2)  | feature  | LOW_FEATURE_SIMILARITY_START    | <a name="lowsim5f1"></a> region within annotated feature at 5' end of sequence lacks significant similarity |
| [*lowsim3f*](#lowsim3f2)  | feature  | LOW_FEATURE_SIMILARITY_END      | <a name="lowsim3f1"></a> region within annotated feature at 3' end of sequence lacks significant similarity | 
| [*lowsimif*](#lowsimif2)  | feature  | LOW_FEATURE_SIMILARITY          | <a name="lowsimif1"></a> region within annotated feature lacks significant similarity  |

#### Description of alerts that are *non-fatal* by default <a name="nonfatal1"></a>
| alert code | type | short description/error name | long description |
|------------|-------|------------------------------|------------------|
| [*qstsbgrp*](#qstsbgrp2)  | sequence | QUESTIONABLE_SPECIFIED_SUBGROUP | <a name="qstsbgrp1"></a> best overall model is not from specified subgroup  |
| [*qstgroup*](#qstgroup2)  | sequence | QUESTIONABLE_SPECIFIED_GROUP    | <a name="qstgroup1"></a> best overall model is not from specified group  |
| [*ambgnt5s*](#ambgnt5s2)  | sequence | N_AT_START                      | <a name="ambgnt5s1"></a> first nucleotide of the sequence is an N |
| [*ambgnt3s*](#ambgnt3s2)  | sequence | N_AT_END                        | <a name="ambgnt3s2"></a> final nucleotide of the sequence is an N |
| [*indfclas*](#indfclas2)  | sequence | INDEFINITE_CLASSIFICATION       | <a name="indfclas1"></a> low score difference between best overall model and second best model (not in best model's subgroup)  |
| [*lowscore*](#lowscore2)  | sequence | LOW_SCORE                       | <a name="lowscore1"></a> score to homology model below low threshold | [`--lowsc`](#options-alerts) | 
| [*biasdseq*](#biasdseq2)  | sequence | BIASED_SEQUENCE                 | <a name="biasdseq1"></a> high fraction of score attributed to biased sequence composition  |
| [*unjoinbl*](#unjoinbl2)  | sequence | UNJOINABLE_SUBSEQ_ALIGNMENTS    | <a name="unjoinbl1"></a> inconsistent alignment of overlapping region between ungapped seed and flanking region |
| [*fstlocnf*](#fstlocnf2)  | feature  | POSSIBLE_FRAMESHIFT_LOW_CONF    | <a name="fstlocnf1"></a> low confidence potential frameshift in CDS |
| [*insertnn*](#insertnn2)  | feature  | INSERTION_OF_NT                 | <a name="insertnn1"></a> too large of an insertion in nucleotide-based alignment of CDS feature | 
| [*deletinn*](#deletinn2)  | feature  | DELETION_OF_NT                  | <a name="deletinn1"></a> too large of a deletion in nucleotide-based alignment of CDS feature | 
| [*ambgnt5f*](#ambgnt5f2)  | feature  | N_AT_FEATURE_START              | <a name="ambgnt5f1"></a> first nucleotide of non-CDS feature is an N |
| [*ambgnt3f*](#ambgnt3f2)  | feature  | N_AT_FEATURE_END                | <a name="ambgnt3f1"></a> final nucleotide of non-CDS feature is an N |
| [*ambgnt5c*](#ambgnt5c2)  | feature  | N_AT_CDS_START                  | <a name="ambgnt5c1"></a> first nucleotide of CDS is an N | 
| [*ambgnt3c*](#ambgnt3c2)  | feature  | N_AT_CDS_END                    | <a name="ambgnt3c1"></a> final nucleotide of CDS is an N | 

### Additional information on `v-annotate.pl` alerts <a name="alerts2"></a> 

The table below has additional information on the alerts 
not contained in the `--alt_list` output.
The "relevant_options" column lists command-line options that 
pertain to each alert. The [**relevant feature types** column
shows which feature types each alert can be reported for (this field is "-" for 
alerts that pertain to a sequence instead of a feature).  The
**omitted in `.tbl` and `.alt.list` by** column lists other alerts
that, if present, will cause this alert to be omitted in the `.tbl`
and `.alt.list` files to reduce redundant information reported to
user, this is "-" for alerts that are never omitted from those files.

#### More information on *always fatal* alert codes <a name="always2"></a>
| alert code | short description/error name | relevant options | relevant feature types | omitted in `.tbl` and `.alt.list` by | 
|------------|------------------------------|------------------|------------------------|--------------------------------------|
| [*noannotn*](#noannotn1)  | NO_ANNOTATION                | none | - | - <a name="noannotn2"></a> | 
| [*revcompl*](#revcompl1)  | REVCOMPLEM                   | none | - | - <a name="revcompl2"></a> |  
| [*unexdivg*](#unexdivg1)  | UNEXPECTED_DIVERGENCE        | none | - | - <a name="unexdivg2"></a> |  
| [*noftrann*](#noftrann1)  | NO_FEATURES_ANNOTATED        | none | - | - <a name="noftrann2"></a> | 
| [*noftrant*](#noftrant1)  | NO_FEATURES_ANNOTATED        | none | - | - <a name="noftrant2"></a> | 

#### More information on alerts that are *fatal* by default <a name="fatal2"></a>
| alert code | short description/error name | relevant_options | relevant feature types | omitted in `.tbl` and `.alt.list` by | 
|------------|------------------------------|------------------|------------------------|--------------------------------------|
| [*incsbgrp*](#incsbgrp1)  | INCORRECT_SPECIFIED_SUBGROUP    | [`--incspec`](#options-alerts-incspec) | - | - <a name="incsbgrp2"></a> | 
| [*incgroup*](#incgroup1)  | INCORRECT_SPECIFIED_GROUP       | [`--incspec`](#options-alerts-incspec) | - | - <a name="incgroup2"></a> |
| [*lowcovrg*](#lowcovrg1)  | LOW_COVERAGE                    | [`--lowcov`](#options-alerts-lowcov) | - | - <a name="lowcovrg2"></a> | 
| [*dupregin*](#dupregin1)  | DUPLICATE_REGIONS               | [`--dupreg`](#options-alerts-dupreg) | - | - <a name="dupregin2"></a> | 
| [*discontn*](#discontn1)  | DISCONTINUOUS_SIMILARITY        | none | - | - <a name="discontn2"></a> | 
| [*indfstrn*](#indfstrn1)  | INDEFINITE_STRAND               | [`--indefstr`](#options-alerts-indefstr) | - | - <a name="indfstrn2"></a> | 
| [*lowsim5s*](#lowsim5s1)  | LOW_SIMILARITY_START            | [`--lowsim5term`](#options-alerts-lowsim5term) | - | - <a name="lowsim5s2"></a> | 
| [*lowsim3s*](#lowsim3s1)  | LOW_SIMILARITY_END              | [`--lowsim3term`](#options-alerts-lowsim3term) | - | - <a name="lowsim3s2"></a> | 
| [*lowsimis*](#lowsimis1)  | LOW_SIMILARITY                  | [`--lowsimint`](#options-alerts-lowsimint) | - | - <a name="lowsimis2"></a> |
| [*deletinf*](#deletins1)  | DELETION_OF_FEATURE             | none | all | - <a name="deletins2"></a> | 
| [*mutstart*](#mutstart1)  | MUTATION_AT_START               | [`--atgonly`](#options-basic-atgonly) | CDS | - <a name="mutstart2"></a> | 
| [*mutendcd*](#mutendcd1)  | MUTATION_AT_END                 | none | CDS | *cdsstopn*, *mutendex*, *mutendns* <a name="mutendcd2"></a> | 
| [*mutendns*](#mutendns1)  | MUTATION_AT_END                 | none | CDS | - <a name="mutendns2"></a> | 
| [*mutendex*](#mutendex1)  | MUTATION_AT_END                 | none | CDS | - <a name="mutendex2"></a> | 
| [*unexleng*](#unexleng1)  | UNEXPECTED_LENGTH               | none | CDS, mat_peptide | - <a name="unexleng2"></a> | 
| [*cdsstopn*](#cdsstopn1)  | CDS_HAS_STOP_CODON              | none | CDS | - <a name="2"></a> <a name="cdsstopn2"></a> | 
| [*cdsstopp*](#cdsstopp1)  | CDS_HAS_STOP_CODON              | none | CDS | - <a name="cdsstopp2"></a> | 
| [*fsthicnf*](#fsthicnf1)  | POSSIBLE_FRAMESHIFT_HIGH_CONF   | [`--fsthighthr`, `--fstminnt`](#options-alerts-fstminnt) | CDS | - <a name="fsthicnf2"></a> |
| [*peptrans*](#peptrans1)  | PEPTIDE_TRANSLATION_PROBLEM     | none | mat_peptide | - <a name="peptrans2"></a> | 
| [*pepadjcy*](#pepadjcy1)  | PEPTIDE_ADJACENCY_PROBLEM       | none | mat_peptide | - <a name="pepadcy2"></a> | 
| [*indfantp*](#indfantp1)  | INDEFINITE_ANNOTATION           | [`--xlonescore`](#options-alerts-xlonescore) | CDS | - <a name="indfantp2"></a> | 
| [*indfantn*](#indfantn1)  | INDEFINITE_ANNOTATION           | none | CDS | - <a name="indfantn2"></a> | 
| [*indf5gap*](#indf5gap1)  | INDEFINITE_ANNOTATION_START     | none | all | - <a name="indf5gap2"></a> | 
| [*indf5loc*](#indf5loc1)  | INDEFINITE_ANNOTATION_START     | [`--indefann`, `--indefann_mp`](#options-alerts-indefann) | all | - <a name="indf5loc2"></a> | 
| [*indf5plg*](#indf5plg1)  | INDEFINITE_ANNOTATION_START     | none | CDS | - <a name="indf5plg2"></a> | 
| [*indf5pst*](#indf5pst1)  | INDEFINITE_ANNOTATION_START     | [`--xalntol`](#options-alerts-xalntol) | CDS | - <a name="indf5pst2"></a> | 
| [*indf3gap*](#indf3gap1)  | INDEFINITE_ANNOTATION_END       | none | all | - <a name="indf3gap2"></a> |  
| [*indf3loc*](#indf3loc1)  | INDEFINITE_ANNOTATION_END       | [`--indefann`, `--indefann_mp`](#options-alerts-indefann) | all | - <a name="indf3loc2"></a> | 
| [*indf3plg*](#indf3plg1)  | INDEFINITE_ANNOTATION_END       | none | CDS | - <a name="indf3plg2"></a> | 
| [*indf3pst*](#indf3pst1)  | INDEFINITE_ANNOTATION_END       | [`--xalntol`](#options-alerts-xalntol) | CDS | - <a name="indf3pst2"></a> | 
| [*indfstrp*](#indfstrp1)  | INDEFINITE_STRAND               | none | CDS | - <a name="indfstrp2"></a> | 
| [*insertnp*](#insertnp1)  | INSERTION_OF_NT                 | [`--xmaxins`](#options-alerts-xmaxins) | CDS | - <a name="insertnp2"></a> | 
| [*insertnn*](#insertnn1)  | INSERTION_OF_NT                 | [`--nmaxins`](#options-alerts-nmaxins) | CDS | - <a name="insertnn2"></a> | 
| [*deletinp*](#deletinp1)  | DELETION_OF_NT                  | [`--xmaxdel`](#options-alerts-xmaxdel) | CDS | - <a name="deletinp2"></a> | 
| [*deletinn*](#deletinn1)  | DELETION_OF_NT                  | [`--nmaxdel`](#options-alerts-nmaxdel) | CDS | - <a name="deletinn2"></a> | 
| [*deletinf*](#deletinf1)  | DELETION_OF_FEATURE_SECTION     | none | all | - <a name="deletinf2"></a> | 
| [*lowsim5f*](#lowsim5f1)  | LOW_FEATURE_SIMILARITY_START    | [`--lowsim5term`](#options-alerts-lowsim5term) | all except CDS, mat_peptide and any feature with identical coordinates to a CDS or mat_peptide | - <a name="lowsim5f2"></a> | 
| [*lowsim3f*](#lowsim3f1)  | LOW_FEATURE_SIMILARITY_END      | [`--lowsim3term`](#options-alerts-lowsim3term) | all except CDS, mat_peptide and any feature with identical coordinates to a CDS or mat_peptide | - <a name="lowsim3f2"></a> | 
| [*lowsimif*](#lowsimif1)  | LOW_FEATURE_SIMILARITY          | [`--lowsimterm`](#options-alerts-lowsimterm)   | all except CDS, mat_peptide and any feature with identical coordinates to a CDS or mat_peptide | - <a name="lowsimif2"></a> | 

#### More information on alerts that are *non-fatal* by default <a name="nonfatal2"></a>
| alert code | short description/error name | relevant_options | relevant feature types | omitted in `.tbl` and `.alt.list` by | 
|------------|------------------------------|------------------|------------------------|--------------------------------------|
| [*qstsbgrp*](#qstsbgrp1)  | QUESTIONABLE_SPECIFIED_SUBGROUP | none | - | - <a name="qstsbgrp2"></a> | 
| [*qstgroup*](#qstgroup1)  | QUESTIONABLE_SPECIFIED_GROUP    | none | - | - <a name="qstgroup2"></a> | 
| [*ambgnt5s*](#ambgnt5s1)  | N_AT_START                      | none | - | - <a name="ambgnt5s2"></a> | 
| [*ambgnt3s*](#ambgnt3s1)  | N_AT_END                        | none | - | - <a name="ambgnt3s2"></a> | 
| [*indfclas*](#indfclas1)  | INDEFINITE_CLASSIFICATION       | [`--indefclas`](#options-alerts-indefclas) | - | - <a name="indfclas2"></a> | 
| [*lowscore*](#lowscore1)  | LOW_SCORE                       | [`--lowsc`](#options-alerts-lowscore) | - | - <a name="lowscore2"></a> | 
| [*biasdseq*](#biasdseq1)  | BIASED_SEQUENCE                 | [`--biasfrac`](#options-alerts-biasfrac) | - | - <a name="biasdseq2"></a> | 
| [*unjoinbl*](#unjoinbl1)  | UNJOINABLE_SUBSEQ_ALIGNMENTS    | none | - | <a name="unjoinbl12"></a> |
| [*fstlocnf*](#fstlocnf1)  | POSSIBLE_FRAMESHIFT_LOW_CONF    | [`--fstlothr`, `--fstminnt`](#options-alerts-fstminnt) | CDS | - <a name="fstlocnf2"></a> |
| [*insertnn*](#insertnn1)  | INSERTION_OF_NT                 | [`--nmaxins`](#options-alerts-nmaxins) | CDS | - <a name="insertnn2"></a> |
| [*deletinn*](#deletinn1)  | DELETION_OF_NT                  | [`--nmaxdel`](#options-alerts-nmaxdel) | CDS | - <a name="deletinn2"></a> |
| [*ambgnt5f*](#ambgnt5s1)  | N_AT_FEATURE_START              | none | - | - <a name="ambgnt5s2"></a> | 
| [*ambgnt3f*](#ambgnt3s1)  | N_AT_FEATURE_END                | none | - | - <a name="ambgnt3s2"></a> | 
| [*ambgnt5c*](#ambgnt5c1)  | N_AT_CDS_START                  | none | CDS | - <a name="ambgnt5c2"></a> | 
| [*ambgnt3c*](#ambgnt3c1)  | N_AT_CDS_END                    | none | CDS | - <a name="ambgnt3c2"></a> | 

---
#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.


