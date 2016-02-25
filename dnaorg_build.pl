#!/usr/bin/env perl
# EPN, Mon Aug 10 10:39:33 2015 [development began on dnaorg_annotate_genomes.pl]
# EPN, Mon Feb  1 15:07:43 2016 [dnaorg_build.pl split off from dnaorg_annotate_genomes.pl]
#
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);
use Bio::Easel::MSA;
use Bio::Easel::SqFile;

require "dnaorg.pm"; 
require "epn-options.pm";

#######################################################################################
# What this script does: 
#
# Preliminaries: 
#   - process options
#   - create the output directory
#   - output program banner and open output files
#   - parse the optional input files, if necessary
#   - make sure the required executables are executable
#
# Step 1. Gather and process information on reference genome using Edirect
#
# Step 2. Fetch and process the reference genome sequence
#
# Step 3. Build and calibrate models
#######################################################################################

# hard-coded-paths:
my $inf_exec_dir   = "/usr/local/infernal/1.1.1/bin/";
my $esl_exec_dir   = "/usr/local/infernal/1.1.1/bin/";
my $esl_fetch_cds  = "/panfs/pan1/dnaorg/programs/esl-fetch-cds.pl";

#########################################################
# Command line and option processing using epn-options.pm
#
# opt_HH: 2D hash:
#         1D key: option name (e.g. "-h")
#         2D key: string denoting type of information 
#                 (one of "type", "default", "group", "requires", "incompatible", "preamble", "help")
#         value:  string explaining 2D key:
#                 "type":          "boolean", "string", "int" or "real"
#                 "default":       default value for option
#                 "group":         integer denoting group number this option belongs to
#                 "requires":      string of 0 or more other options this option requires to work, each separated by a ','
#                 "incompatiable": string of 0 or more other options this option is incompatible with, each separated by a ','
#                 "preamble":      string describing option for preamble section (beginning of output from script)
#                 "help":          string describing option for help section (printed if -h used)
#                 "setby":         '1' if option set by user, else 'undef'
#                 "value":         value for option, can be undef if default is undef
#
# opt_order_A: array of options in the order they should be processed
# 
# opt_group_desc_H: key: group number (integer), value: description of group for help output
my %opt_HH = ();      
my @opt_order_A = (); 
my %opt_group_desc_H = ();

# Add all options to %opt_HH and @opt_order_A.
# This section needs to be kept in sync (manually) with the &GetOptions call below
$opt_group_desc_H{"1"} = "basic options";
#     option            type       default               group   requires incompat    preamble-output                          help-output    
opt_Add("-h",           "boolean", 0,                        0,    undef, undef,      undef,                                   "display this help",                                  \%opt_HH, \@opt_order_A);
opt_Add("-c",           "boolean", 0,                        1,    undef, undef,      "genome is circular",                    "genome is circular",                                 \%opt_HH, \@opt_order_A);
opt_Add("-d",           "string",  undef,                    1,    undef, undef,      "directory specified as",                "specify output directory is <s1> (created with dnaorg_build.pl -d <s>), not <ref accession>", \%opt_HH, \@opt_order_A);
opt_Add("-f",           "boolean", 0,                        1,    undef, undef,      "forcing directory overwrite",           "force; if dir <reference accession> exists, overwrite it", \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                            "be verbose; output commands to stdout as they're run", \%opt_HH, \@opt_order_A);
opt_Add("--matpept",    "string",  undef,                    1,    undef, undef,      "using pre-specified mat_peptide info",  "read mat_peptide info in addition to CDS info, file <s> explains CDS:mat_peptide relationships", \%opt_HH, \@opt_order_A);
opt_Add("--nomatpept",  "boolean", 0,                        1,    undef,"--matpept", "ignore mat_peptide annotation",         "ignore mat_peptide information in reference annotation", \%opt_HH, \@opt_order_A);
opt_Add("--dirty",      "boolean", 0,                        1,    undef, undef,      "leaving intermediate files on disk",    "do not remove intermediate files, leave them all on disk", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"2"} = "options affecting window/hit definition";
#       option       type       default                group  requires incompat  preamble-output                          help-output    
opt_Add("--cslow",   "boolean", 0,                     2,    undef, undef,   "running cmcalibrate in slow mode",               "use default cmcalibrate parameters, not parameters optimized for speed", \%opt_HH, \@opt_order_A);
opt_Add("--clocal",  "boolean", 0,                     2,    undef, undef,   "running cmcalibrate on local machine",           "run cmcalibrate locally, do not submit calibration jobs for each CM to the compute farm", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: dnaorg_build.pl [-options] <reference accession>\n";
my $synopsis = "dnaorg_build.pl :: build homology models for features of a reference sequence";

my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"}, 
# basic options
                'c'            => \$GetOptions_H{"-c"},
                'd=s'          => \$GetOptions_H{"-d"},
                'f'            => \$GetOptions_H{"-f"},
                'v'            => \$GetOptions_H{"-v"},
                'matpept=s'    => \$GetOptions_H{"--matpept"},
                'nomatpept'    => \$GetOptions_H{"--nomatpept"},
                'dirty'        => \$GetOptions_H{"--dirty"},
# calibration related options
                'cslow'        => \$GetOptions_H{"--cslow"},
                'clocal'       => \$GetOptions_H{"--clocal"});

