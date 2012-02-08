#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;

use GraphViz2::Marpa::Utils;

# -----------

my($print)         = shift || 0;
my($data_dir_name) = 'data';

my($dot_file);
my($lex_file);
my($parse_file);
my($rend_file);

for my $file_name (GraphViz2::Marpa::Utils -> new -> get_files($data_dir_name, 'dot') )
{
	$dot_file = File::Spec -> catfile($data_dir_name, "$file_name.dot");
	$lex_file = File::Spec -> catfile($data_dir_name, "$file_name.lex");

	print "$dot_file. \n" if ($print);

	`$^X -Ilib scripts/lex.pl -i $dot_file -lex $lex_file`;

	if (-e $lex_file)
	{
		$parse_file = File::Spec -> catfile($data_dir_name, "$file_name.parse");
		$rend_file  = File::Spec -> catfile($data_dir_name, "$file_name.rend");

		`$^X -Ilib scripts/parse.pl -l $lex_file -p $parse_file -o $rend_file`;
	}
}