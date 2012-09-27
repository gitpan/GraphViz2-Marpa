#!/bin/bash
# Run with:
# scripts/fixed.length.paths.sh; cat data/fixed.length.gv; dot -Tsvg data/fixed.length.gv > html/fixed.length.svg; cp html/fixed.length.svg $DR

perl -Ilib scripts/fixed.length.paths.pl -lex data/90.Petersen.lex -out data/fixed.length.paths.gv -path_length 3 -report_paths 1 -start_node 5

dot -Tsvg data/fixed.length.paths.gv > html/fixed.length.paths.svg

cp html/fixed.length.paths.html $DR/Perl-modules/html/graphviz2.marpa/
cp html/90.Petersen.svg         $DR/Perl-modules/html/graphviz2.marpa/
cp html/fixed.length.paths.svg  $DR/Perl-modules/html/graphviz2.marpa/