my $total_seconds = -1 * secondsSinceEpoch(); # by multiplying by -1, we can just add another secondsSinceEpoch call at end to get total time
my $executable    = $0;
my $date          = scalar localtime();
my $version       = "0.1";
my $releasedate   = "Feb 2016";

# print help and exit if necessary
if((! $options_okay) || ($GetOptions_H{"-h"})) { 
  outputBanner(*STDOUT, $version, $releasedate, $synopsis, $date);
  opt_OutputHelp(*STDOUT, $usage, \%opt_HH, \@opt_order_A, \%opt_group_desc_H);
  if(! $options_okay) { die "ERROR, unrecognized option;"; }
  else                { exit 0; } # -h, exit with 0 status
}

# check that number of command line args is correct
if(scalar(@ARGV) != 1) {   
  print "Incorrect number of command line arguments.\n";
  print $usage;
  print "\nTo see more help on available options, do dnaorg_build.pl -h\n\n";
  exit(1);
}
my ($ref_accn) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

my $dir        = opt_Get("-d", \%opt_HH);          # this will be undefined unless -d set on cmdline
my $do_matpept = opt_IsOn("--matpept", \%opt_HH);

#############################
# create the output directory
#############################
my $cmd;              # a command to run with runCommand()
my @early_cmd_A = (); # array of commands we run before our log file is opened
# check if the $dir exists, and that it contains the files we need
# check if our output dir $symbol exists
if(! defined $dir) { 
  $dir = $ref_accn;
}
else { 
  if($dir !~ m/\/$/) { $dir =~ s/\/$//; } # remove final '/' if it exists
}
if(-d $dir) { 
  $cmd = "rm -rf $dir";
  if(opt_Get("-f", \%opt_HH)) { runCommand($cmd, opt_Get("-v", \%opt_HH), undef); push(@early_cmd_A, $cmd); }
  else                        { die "ERROR directory named $dir already exists. Remove it, or use -f to overwrite it."; }
}
if(-e $dir) { 
  $cmd = "rm $dir";
  if(opt_Get("-f", \%opt_HH)) { runCommand($cmd, opt_Get("-v", \%opt_HH), undef); push(@early_cmd_A, $cmd); }
  else                        { die "ERROR a file named $dir already exists. Remove it, or use -f to overwrite it."; }
}

# create the dir
$cmd = "mkdir $dir";
runCommand($cmd, opt_Get("-v", \%opt_HH), undef);
push(@early_cmd_A, $cmd);

my $dir_tail = $dir;
$dir_tail =~ s/^.+\///; # remove all but last dir
my $out_root = $dir . "/" . $dir_tail . ".dnaorg_build";

#############################################
# output program banner and open output files
#############################################
# output preamble
my @arg_desc_A = ("reference accession");
my @arg_A      = ($ref_accn);
outputBanner(*STDOUT, $version, $releasedate, $synopsis, $date);
opt_OutputPreamble(*STDOUT, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

# open the log and command files:
# set output file names and file handles, and open those file handles
my %ofile_name_H          = (); # full name for (full path to) output files
my %ofile_sname_H         = (); # short name for (no dir path) output files
my %ofile_FH_H            = (); # file handle for output files, keys are in @ofile_keys_A
my @ofile_keys_A          = ("log", "cmd"); 
my %ofile_desc_H          = (); # description of each output file
$ofile_desc_H{"log"}      = "Output printed to screen";
$ofile_desc_H{"cmd"}      = "List of executed commands";

foreach my $key (@ofile_keys_A) { 
  $ofile_name_H{$key}  = $out_root . "." . $key;
  $ofile_sname_H{$key} = $dir_tail . ".dnaorg_build." . $key; # short name (lacks directory)
  if(! open($ofile_FH_H{$key}, ">", $ofile_name_H{$key})) { 
    printf STDERR ("ERROR, unable to open $ofile_name_H{$key} for writing.\n"); 
    exit(1);
  }
}

my $log_FH = $ofile_FH_H{"log"};
my $cmd_FH = $ofile_FH_H{"cmd"};
# output files are all open, if we exit after this point, we'll need
# to close these first.

# now we have the log file open, output the banner there too
outputBanner($log_FH, $version, $releasedate, $synopsis, $date);
opt_OutputPreamble($log_FH, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

# output any commands we already executed to $log_FH
foreach $cmd (@early_cmd_A) { 
  print $cmd_FH $cmd . "\n";
}

########################################
# parse the optional input files, if nec
########################################
# -matpept <f>
my @cds2pmatpept_AA = (); # 1st dim: cds index (-1, off-by-one), 2nd dim: value array of primary matpept indices that comprise this CDS
my @cds2amatpept_AA = (); # 1st dim: cds index (-1, off-by-one), 2nd dim: value array of all     matpept indices that comprise this CDS
if($do_matpept) { 
  parseMatPeptSpecFile(opt_Get("--matpept", \%opt_HH), \@cds2pmatpept_AA, \@cds2amatpept_AA, \%ofile_FH_H);
}

###################################################
# make sure the required executables are executable
###################################################
my %execs_H = (); # hash with paths to all required executables
$execs_H{"cmbuild"}       = $inf_exec_dir . "cmbuild";
$execs_H{"cmcalibrate"}   = $inf_exec_dir . "cmcalibrate";
$execs_H{"cmfetch"}       = $inf_exec_dir . "cmfetch";
$execs_H{"cmpress"}       = $inf_exec_dir . "cmpress";
$execs_H{"esl-reformat"}  = $esl_exec_dir . "esl-reformat";
$execs_H{"esl_fetch_cds"} = $esl_fetch_cds;
validateExecutableHash(\%execs_H, \%ofile_FH_H);

###########################################################################
# Step 1. Gather and process information on reference genome using Edirect.
###########################################################################
my $progress_w = 60; # the width of the left hand column in our progress output, hard-coded
my $start_secs = outputProgressPrior("Gathering information on reference using edirect", $progress_w, $log_FH, *STDOUT);

my %cds_tbl_HHA = ();   # CDS data from .cds.tbl file, hash of hashes of arrays, 
                        # 1D: key: accession
                        # 2D: key: column name in gene ftable file
                        # 3D: per-row values for each column
my %mp_tbl_HHA = ();    # mat_peptide data from .matpept.tbl file, hash of hashes of arrays, 
                        # 1D: key: accession
                        # 2D: key: column name in gene ftable file
                        # 3D: per-row values for each column
my %totlen_H   = ();    # key: accession, value: total length of the sequence for that accession


# Call the wrapper function that does the following:
#  1) creates the edirect .mat_peptide file, if necessary
#  2) creates the edirect .ftable file
#  3) creates the length file
#  4) parses the edirect .mat_peptide file, if necessary
#  5) parses the edirect .ftable file
#  6) parses the length file
wrapperGetInfoUsingEdirect(undef, $ref_accn, $out_root, \%cds_tbl_HHA, \%mp_tbl_HHA, \%totlen_H, \@ofile_keys_A, \%ofile_name_H, \%ofile_sname_H,
                           \%ofile_desc_H, \%opt_HH, \%ofile_FH_H); # 1st argument is undef because we are only getting info for $ref_accn

if($do_matpept) {  
  # validate the CDS:mat_peptide relationships that we read from the $matpept input file
  matpeptValidateCdsRelationships(\@cds2pmatpept_AA, \%{$cds_tbl_HHA{$ref_accn}}, \%{$mp_tbl_HHA{$ref_accn}}, opt_Get("-c", \%opt_HH), $totlen_H{$ref_accn}, \%ofile_FH_H);
}
outputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

#########################################################
# Step 2. Fetch and process the reference genome sequence
##########################################################
$start_secs = outputProgressPrior("Fetching and processing the reference genome", $progress_w, $log_FH, *STDOUT);
my $fetch_file = $out_root . ".ref.fg.idfetch.in";
my $fasta_file = $out_root . ".ref.fg.fa";
my @accn_A     = ($ref_accn); # array of accessions 
my @seq_accn_A = ();      # array of actual sequence names in $fasta_file that we'll create, filled in fetchSequencesUsingEslFetchCds

# fetch the reference genome
fetchSequencesUsingEslFetchCds($execs_H{"esl_fetch_cds"}, 0, $fetch_file, $fasta_file, opt_Get("-c", \%opt_HH), \@accn_A, \%totlen_H, \@seq_accn_A, undef, undef, \%ofile_FH_H);
addClosedOutputFile(\@ofile_keys_A, \%ofile_name_H, \%ofile_sname_H, \%ofile_desc_H, "fetch", $fetch_file, "Input file for esl-fetch-cds.pl", \%ofile_FH_H);
addClosedOutputFile(\@ofile_keys_A, \%ofile_name_H, \%ofile_sname_H, \%ofile_desc_H, "fasta", $fasta_file, "Sequence file with reference genome", \%ofile_FH_H);

my %ftr_info_HA = (); # hash of arrays, values are arrays [0..$nftr-1], 
                      # see dnaorg.pm::validateFeatureInfoHashIsComplete() for list of all keys
my $nftr;             # number of features
my $nmp;              # number of mature peptide features

# determine reference information for each feature (strand, length, coordinates, product)
getReferenceFeatureInfo(\%cds_tbl_HHA, ($do_matpept ? \%mp_tbl_HHA : undef), \%ftr_info_HA, $ref_accn, \%ofile_FH_H);
my @reqd_keys_A = ("ref_strand", "ref_len", "ref_coords", "out_product");
$nftr = validateAndGetSizeOfInfoHashOfArrays(\%ftr_info_HA, undef, \%ofile_FH_H);
$nmp  = ($do_matpept) ? scalar(@{$mp_tbl_HHA{$ref_accn}{"coords"}}) : 0;

# determine type of each feature 
determineFeatureTypes($nmp, ((@cds2pmatpept_AA) ? \@cds2pmatpept_AA : undef), \%ftr_info_HA, \%ofile_FH_H);

# fetch the reference feature sequences and populate information on the models and features
my $all_stk_file = $out_root . ".ref.all.stk";
my %mdl_info_HA = (); # hash of arrays, hash keys: "ftr_idx",  "is_first",  "is_final",  values are arrays [0..$nmdl-1];
my $sqfile = Bio::Easel::SqFile->new({ fileLocation => $fasta_file });
addClosedOutputFile(\@ofile_keys_A, \%ofile_name_H, \%ofile_sname_H, \%ofile_desc_H, "index", $fasta_file.".ssi", "Index for reference genome sequence file", \%ofile_FH_H);

my $ref_totlen = $totlen_H{$ref_accn}; # wrapperGetInfoUsingEdirect() verified that $totlen_H{$ref_accn} exists
fetchReferenceFeatureSequences(\%execs_H, $sqfile, $seq_accn_A[0], $ref_totlen, $out_root, \%mdl_info_HA, \%ftr_info_HA, $all_stk_file, \%opt_HH, \%ofile_FH_H); # 0 is 'do_circular' which is irrelevant in this context
addClosedOutputFile(\@ofile_keys_A, \%ofile_name_H, \%ofile_sname_H, \%ofile_desc_H, "refstk", $all_stk_file, "Stockholm alignment file with reference features", \%ofile_FH_H);

outputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

# verify our model and feature info hashes are complete, 
# if validateFeatureInfoHashIsComplete() fails
# the program will exit with an error message
my $nmdl; # the number of homology models (CMs)
validateFeatureInfoHashIsComplete(\%ftr_info_HA, undef, \%ofile_FH_H);
$nmdl = validateModelInfoHashIsComplete(\%mdl_info_HA, undef, \%ofile_FH_H);


####################################
# Step 3. Build and calibrate models 
####################################
my $do_clocal = opt_Get("--clocal", \%opt_HH); # are we running calibration locally
my $build_str = $do_clocal ? "Building and calibrating models" : "Building models and submitting calibration jobs to the farm";
$start_secs = outputProgressPrior($build_str, $progress_w, $log_FH, *STDOUT);
createCmDb(\%execs_H, $all_stk_file, $out_root . ".ref", \@{$mdl_info_HA{"cmname"}}, \%opt_HH, \%ofile_FH_H);
if(! $do_clocal) { 
  for(my $i = 0; $i < $nmdl; $i++) { 
    addClosedOutputFile(\@ofile_keys_A, \%ofile_name_H, \%ofile_sname_H, \%ofile_desc_H, "cm$i", "$out_root.$i.cm", 
                        sprintf("CM file #%d, %s (currently calibrating on the farm)", $i+1, $mdl_info_HA{"out_tiny"}[$i]), \%ofile_FH_H);
  }
}
else { 
  addClosedOutputFile(\@ofile_keys_A, \%ofile_name_H, \%ofile_sname_H, \%ofile_desc_H, "cm", "$out_root.cm", 
                      "CM file with all $nmdl models", \%ofile_FH_H);
}

outputProgressComplete($start_secs, undef,  $log_FH, *STDOUT);

# a quick note to the user about what to do next
outputString($log_FH, 1, sprintf("#\n"));
if(! $do_clocal) { 
  outputString($log_FH, 1, "# When the $nmdl cmcalibrate jobs on the farm finish, you can use dnaorg_annotate.pl\n");
  outputString($log_FH, 1, "# to use them to annotate genomes.\n");
}
else { 
  outputString($log_FH, 1, "# You can now use dnaorg_annotate.pl to annotate genomes with the models\n");
  outputString($log_FH, 1, "# you've created here.\n");
}
outputString($log_FH, 1, sprintf("#\n"));

##########
# Conclude
##########
$total_seconds += secondsSinceEpoch();
outputConclusionAndCloseFiles($total_seconds, $dir, \@ofile_keys_A, \%ofile_desc_H, \%ofile_sname_H, \%ofile_FH_H);

exit 0;

