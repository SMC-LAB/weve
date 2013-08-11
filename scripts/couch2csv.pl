#!/usr/bin/env perl

print STDERR "Usage: perl build_factors_table.pl PARTICIPANTS_DIR RATINGS_DIR\n"
    and exit -255
    unless @ARGV == 2;

use strict;
use warnings;
use autodie;
use JSON;
use File::Spec;
use DateTime::Format::Strptime;
use Data::Dumper;

my $date_parser = DateTime::Format::Strptime->new(
    pattern     => '%a %b %d %Y %T %Z',
    on_error    => 'croak',
    );

my %participants = parse_json_dir(
    $ARGV[0],
    sub { $_[1]->{name} }
    );

my %ratings = parse_json_dir(
    $ARGV[1],
    );

my $observations_headers = [qw/
stimuli
transform
name
Sex
Age
YMT
start_time
end_time
environment
experiment-manageable
experiment-tiring
experiment-notes
technical-problems
Jazz
Rock
Funk
Pop
Samba
Reggae
Folk
/];

my $current_ratings_headers = [
    "Movement inducing",
    qw/Familiarity
Preference
Naturalness
Groove
/];

binmode(STDOUT, ':utf8');

print join("\t", map {my $field = $_; $field =~ s/_/-/g; lc $field}
	   @$observations_headers, @$current_ratings_headers), "\n";

TRACK:
    while (my ($track, $ratings) = each %ratings) {

        my %current_ratings;
        my %observations;

      DVARIABLE:
        while (my ($dependent_variable, $user_ratings) = each %$ratings) {

          PARTICIPANT:
            while (my ($id, $rating) = each %$user_ratings) {

                my %track = parse_track($track);

                next PARTICIPANT unless exists $participants{$id};

                $current_ratings{$id}->{$dependent_variable} = $rating;
                $observations{$id} //= {%{$participants{$id}}, %track};
            }
        }

      BATCH:
        for my $id (sort keys %current_ratings) {
            print join(
		"\t",
		map { $_ //= 'NA'; $_ =~ s/[\r\n\t]/ /g; $_ }
		@{$observations{$id}}{@$observations_headers},
		@{$current_ratings{$id}}{@$current_ratings_headers}
		), "\n";
        }
}

sub parse_json_dir {
    my ($dir, $id_function) = @_;

    $id_function //= sub {
        my ($file, $json) = @_;
        return $file;
    };

    opendir(my $DIR, $dir);

    my %json = map {
        open my $JSON, '<', File::Spec->catfile( $dir, $_ );
        local $\;
        my $json_string = join '', <$JSON>;
        my $json = decode_json $json_string;
        close $JSON;
        $id_function->($_, $json) => $json;
    }
    grep {
        $_ ne File::Spec->curdir() and $_ ne File::Spec->updir()
    }
    readdir $DIR;
    closedir $DIR;
    return %json;
}

sub parse_track {
    my ($track, $flag) = @_;
    $track =~ s[\.json$][];
    my ($id, $transform) = $track =~ m[^(\w+)[-_](\w+)$];
    return stimuli => $id, transform => ($transform || "quantized");
}
