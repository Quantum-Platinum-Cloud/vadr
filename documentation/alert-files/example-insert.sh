#!/bin/bash
perl $VADRSCRIPTSDIR/v-annotate.pl --minpvlen 3 --nmaxins 2 --pv_skip --keep --mkey toy50 -mdir $VADRSCRIPTSDIR/documentation/alert-files -f $VADRSCRIPTSDIR/documentation/alert-files/example-insert.fa va-example-insert
