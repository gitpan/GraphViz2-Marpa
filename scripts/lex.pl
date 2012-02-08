#!/usr/bin/env perl

use strict;
use warnings;

use GraphViz2::Marpa::Lexer;

use Getopt::Long;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'description=s',
 'help',
 'input_file=s',
 'lexed_file=s',
 'maxlevel=s',
 'minlevel=s',
 'report_items=i',
 'report_stt=i',
 'stt_file=s',
 'timeout=i',
 'type=s',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1 for failure.

	exit GraphViz2::Marpa::Lexer -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

lex.pl - Run GraphViz2::Marpa::Lexer.

=head1 SYNOPSIS

lex.pl [options]

	Options:
	-description graphDescription
	-help
	-input_file aDotInputFileName
	-lexed_file aLexedOutputFileName
	-maxlevel logOption1
	-minlevel logOption2
	-report_items Boolean
	-report_stt Boolean
	-stt_file sttFileName
	-timeout seconds
	-type '' or csv or ods

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item -description graphDescription

Read the DOT-style graph definition from the command line.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the -input_file option to read the description from a file.

The -description option takes precedence over the -input_file option.

Default: ''.

=item -help

Print help and exit.

=item -input_file aDotInputFileName

Read the DOT-style graph definition from a file.

See also the -description option to read the graph definition from the command line.

The -description option takes precedence over the -input_file option.

Default: ''.

See the distro for data/*.dot.

=item -lexed_file aLexedOutputFileName

Specify the name of a CSV file of lexed tokens to write. This file can be input to the parser.

Default: ''.

The default means the file is not written.

See the distro for data/*.lex.

=item -maxlevel logOption1

This option affects Log::Handler.

See the Log::Handler docs.

Default: 'notice'.

=item -minlevel logOption2

This option affects Log::Handler.

See the Log::Handler docs.

Default: 'error'.

No lower levels are used.

=item -report_items Boolean

Log the items recognised by the lexer.

Default: 0.

=item -report_stt Boolean

Log the State Transition Table.

Calls Set::FA::Element.report(). Set min and max log levels to 'info' for this.

Default: 0.

=item -stt_file sttFileName

Specify which file contains the State Transition Table.

Default: ''.

The default value means the STT is read from the source code of GraphViz2::Marpa::Lexer.

Candidate files are '' and 'data/default.stt.csv'.

The type of this file must be specified by the -type option.

If the file name matches /csv$/, the value of the -type option is set to 'csv'.

=item -timeout seconds

Run the DFA for at most this many seconds.

Default: 10.

=item -type '' or cvs or ods

Specify the type of the stt_file: '' for internal STT and 'csv' for CSV.

Default: ''.

The default value means the STT is read from the source code of GraphViz2::Marpa::Lexer.

This option must be used with the -stt_file option.

Warning: The 'ods' option is disabled, because I can find no way in LibreOffice to make it operate in ASCII. What happens is that when you type "
(i.e. the double-quote character on the keyboard), LibreOffice inserts a different double-quote character, which, when exported as CSV in Unicode
format, produces these 3 bytes: 0xe2, 0x80, 0x9c. This means that if you edit the STT, you absolutely must export to a CSV file in ASCII format.
It also means that DOT identifiers in (normal) double-quotes will never match the double-quotes in the *.ods file.

=back

=cut