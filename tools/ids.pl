#!/usr/bin/env perl
## Copyright (C) 2022 Harald Hope
## 
## License: GNU GPL v3 or greater
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
## If you don't understand what Free Software is, please read (or reread)
## this page: http://www.gnu.org/philosophy/free-sw.html
##
## These are based on lists found on latest driver support page:
## https://www.nvidia.com/Download/driverResults.aspx/187826/en-us
## http://us.download.nvidia.com/XFree86/Linux-x86_64/515.43.04/README/supportedchips.html#subsys
## Copy with mouse highlight the driver section, then paste that into a text file.
## Make sure it preserves the tabs \t!!! Otherwise it won't work!
use strict;
use warnings;
# use diagnostics;
use 5.024;

use Data::Dumper qw(Dumper); 
use JSON::PP; # if we ever get the data in json! sigh. 
# JSON::PP::encode_json
# JSON::PP::decode_json
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure ('bundling', 'no_ignore_case', 
'no_getopt_compat', 'no_auto_abbrev','pass_through');

my $self_name = 'ids.pl';
my $self_version = '1.0';
my $self_date = '2022-05-16';

my $b_print_ids = 0;
my $b_print_output = 1;
my $b_print_raw = 0;
my $b_print_remains = 1;
my $job = 'current';
my $tab = "\t";
my $options = 'current|470|390|367|340|304|173|96|71';

my ($active,@data,$file,%output);
my $line = '------------------------------------------------------------------';

## Rules:
# Confirm patterns if in doubt here: https://www.techpowerup.com/
# note, order matters here, so sort, since we delete the detected lines after
# each iteration through the keys
my $nv_data = {
# Nvidia GeForce GPU: GeForce GTX 860M
'current' => {
'file' => 'nv_515.xx.sort',
'00' => {
'arch' => 'Maxwell',
'pattern' => 'G?M\d{1,4}M?|MX1\d{2}|GTX? (745|750|8\d{2})(MX?|Ti)?|[89]\d{2}[AM]?X?|Quadro K(6\d|12\d|22\d)\dM?|NVS 8\d{2}|GeForce GPU',
},
# Matrox D-Series D1450/D1480: Nvidia. Pascal and GP107 - Quadro P1000	1CFB
'01' => {
'arch' => 'Pascal',
'pattern' => 'G?P\d{1,4}M?|MX[23]\d{2}|GPU100|Titan Xp?|GTX? 10\d{2}|D-Series D14\d{2}',
},
# not certain DGX are always V100, maybe, maybe not
'02' => {
'arch' => 'Volta',
'pattern' => 'G?V100S?|PG5\d{2}|Titan V|NVIDIA DGX',
},
# CMP are mining cpus
# Matrox D-Series D2450/D2480: Nvidia. Quadro RTX 3000 1F76
'03' => {
'arch' => 'Turing',
'pattern' => 'T\d{1,4}|MX[45]\d{2}|GTX 16\d{2}|RTX 20\d{2}|Quadro RTX [34568]\d{3}|Titan RTX|CMP [345]\dHX|D-Series D24\d{2}',
},
'04' => {
'arch' => 'Ampere',
'pattern' => 'G?A\d{1,4}[GMH]?|RTX 30\d{2}(Ti)?|CMP [789]\dHX',
},
# '05' => {
# 'arch' => 'Lovelace',
# 'pattern' => 'G?L\d{1,4}',
# },GT
# '06' => {
# 'arch' => 'Hopper',
# 'pattern' => 'G?H\d{1,4}',
# },
},
'470' => {
'file' => 'nv_470.xx.sort',
'00' => {
'arch' => 'Fermi 2',
'pattern' => '7[1]\d[AM]?|GT 720M',
},
'01' => {
'arch' => 'Kepler',
'pattern' => 'K\d{1,4}(M|D|c|st?|Xm|t)?|NVS|GTX|7[3-9]\d[AM]?|[689]\d{2}[AM]?|Quadro 4\d{2}|GT 720'
},
},
# these are all Fermi/Fermi 2.0
'390' => {
'file' => 'nv_390.xx.sort',
'00' => {
'arch' => 'Fermi',
'pattern' => '.*',
},
},
'367' => {
'file' => 'nv_367.xx',
'00' => {
'arch' => 'Kepler',
'pattern' => '.*',
},
},
# these are both Tesla and Tesla 2.0, if we want more granular, make 2 full 
# rulesets, otherwise they are all Tesla
'340' => {
'file' => 'nv_340.xx.sort',
'00' => {
'arch' => 'Tesla',
# T\d{1,4}|Tesla|[89]\d{3}(M|GS)?|(G|GT[SX]?)?\s?[1234]\d{2}M?|ION|NVS
'pattern' => '.*'
},
},
'304' => {
'file' => 'nv_304.xx.sort',
'00' => {
'arch' => 'Curie',
'pattern' => '[67]\d{3}(SE|M)?|Quadro (FX|NVS)'
},
},
'173' => {
'file' => 'nv_173.xx.sort',
'00' => {
'arch' => 'Rankine',
'pattern' => 'FX|PCX|NVS'
},
},
'96' => {
'file' => 'nv_96.xx.sort',
'00' => {
'arch' => 'Celsius',
'pattern' => 'GeForce2|Quadro2'
},
'01' => {
'arch' => 'Kelvin',
'pattern' => 'GeForce[34]|Quadro(4| NVS| DCC)'
},
},
'71' => {
'file' => 'nv_71.xx.sort',
'00' => {
'arch' => 'Fahrenheit',
'pattern' => 'TNT2?|Vanta'
},
'01' => {
'arch' => 'Celsius',
'pattern' => 'Quadro|GeForce2?'
},
},
};
sub process {
	foreach my $key (sort keys %$active){
		# say "$active->{$key}{'pattern'}";
		my (@ids);
		if (my @result = grep {/\b($active->{$key}{'pattern'})\b/i} @data){
			foreach my $item (@result){
				@data = grep {$_ ne $item} @data;
				my $temp = lc((split(/\t+/,$item))[1]);
				# note: if 3 ids, only first 1 product, others are subvendor/product
				my $product = (split(/\s+/,$temp))[0];
				push(@ids,$product);
			}
			# my @ids = map {$_ =~ s/^[^\t]+\t+([^\t]+)(\t|$)/$1/;$_ = lc($_);split(/\s+/,$_);} @result;
			# $arch =~ s/^\d+-//;
			@ids = sort @ids;
			uniq(\@ids);
			say "\n$active->{$key}{'arch'}:\n", join("\n",@ids) if $b_print_ids;
			$output{$key} = {'arch' => $active->{$key}{'arch'}, 'ids' => [@ids]};
		}
	}
	say join("\n",@data) if @data && $b_print_remains;
}
sub output {
	foreach my $sort (sort keys %output){
		say "${tab}'$output{$sort}->{'arch'}' => {" if $b_print_output;
		my $cnt = 4;
		my $cnt2 = 1;
		my $line = "$tab\'ids' => '";
		my $start = '';
		my $total = scalar @{$output{$sort}->{'ids'}};
		foreach my $id (@{$output{$sort}->{'ids'}}){
			my $sep = ($cnt2 < $total) ? '|' : '';
			# say "1: $cnt2 $total $id $sep";
			if ($cnt > 15){
				$cnt = 1;
				# say "2: $cnt2 $total";
				$line .= ($cnt2 != $total) ? "$id$sep' .\n" : $id;
				$start = "${tab}'";
			}
			else {
				$line .= "$start$id$sep";
				$start = '';
			}
			$cnt++;
			$cnt2++;
		}
		$line .= "',\n";
		say $line if $b_print_output;
	}
}

