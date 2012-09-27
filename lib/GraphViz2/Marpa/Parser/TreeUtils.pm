package GraphViz2::Marpa::Parser::TreeUtils;

use parent 'GraphViz2::Marpa::Parser';
use strict;
use warnings;

use Hash::FieldHash ':all';

use Tree::DAG_Node;

fieldhash my %fixed_paths  => 'fixed_paths';
fieldhash my %path_length  => 'path_length';
fieldhash my %report_paths => 'report_paths';
fieldhash my %root         => 'root';
fieldhash my %start_node   => 'start_node';
fieldhash my %tree_file    => 'tree_file';

our $VERSION = '1.04';

# -----------------------------------------------
# Add edges to the tree of nodes.

sub _add_edge2tree
{
	my($self, $index, $root, $items) = @_;

	my($daughter);
	my($name);

	while ($index < $#$items)
	{
		$index++;

		# Skip if not a node.

		next if ($$items[$index]{type} ne 'node_id');

		# Nodes found by find_edges() belong to the 'current' root.

		$name     = $$items[$index]{value};
		$daughter = Tree::DAG_Node -> new;

		$daughter -> name($name);
		$root -> add_daughter($daughter);

		# Is there room in the list for another edge and node?

		last if ($index > $#$items - 2);

		# Skip if the next element is not an edge.

		last if ($$items[$index + 1]{type} ne 'edge_id');

		# Skip if the next-but-1 element is not a node.

		last if ($$items[$index + 2]{type} ne 'node_id');

		# Step to the edge, and the top of the loop steps to the node.

		$root  = $daughter;
		$index += 1;
	}

	# We must return the index to tell the caller where to
	# continue from in its search for daughters of the real root.

	return $index;

} # End of _add_edge2tree.

# -----------------------------------------------
# Build a tree of nodes from the Graphviz file.

sub _build_tree
{
	my($self, $index, $root, $items) = @_;

	my($daughter);
	my($name);

	while ($index < $#$items)
	{
		$index++;

		# Skip if not a node.

		next if ($$items[$index]{type} ne 'node_id');

		$name = $$items[$index]{value};

		# Skip special cases. TODO: How to handle real nodes with these names?

		next if ($name =~ /^(?:edge|graph|node)/);

		# Nodes found by find_nodes() belong to the real root.

		$daughter = Tree::DAG_Node -> new;

		$daughter -> name($name);
		$root -> add_daughter($daughter);

		# Is there room in the list for another edge and node?

		next if ($index > $#$items - 2);

		# Skip if the next element is not an edge.

		next if ($$items[$index + 1]{type} ne 'edge_id');

		# Skip if the next-but-1 element is not a node.

		next if ($$items[$index + 2]{type} ne 'node_id');

		$index = $self -> _add_edge2tree($index + 1, $daughter, $items);
	}

} # End of _build_tree.

# -----------------------------------------------

sub _find_fixed_length_candidates
{
	my($self, $solution, $stack) = @_;
	my($current_node) = $$solution[$#$solution];

	# Add the node's parent, if it's not the root.
	# Then add the node's daughters.

	my(@neighbours);

	$self -> root -> walk_down
	({
		callback   => \&_find_fixed_length_cb,
		neighbours => \@neighbours,
		_depth     => 0,
		name       => $current_node -> name,
	});

	# Now filter out the nodes we don't want:

	my(@names) = map{$_ -> name} @$solution;

	my(%seen);

	@seen{@names} = (1) x @names;
	@neighbours   = grep{! defined $seen{$_ -> name} } @neighbours;

	# Elements:
	# 0 .. N: The neighbours.
	# N + 1:  The count of neighbours.

	push @$stack, @neighbours, $#neighbours + 1;

} # End of find_fixed_length_candidates.

# -----------------------------------------------
# Warning: This is a function.

sub _find_fixed_length_cb
{
	my($node, $option) = @_;

	# Skip this node if:
	# o It is the root node.
	# o It is a not copy of the current node.
	# Return 1 to keep scanning the tree.

	return 1 if (! defined $node -> mother);
	return 1 if ($node -> name ne $$option{name});

	# Save this node if it's a neighbour of the current node.

	my(@neighbours);

	for my $n ($node -> mother, $node -> daughters)
	{
		# Skip the root node.

		next if (! defined $n -> mother);

		push @{$$option{neighbours} }, $n;
	}

	# Return 1 to keep scanning the tree.

	return 1;

} # End of _find_fixed_length_cb.

# -----------------------------------------------
# Find all paths starting from any copy of the target start_node.

sub _find_fixed_length_path_set
{
	my($self, $start) = @_;
	my($one_solution) = [];
	my($stack)        = [];

	my(@all_solutions);
	my($count, $candidate);

	# Push 1 candidate and its count onto the stack.

	push @$stack, $$start[0], 1;

	# Process these N candidates 1-by-1.
	# The top-of-stack is a candidate count.

	while ($#$stack >= 0)
	{
		while ($$stack[$#$stack] > 0)
		{
			($count, $candidate) = (pop @$stack, pop @$stack);

			push @$stack, $count - 1;
			push @$one_solution, $candidate;

			# Does this candidate suit the solution so far?

			if ($#$one_solution == $self -> path_length)
			{
				# Yes. Save this solution

				push @all_solutions, [@$one_solution];

				# Discard this candidate, and try another.

				pop @$one_solution;
			}
			else
			{
				# No. The solution so far is too short.
				# Push N more candidates onto the stack.

				$self -> _find_fixed_length_candidates($one_solution, $stack);
			}
		}

		# Pop the 0 (candidate count) off the stack.
		# If there are any more candidates left, loop.

		pop @$stack;
		pop @$one_solution;
	}

	$self -> fixed_paths([@all_solutions]);

} # End of _find_fixed_length_path_set.

# -----------------------------------------------
# Find all paths starting from any copy of the target start_node.

sub _find_fixed_length_paths
{
	my($self) = @_;

	my(@stack);

	$self -> root -> walk_down
	({
		callback => \&_find_start_node_cb,
		_depth   => 0,
		name     => $self -> start_node,
		stack    => \@stack,
	});

	# Give up if the given node was not found.
	# Return 0 for success and 1 for failure.

	die 'Error: Start node (', $self -> start_node, ") not found\n" if ($#stack < 0);

	$self -> _find_fixed_length_path_set(\@stack);

} # End of _find_fixed_length_paths.

# -----------------------------------------------
# Warning: This is a function.

sub _find_start_node_cb
{
	my($node, $option) = @_;

	push @{$$option{stack} }, $node if ($node -> name eq $$option{name});

	# Return 1 to keep scanning the tree.

	return 1;

} # End of _find_start_node_cb.

# -----------------------------------------------

sub fixed_length_paths
{
	my($self)  = @_;
	my($title) = 'Paths of length ' . $self -> path_length . ' starting from node ' . $self -> start_node;

	# Generate the RAM-based version of the graph.

	$self -> run;

	# Assemble the nodes into a tree.

	my(@items) = @{$self -> items};

	$self -> _build_tree(-1, $self -> root, \@items);

	# Process the tree.

	$self -> _find_fixed_length_paths;
	$self -> report_fixed_paths($title) if ($self -> report_paths);
	$self -> output_fixed_paths($title) if ($self -> output_file);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of fixed_length_paths.

# -----------------------------------------------

sub _init
{
	my($self, $arg)     = @_;
	$$arg{path_length}  ||= 0;  # Caller can set.
	$$arg{report_paths} ||= 0;  # Caller can set.
	$$arg{root}         = Tree::DAG_Node -> new;
	$$arg{start_node}   ||= ''; # Caller can set.
	$$arg{tree_file}    ||= ''; # Caller can set.
	$self               = $self -> SUPER::_init($arg);

	die "No start node specified\n"  if (! defined $self -> start_node);
	die "Path length must be >= 0\n" if ($self -> path_length < 0);

	$self -> root -> name('Root');

	return $self;

} # End of _init.

# -----------------------------------------------

sub output_fixed_paths
{
	my($self, $title) = @_;
	my(@solutions)    = @{$self -> fixed_paths};

	# We have to rename all the node so they can all be included
	# in a DOT file without dot linking them based on their names.

	my($new_name)  = 0;

	my($name);
	my(@set);

	for my $set (@solutions)
	{
		my(@name);
		my(%seen);

		for my $node (@$set)
		{
			$name = $node -> name;

			if (! defined($seen{$name}) )
			{
				$seen{$name} = ++$new_name;
			}

			push @name, {label => $name, name => $seen{$name} };
		}

		push @set, [@name];
	}

	open(OUT, '>', $self -> output_file) || die "Can't open(> ", $self -> output_file, "): $!\n";
	print OUT <<"EOS";
strict digraph
{
	graph [label = \"$title\" rankdir = LR size = \"6x7\"];

EOS
	for my $set (@set)
	{
		for my $node (@$set)
		{
			print OUT qq|\t"$$node{name}" [label = "$$node{label}"]\n|;
		}
	}

	for my $set (@set)
	{
		print OUT "\t", join(' -> ', map{qq|"$$_{name}"|} @$set), ";\n";
	}

	print OUT "}\n";
	close OUT;

} # End of output_fixed_paths.

# -----------------------------------------------

sub report_fixed_paths
{
	my($self, $title) = @_;
	my(@solutions)    = @{$self -> fixed_paths};

	print "$title:\n";

	for my $candidate (@solutions)
	{
		print join(' - ', map{$_ -> name} @$candidate), "\n";
	}

	print 'Solution count: ', scalar @solutions, "\n";

} # End of report_fixed_paths.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Marpa::Parser::Tree> - A Perl lexer and parser for Graphviz dot files

=head1 Synopsis

See scripts/generate.index.pl, and scripts/dot2lex.pl etc.

=head1 Description

Some utils to simplify reading CSV files, and testing.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<GraphViz2::Marpa> as you would for any C<Perl> module:

Run:

	cpanm GraphViz2::Marpa

or run:

	sudo cpan GraphViz2::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = GraphViz2::Marpa::Utils -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Marpa::Parser::Tree>.

This class is a descendent of L<GraphViz2::Marpa::Parser>, and hence inherits all its keys to new().

Further, these key-value pairs are accepted in the parameter list:

=over 4

=item o (none)

=back

=head1 Methods

This class is a descendent of L<GraphViz2::Marpa::Parser>, and hence inherits all its methods.

Further, these methods are implemented.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2::Marpa>.

=head1 Author

L<GraphViz2::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
