#!/usr/bin/perl -w
use strict;
use FindBin qw( $RealBin );
use lib "RealBin/.../perl";

use Data::Dumper;
use Time::Local;
use Getopt::Long;
use Switch;

my $first = 1;
my $opt_debug;
my $debug;
GetOptions(
	"debug|d" => \$debug
);

 

my $hash_postgres_server;
my $hash_data;


	for (`barman list-server --minimal`) {
		chomp($_);
		my $postgres_server = $_;
		$hash_postgres_server -> {"$postgres_server"} = {} unless exists($hash_postgres_server -> {"$postgres_server"});
		$first = 0;
	}


foreach my $postgres_server(sort (keys %$hash_postgres_server)){
	my $cmd = "barman check $postgres_server";
	for (`$cmd`) {
		chomp($_);
		my $line = $_;
		
		my ($key,$value);
		if($line =~ /.*\(.*\)/){
			if($line =~ /\s+(.*):\s+(.*)\s+\(/){
				$key = $1;
				$value = $2;
			}
		} else {
			if($line =~ /\s+(.*):\s+(.*)/){
				$key = $1;
				$value = $2;
			}
		}

		if(($key) and ($value)){
			(my $ITEM_NAME = $key) =~ s/\s+/./g;
			my $ITEM_KEY = $postgres_server.".".$ITEM_NAME;
			$ITEM_NAME = $postgres_server.".".$ITEM_NAME;
			my $data = '{ "{#ITEM_NAME}":"'.$ITEM_NAME.'","{#ITEM_KEY}":"'.$ITEM_KEY.'" }';
			
			# generated a hash of all items from barman check
			$hash_data -> {"$ITEM_KEY"} = {} unless exists($hash_data -> {"$ITEM_KEY"});
			$hash_data -> {"$ITEM_KEY"} = {
				"data" => "$data",
				"value" => "$value",
			};
		}
	}
}


my $count_failed   = 0;
my $count_warning  = 0;
my $count_unknown  = 0;


#send the key / value
foreach my $ITEM_KEY(sort (keys %$hash_data)){
	my $value = $hash_data -> {"$ITEM_KEY"}-> {"value"};

	if ($value eq 'FAILED')  { print "$ITEM_KEY\: $value  \| \n"; $count_failed    = $count_failed +1; } 
	if ($value eq 'WARNING') { print "$ITEM_KEY\: $value  \| \n"; $count_warning   = $count_warning +1; } 
	if ($value ne 'FAILED' and $value ne 'WARNING' and $value ne 'OK')  { print "$ITEM_KEY\: $value  \| \n"; $count_unknown   = $count_unknown +1; } 
} 

#Compter les $value avec FAILED et sortir avec exit 2 ou 1 ou 3  si le nb >0
if ($count_failed > 0 ) { print "$count_failed errors \n"; exit 2}
if ($count_warning > 0 ) { print "$count_warning warinings \n"; exit 1}
if ($count_unknown > 0 ) { print "$count_unknown unknown \n"; exit 3}
if ($count_failed == 0 and $count_warning == 0 and $count_unknown == 0 ) { exit 0 }

sub _convert_unit{
	my %arg = @_;
	my $unit = $arg{'unit'};
	my $number = $arg{'number'};
	if(($unit) and ($number)){
		switch($unit) {
			case "KiB" { $number = $number * 1024 }
			case "MiB" { $number = $number * 1024 * 1024 }
			case "GiB" { $number = $number * 1024 * 1024 * 1024}
			case "TiB" { $number = $number * 1024 * 1024 * 1024 * 1024}
		}
	}
	return $number;
}
#print Dumper($hash_data);