sub assign {
	$active = $nv_data->{$job};
	$file = 'lists/' . $active->{'file'};
	# say Dumper $active;
	delete $active->{'file'};
	# say Dumper $active;
}

sub reader {
	if (!$file || ! -r $file){
		die "$file does not exist, or is not readable!";
	}
	open(my $fh, '<', $file) or die "Reading $file failed with error: $!";
	chomp(@data = <$fh>);
	close $fh;
	die "\@rows had no data!" if !@data;
	my @temp;
	for (@data){
		next if /^\s*(#|$)/;
		$_ =~ s/^\s+|\s+$//g;
		push(@temp,$_);
	}
	@data = @temp;
	@data = sort @data;
}
sub uniq {
	my %seen;
	@{$_[0]} = grep !$seen{$_}++, @{$_[0]};
}
sub options {
	my @errors;
	Getopt::Long::GetOptions (
	'j|job:s' => sub {
		my ($opt,$arg) = @_;
		if ($arg =~ /^($options)$/){
			$job = $arg;
		}
		else {
			push(@errors,"Unsupported option for -$opt: $arg\n  Use [$options]");
		}
	},
	'r|raw' => sub {
		$b_print_raw = 1;
	},
	't|tabs' => sub {
		$tab = '';
	},
	'h|help' => sub {
		show_options();
		exit 0;
	},
	'v|version' => sub {
		show_version();
		exit 0;
	},
	'<>' => sub {
		my ($opt,$arg) = @_;
		push(@errors,"Unsupported option $opt");
	},
	);
	if (@errors){
		print "Sorry, Options Error:\n* ";
		say join("\n* ",@errors);
		say $line;
		show_options();
		exit 1;
	}
}
sub show_options {
	show_version();
	say "\nAvailable Options:";
	say "-h,--help    - this help option menu";
	say "-r,--raw     - show raw data before start of processing.";
	say "-j,--job     - [$options] job selector.";
	say "               Using: $job";
	say "-t,--tabs    - disable tab indentation.";
	say "-v,--version - show tool version and date.";
}
sub show_version {
	say "$self_name v: $self_version date: $self_date";
}
sub main {
	options();
	assign();
	reader();
	say Dumper \@data if $b_print_raw;
	die "No \@data returned!" if !@data;
	process();
	die "No \%output generated!" if !%output;
	output();
}
main();


