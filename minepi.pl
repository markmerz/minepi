#!/usr/bin/perl
# @author Markko Merzin, markko.merzin@ut.ee, 2010. 

use Storable qw(dclone);

$ft = 200; # support threshold
$tt = 99999999; # lookahead limit, kind of window size.

$ct = 0.70; # confidence threshold

# for testdata
#$ft = 1;
#$tt = 10000000;

open(IN, $ARGV[0]) || die "inputfile: $!";

open(OUT, "> $ARGV[1]") || die "outputfile: $!";

%singletons=();
while(<IN>) {
	if(m/^(\d+):(\S+)$/) { # this line parses input file.
		my $time=$1;
		my $event=$2;
		if ( $singletons{$event} == undef ) {
			$singletons{$event} = [$time];
		} else {
			push @{$singletons{$event}}, $time;
		}
	} else {
		# die "input file parse error";
	}



}

close IN;

# delete non frequent singletons
while (($key, $value) = each(%singletons)){
	$len=scalar(@{$value});
	if ($len < $ft) {
		delete $singletons{$key};
	}
}

@episodes = ();
foreach $singleton (keys %singletons) {
	my $event = {
		EPISODE => [($singleton)],
		STARTS => [@{$singletons{$singleton}}],
		ENDS => [@{$singletons{$singleton}}],
		CANDIDATE => undef
	};
	push @episodes, $event;
}

@results = ();

do {
	@newepisodes = ();
	my @candidates = ();
	foreach my $episode (@episodes) {
		bar: foreach my $singleton (keys %singletons) {
			foreach my $s (@{$episode->{EPISODE}}) {
				if ($s eq $singleton) {
					next bar;
				}
			}
			my $episode2 = dclone($episode);
			$episode2->{CANDIDATE} = $singleton;
			push @candidates, $episode2;
		}


	}

	foreach my $candidate (@candidates){
		my $episode = {
			EPISODE => dclone($candidate->{EPISODE}),
			STARTS => [()],
			ENDS => [()],
			CANDIDATE => undef
		};
		push @{$episode->{EPISODE}}, $candidate->{CANDIDATE};

		for(my $c=0; $c < scalar( @{$candidate->{STARTS}} ); $c++) {
			my $cstart = @{$candidate->{STARTS}}[$c];
			my $cend = @{$candidate->{ENDS}}[$c];
			my $eend = undef;
			foreach my $end (@{$singletons{$candidate->{CANDIDATE}}}) {
				if ($end > $cend) {
					$eend = $end;
					last;
				}
			}
			if ($eend != undef && $eend - $cstart <= $tt) {
				push @{$episode->{STARTS}}, $cstart;
				push @{$episode->{ENDS}}, $eend;
			}
		}


		if (scalar(@{$episode->{STARTS}}) == 0) {
			next;
		}

		for (my $c=0; $c < scalar(@{$episode->{STARTS}}); $c++) {
			for (my $d=$c+1; $d < scalar(@{$episode->{STARTS}}); $d++) {
				if (@{$episode->{STARTS}}[$c] <= @{$episode->{STARTS}}[$d] 
					&& @{$episode->{ENDS}}[$c] >= @{$episode->{ENDS}}[$d]){

					@{$episode->{STARTS}}[$c] = @{$episode->{ENDS}}[$c] = undef;
				}
			}
		}

		my @newstarts = ();
		my @newends = ();
		for (my $c=0; $c < scalar(@{$episode->{STARTS}}); $c++) {
			if (@{$episode->{STARTS}}[$c] != undef) {
				push @newstarts, @{$episode->{STARTS}}[$c];
				push @newends, @{$episode->{ENDS}}[$c];
			}
		}
		$episode->{STARTS} = \@newstarts;
		$episode->{ENDS} = \@newends;

		if (scalar(@{$episode->{STARTS}}) >= $ft) {
			push @results, dclone($episode);
			push @newepisodes, $episode;
		}


	}
	@episodes = @newepisodes;

	my $elen = scalar(@newepisodes);
} while(scalar(@newepisodes) > 0);

foreach $singleton (keys %singletons) {
	my $sup = scalar(@{$singletons{$singleton}});
	print OUT "$sup", "::", "$singleton\n";
}

foreach my $episode (@results) {
	my $sup = scalar(@{$episode->{STARTS}});
	my @left = @{$episode->{EPISODE}};
	my @right = ();
	while(scalar(@left) > 1) {
		push @right, pop @left;
		my $supl = &findsupport(@left);
		my $conf = $sup / $supl;
		if ($conf >= $ct){
			my $leftp = join ",", @left;
			my $rightp = join ",", @right;
			print OUT "$sup:$conf:$leftp>$rightp\n";
		}
	}
}

close OUT;

sub findsupport(\@) {
	my @param = @_;
	my $sup = undef;

	if (scalar(@param) > 1) {
		lab2: foreach my $episode (@results) {
			my @ep =  @{$episode->{EPISODE}};
			if (scalar(@ep) == scalar(@param)) {
				for (my $c = 0; $c < scalar(@ep); $c++){
					if ($ep[$c] ne $param[$c]) {
						next lab2;
					}
				}
				$sup = scalar(@{$episode->{STARTS}});
				last lab2;
			}

		}
	} else {
		$sup = @{$singletons{pop(@param)}};
	}

	return $sup;
}


