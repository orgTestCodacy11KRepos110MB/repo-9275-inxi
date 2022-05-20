#!/usr/bin/env perl
## ids.pl: Copyright (C) 2022 Harald Hope
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
my $self_version = '1.1';
my $self_date = '2022-05-17';

my $b_print_ids = 0;
my $b_print_output = 1;
my $b_print_raw = 0;
my $b_print_remains = 1;

my $job = 'nv-current';
my $options = 'amd|nv-urrent|470|390|367|340|304|173|96|71';

my ($active,$file,$id_data,%output);
my $data = [];
my $b_hash = 1;
my $br = "\n";
my $line = '------------------------------------------------------------------';
my $line_end = ' .';
my $quote = "'";
my $sep_global = '|';
my $tab = "\t";

## Rules:
# Confirm patterns if in doubt here: https://www.techpowerup.com/
# note, order matters here, so sort, since we delete the detected lines after
# each iteration through the keys
my $nv_data = {
# Nvidia GeForce GPU: GeForce GTX 860M
'nv-current' => {
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
'pattern' => 'K\d{1,4}(M|D|c|st?|Xm|t)?|NVS|GTX|7[3-9]\d[AM]?|[689]\d{2}[AM]?|Quadro 4\d{2}|GT 720',
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
'pattern' => '.*',
},
},
'304' => {
'file' => 'nv_304.xx.sort',
'00' => {
'arch' => 'Curie',
'pattern' => '[67]\d{3}(SE|M)?|Quadro (FX|NVS)',
},
},
'173' => {
'file' => 'nv_173.xx.sort',
'00' => {
'arch' => 'Rankine',
'pattern' => 'FX|PCX|NVS',
},
},
'96' => {
'file' => 'nv_96.xx.sort',
'00' => {
'arch' => 'Celsius',
'pattern' => 'GeForce2|Quadro2',
},
'01' => {
'arch' => 'Kelvin',
'pattern' => 'GeForce[34]|Quadro(4| NVS| DCC)',
},
},
'71' => {
'file' => 'nv_71.xx.sort',
'00' => {
'arch' => 'Fahrenheit',
'pattern' => 'TNT2?|Vanta',
},
'01' => {
'arch' => 'Celsius',
'pattern' => 'Quadro|GeForce2?',
},
},
};
my $amd_data = {
'amd' => {
'file' => 'amd.merged.sort',
'00' => {
'arch' => 'Wonder',
'pattern' => 'Color Emulation|Graphics Solution|[EV]GA Wonder',
'code' => 'Wonder',
'process' => 'NEC 800nm',
},
'01' => {
'arch' => 'Mach',
'pattern' => 'Mach\s?64|3D Rage (LT|II)|(ATI\s)?Graphics (Ultra|Vantage)|ATI 8514-Ultra',
'code' => 'Mach64',
'process' => 'TSMC 500-600nm',
},
'02' => {
'arch' => 'Rage 2',
'pattern' => 'Rage 2|3D Rage IIC',
'code' => 'Rage 2',
'process' => 'TSMC 500nm',
},
'03' => {
'arch' => 'Rage 3',
'pattern' => 'Rage (3|XL)|3D Rage (PRO)',
'code' => 'Rage 3',
'process' => '350nm',
},
'04' => {
'arch' => 'Rage 4',
'pattern' => 'Rage (4|128|Fury|Mobility[\s-]?(128|CL|M[1-4]?|P))|All-In-Wonder 128',
'code' => '',
'process' => 'TSMC 250nm',
},
# vendor 1014 IBM, subvendor: 1092
# 0172|0173|0174|0184
'05' => {
'arch' => 'IBM',
'pattern' => 'Fire GL[1234][As]?',
'code' => 'Fire GL',
'process' => 'IBM 156-250nm',
},
# rage 5 was game cube flipper chip
'06' => {
'arch' => 'Rage 6',
'pattern' => 'Rage 6|R[SV]?100|Radeon 7[02]\d{2}',
'code' => 'R100',
'process' => 'TSMC 180nm',
},
'07' => {
'arch' => 'Rage 7',
'pattern' => 'RV?2\d{2}|FireGL 88\d{2}|Radeon (7[3-9]{2}|8\d{3}|9[5-9]\d{2})|X1\d{3}|(FireGL) 9[5-9]\d{2}',
'code' => 'R200',
'process' => 'TSMC 150nm',
},
'08' => {
'arch' => 'Rage 8',
'pattern' => 'RV?3[0-5]\dX?|M10|Radeon 9[0-5]\d{2}',
'code' => 'R300',
'process' => 'TSMC 130nm',
},
'09' => {
'arch' => 'Rage 9',
'pattern' => 'RV?3[6-9]\d|RS48\d|M(1[12]2[24])Radeon 9[6-9]\d{2}|X(10|[2356])\d{2}|FireGL V3[12]\d{2}',
'code' => 'Radeon IGP',
'process' => '110nm',
},
'10' => {
'arch' => 'R400',
'pattern' => 'RV?4\d{2}|X[78]\d{2}',
'code' => 'R400',
'process' => '',
},
'11' => {
'arch' => 'R500',
'pattern' => 'RV5\d{2}|X[356789]\d{2}|FireGL V[37]\d{3}|FireMV 2\d{3}|M[567]\d',
'code' => 'R500',
'process' => 'TSMC 90nm',
},
'12' => {
'arch' => 'TeraScale',
'pattern' => 'HD [234]\d{3}',
'code' => 'R6xx/RV6xx/RV7xx',
'process' => '40-80nm',
},
'13' => {
'arch' => 'TeraScale 2',
'pattern' => 'Barts|Caicos|Cedar|Cypress|Evergreen|Hemlock|Juniper|Pinewood|Redwood|(Super)?Sumo|Thames|Turks|Whistler|Wrestler|HD (5[4-9]|6[2-7]|7[0-6])\d{2}[DGM]?|E76\d{2}',
'code' => 'Evergreen',
'process' => 'TSMC 32-40nm',
},
'14' => {
'arch' => 'TeraScale 3',
'pattern' => 'Northern Islands|Richland|Trinity|HD\s?69\s{2}|HD\s?[456]\d{2}G?',
'code' => 'Northern Islands',
'process' => 'TSMC 32nm',
},
'15' => {
'arch' => 'GCN-1',
'pattern' => 'Southern Islands|Tahiti|Venus|HD\s?77[5-9]{2}|HD\s?79[0-7]\d|E88\d{2}',
'code' => 'Southern Islands',
'process' => 'TSMC 28',
},
'16' => {
'arch' => 'GCN 2',
'pattern' => 'Beema|Bonaire|Emerald|Grenada|Hawaii|Kalindi|Liverpool|Mullins|Neo|Saturn|Scorpio|Sea Islands|Spectre|Strato|Temash|Tobago|Vesuvius|HD\s?(77|82)\d{2}|Radeon R[234]E?',
'code' => 'Sea Islands',
'process' => '28nm', # both TSMC and GlobalFoundries
},
'17' => {
'arch' => 'GCN 3',
'pattern' => 'Volcanic|Tonga|Topaz|Radeon R7 M',
'code' => 'Volcanic Islands',
'process' => 'TSMC 28nm',
},
'18' => {
'arch' => 'GCN 4',
'pattern' => 'Arctic Islands|Baffin|Polaris\s?\d*',
'code' => 'Arctic Islands',
'process' => 'TSMC 14nm',
},
'19' => {
'arch' => 'GCN 5',
'pattern' => 'Vega',
'code' => 'Vega',
'process' =>  'TSMC 14nm',
},
'20' => {
'arch' => 'RDNA',
'pattern' => 'Navi 1\d\b',
'code' => 'Navi',
'process' => 'TSMC 7nm',
},
'21' => {
'arch' => 'RDNA 2',
'pattern' => 'Navi 2\d\b',
'code' => 'Navi 2x',
'process' => 'TSMC 7nm',
},
},
};

sub process {
	foreach my $key (sort keys %$active){
		# say "$active->{$key}{'pattern'}";
		my (@ids);
		if (my @result = grep {/\b($active->{$key}{'pattern'})\b/i} @$data){
			foreach my $item (@result){
				@$data = grep {$_ ne $item} @$data;
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
	say join("\n",@$data) if @$data && $b_print_remains;
}
sub output {
	foreach my $sort (sort keys %output){
		if ($b_print_output){
			if ($b_hash){
				say $tab . $quote . $output{$sort}->{'arch'} . $quote . ' => {';
			}
			else {
				say $output{$sort}->{'arch'} . ':';
			}
		}
		my $cnt = 4;
		my $cnt2 = 1;
		my $line = ($b_hash) ? $tab . $quote . "ids$quote => " . $quote : '';
		my $start = '';
		my $total = scalar @{$output{$sort}->{'ids'}};
		foreach my $id (@{$output{$sort}->{'ids'}}){
			my $sep = ($cnt2 < $total) ? $sep_global : '';
			# say "1: $cnt2 $total $id $sep";
			if ($cnt > 15){
				$cnt = 1;
				# say "2: $cnt2 $total";
				$line .= ($cnt2 != $total) ? $id . $sep . $quote . $line_end . $br : $id;
				$start = $tab . $quote;
			}
			else {
				$line .= $start . $id . $sep;
				$start = '';
			}
			$cnt++;
			$cnt2++;
		}
		# we want hardcoded \n here to create spaces between result blocks
		$line .= ($b_hash) ? "$quote,\n" : "\n";
		say $line if $b_print_output;
	}
}

sub assign {
	$active = ($job ne 'amd') ? $nv_data->{$job} : $amd_data->{$job};
	$file = 'lists/' . $active->{'file'};
	# say Dumper $active;
	delete $active->{'file'};
	# say Dumper $active;
}

sub checks {
	my @errors;
	if (! -e $self_name ){
		push(@errors,"You must start $self_name from the directory it is located in!");
	}
	if (@errors){
		print "The following errors were encountered:\n* ";
		say join("* ", @errors);
		exit 1;
	}
}

sub reader {
	my $file = $_[0];
	if (!$file || ! -r $file){
		die "$file does not exist, or is not readable!";
	}
	open(my $fh, '<', $file) or die "Reading $file failed with error: $!";
	chomp(@$data = <$fh>);
	close $fh;
	die "\@data had no data!" if !@$data;
	my @temp;
	for (@$data){
		next if /^\s*(#|$)/;
		$_ =~ s/^\s+|\s+$//g;
		push(@temp,$_);
	}
	@$data = @temp;
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
	'h|help' => sub {
		show_options();
		exit 0;
	},
	'i|ids' => sub {
		$b_print_ids = 1;
	},
	'l|line-end:s' => sub {
		my ($opt,$arg) = @_;
		$line_end = $arg;
	},
	'p|plain' => sub {
		$b_hash = 0;
		$br = '';
		$line_end = '';
		$quote = '';
		$tab = '';
	},
	'r|raw' => sub {
		$b_print_raw = 1;
	},
	's|sep:s' => sub {
		my ($opt,$arg) = @_;
		if ($arg =~ /^.+$/){
			$sep_global = $arg;
		}
		else {
			push(@errors,"Unsupported option for -$opt: $arg\n  Use [$options]");
		}
	},
	't|tabs' => sub {
		$tab = '';
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
	say "-h,--help     - This help option menu";
	say "-i,--ids      - Print product/pci ids list raw before formatted id lists.";
	say "-j,--job      - [$options] job selector.";
	say "                Using: $job";
	say "-l,--line-end - [empty|chars] Change line ending per line.";
	say "                Current: '$line_end'";
	say "-p,--plain    - Output single line, no breaks, no quotes or tabs";
	say "-r,--raw      - Print raw driver list data before start of processing.";
	say "-s,--sep      - Separator to use for IDs. Current: $sep_global";
	say "-t,--tabs     - Disable tab indentation.";
	say "-v,--version  - Show tool version and date.";
}
sub show_version {
	say "$self_name v: $self_version date: $self_date";
}
sub main {
	checks();
	options();
	assign();
	reader($file);
	say Dumper $data if $b_print_raw;
	die "No \@data returned!" if !@$data;
	process();
	die "No \%output generated!" if !%output;
	output();
}
main();


