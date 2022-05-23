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
my $self_version = '1.3';
my $self_date = '2022-05-22';

my $b_print_output = 1;
my $b_print_remains = 1;

my $job = 'nv-current';
my $options = 'amd|intel|nv-current|470|390|367|340|304|173|96|71';

my ($active,$file,$id_data,%output);
my $data = [];
my $b_hash = 1;
my $br = "\n";
my $line = '------------------------------------------------------------------';
my $line_end = ' .';
my $quote = "'";
my $sep_global = '|';
my $tab = "\t";
my $dbg = [];

## Rules:
# Confirm patterns if in doubt here: https://www.techpowerup.com/
# note, order matters here, so sort, since we delete the detected lines after
# each iteration through the keys

my $amd_data = {
'amd' => {
'file' => 'gpu.amd.full.sort',
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
'pattern' => 'Rage[\s-](4|128|Fury|X[CL]|RS[67]\d|RV410|Mobility[\s-]?(128|CL|M[1-4]?|P))|^Rage Mobility|All-In-Wonder 128',
'code' => 'Rage 4',
'process' => 'TSMC 250-350nm',
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
'pattern' => 'Rage 6|RV?100|RS2[05]0M?|Radeon 7[02]\d{2}|M6|ES1000',
'code' => 'R100',
'process' => 'TSMC 180nm',
},
# |Radeon (7[3-9]{2}|8\d{3}|9[5-9]\d{2}
'07' => {
'arch' => 'Rage 7',
'pattern' => 'RV?2\d{2}|RC22\d{2}|RS100|RS3[05]0M?|FireGL 88\d{2}|X1\d{3}|FireGL 9[5-9]\d{2}|Mobility Radeon 9[01]\d{2}|M[79]\+?',
'code' => 'R200',
'process' => 'TSMC 150nm',
},
'08' => {
'arch' => 'Rage 8',
'pattern' => 'R3[0-5]0|RC4[1]0|RC410M?|RS400M?|RV350|M10|M10',
'code' => 'R300',
'process' => 'TSMC 130nm',
},
'09' => {
'arch' => 'Rage 9',
'pattern' => 'RV?3[6-9]\d[MX]?|RS48\dM?|M(1[12]2[24])Radeon 9[6-9]\d{2}|X(10|[2356])\d{2}|FireGL V3[12]\d{2}',
'code' => 'Radeon IGP',
'process' => 'TSMC 110nm',
},
'10' => {
'arch' => 'R400',
'pattern' => 'R4[238]\d|RS6[09]\dM?|RS74\dM?|RV410|M(18|26|28)',
'code' => 'R400',
'process' => 'TSMC 55-130nm',
},
'11' => {
'arch' => 'R500',
'pattern' => 'RV?5\d{2}|X[356789]\d{2}|FireGL V[37]\d{3}|FireMV 2\d{3}|X19\d{2}|M[567]\d',
'code' => 'R500',
'process' => 'TSMC 90nm',
},
'12' => {
'arch' => 'TeraScale',
'pattern' => 'Xenos|RV?[67]\d{2}|RS6[09]0M?|RS[76]80[CLM]?|HD [234]\d{3}|M7[246]|8[2468]|M9[23678]',
'code' => 'R6xx/RV6xx/RV7xx',
'process' => '40-80nm',
},
# llano, ontario, zacate apu
'13' => {
'arch' => 'TeraScale 2',
'pattern' => 'Barts|Blackcomb|Broadway|Caicos|Capilano|Cedar|Cypress|Evergreen|Granville|Hemlock|Juniper|Latte|Lexington|Llano|Loveland|Madison|Onega|Ontario|Park|Pinewood|Redwood|Robson|Seymour|(Super)?Sumo|Thames|Turks|Whistler|Wrestler|Zacate|HD (64|74)\d{2}M|E76\d{2}',
'code' => 'Evergreen',
'process' => 'TSMC 32-40nm',
},
# trinity, richland apu
'14' => {
'arch' => 'TeraScale 3',
'pattern' => 'Northern Islands|Antilles|Cayman|Devastator|Richland|Scrapper|Trinity|HD\s?69\s{2}|HD\s?[456]\d{2}G?|FirePro A3\d{2}',
'code' => 'Northern Islands',
'process' => 'TSMC 32nm',
},
'15' => {
'arch' => 'GCN 1',
'pattern' => 'Southern Islands|Banks|Cape Verde|Chelsea|Curacao|Durango|Exo|Hainan|Heathrow|Jet|Kryptos|Litho|Malta|Mars|Neptune|New Zealand|Oland|Opal|Pitcairn|Sun|Tahiti|Trinidad|Tropo|Venus|Wimbledon|HD\s?77[5-9]{2}|HD\s?79[0-7]\d|E88\d{2}',
'code' => 'Southern Islands',
'process' => 'TSMC 28',
},
# beema, mullins, kabini, kaveri, temash apu
'16' => {
'arch' => 'GCN 2',
'pattern' => 'Sea Islands|Beema|Bonaire|Emerald|Grenada|Hawaii|Kabini|Kalindi|Kaveri|Liverpool|Mullins|Neo|Saturn|Scorpio|Spectre|Strato|Temash|Tobago|Vesuvius|HD\s?(77|82)\d{2}|Radeon R[234]E?',
'code' => 'Sea Islands',
'process' => 'GF/TSMC 16-28nm', # both TSMC and GlobalFoundries
},
# carrizo, bristol, prairie, stoney ridge apu
'17' => {
'arch' => 'GCN 3',
'pattern' => 'Volcanic|Amethyst|Antigua|Bristol|Capsaicin|Carrizo|Fiji|Meso|Prarie|Polaris\s?24|Stoney|Tonga|Topaz|Wani|Weston|Radeon R7 M',
'code' => 'Volcanic Islands',
'process' => 'TSMC 28nm',
},
'18' => {
'arch' => 'GCN 4',
'pattern' => 'Arctic Islands|Baffin|Ellesmere|Lexa|Polaris\s?(2[0123]|3[01])*',
'code' => 'Arctic Islands',
'process' => 'GF 14nm',# s
},
# needs to go before 5 to catch the vega > 1
# cezanne, lucienne, renoir apu
'19' => {
'arch' => 'GCN 5.1',
'pattern' => 'Vega (II|[678]|20)|Cezanne|Lucienne|Renoir|Radeon (Graphics [345]\d{2}SP|Pro VII|Instinct MI[56]\d)',
'code' => 'Vega 2',
'process' =>  'TSMC 7nm',
},
# raven ridge, dali, picasso, kestrel apu
'20' => {
'arch' => 'GCN 5',
'pattern' => 'Vega|Dali|Fenghuang|Kestrel|Picasso|Raven|Instinct MI[12]\d',
'code' => 'Vega',
'process' =>  'TSMC 14nm',
},
'21' => {
'arch' => 'RDNA 1',
'pattern' => 'Navi\s?1\d\b',
'code' => 'Navi',
'process' => 'TSMC 7nm',
},
# Lockhart, Oberon, Rembrandt, Scarlett, Van Gogh apu
'22' => {
'arch' => 'RDNA 2',
'pattern' => 'Navi\s?2\d\b|Lockhart|Oberon|Rembrandt|Scarlett|Van Gogh|Radeon 680M',
'code' => 'Navi 2x',
'process' => 'TSMC 7nm',
},
# phoenix apu
'23' => {
'arch' => 'RDNA 3',
'pattern' => 'Navi\s?3\d\b|Phoenix|RX 7[78]\d{2} XT',
'code' => 'Navi 3x',
'process' => 'TSMC 5nm',
},
'24' => {
'arch' => 'CDNA 1',
'pattern' => 'Arcturus|Radeon Instinct MI1\d{2}',
'code' => 'Instinct',
'process' => 'TSMC 7nm',
},
'25' => {
'arch' => 'CDNA 2',
'pattern' => 'Aldebaran|Radeon Instinct MI2\d{2}',
'code' => 'Instinct',
'process' => 'TSMC 6nm',
},
},
};

my $intel_data = {
'intel' => {
'file' => 'gpu.intel.full.sort',
'00' => {
'arch' => 'Gen1',
'pattern' => '827\d{2}|8281[05]\S?|i74[02]|i815|i830|Whitney',
'code' => '',
'process' => 'Intel 150nm',
},
'01' => {
'arch' => 'Gen2',
'pattern' => '(82)?865G|828[34]\dM|Brookdale|Springdale|Extreme Graphics',
'code' => '',
'process' => 'Intel 130nm',
},
'02' => {
'arch' => 'Gen3',
'pattern' => '(82)?91[05]GM?|82[GQ]3[35]|Grantsdale|Alviso|GMA\s?900',
'code' => '',
'process' => 'Intel 130nm',
},
'03' => {
'arch' => 'Gen3.5',
'pattern' => '(82)?94[56]G[A-Z]*|Lakeport|Calistoga|GMA\s?950',
'code' => '',
'process' => 'Intel 90nm',
},

'04' => {
'arch' => 'Gen4',
'pattern' => '4 Series|82[GQ]96[35]|GME?965E?|Bear\s?Lake|Crestline|Santa\s?Rosa',
'code' => '',
'process' => 'Intel 65n',
},
'05' => {
'arch' => 'Gen5',
'pattern' => 'Cantiga|Eagle\s?Lake|Montevina|GMA 4500',
'code' => '',
'process' => 'Intel 45nm',
},
'06' => {
'arch' => 'Gen5.75',
'pattern' => '1st Generation|Iron\s?Lake|Westmere',
'code' => '',
'process' => 'Intel 45nm',
},
# atom d2xxx/n2xxxx released 2012, assuming d2550 at 32nm is this
'07' => {
'arch' => 'Gen6',
'pattern' => '2nd Gen(eration)?|Atom (Processor\s)?(D2\S{3}/N2\S{3}|Z2760)|Sandy\s?Bridge',
'code' => '',
'process' => 'Intel 32nm',
},
'08' => {
'arch' => 'Gen7',
'pattern' => '3rd Gen(eration)?|Ivy\s?Bridge',
'code' => '',
'process' => 'Intel 22nm',
},
'09' => {
'arch' => 'Gen7.5',
'pattern' => '4th Gen(eration)?|Haswell',
'code' => '',
'process' => 'Intel 22nm',
},
'10' => {
'arch' => 'Gen8',
'pattern' => '5th Gen(eration)?|E8000|J3xxx/N3xxx|Broadwell|(HD|Iris|UHD) ((Plus|Pro)\s)?Graphics P?[56]\d{3}',
'code' => '',
'process' => 'Intel 14nm',
},
#  kaby/coffee lake had early and refresh, refresh is 9.5
'11' => {
'arch' => 'Gen9',
'pattern' => '6th Gen(eration)?|N4200|E3900|N3350|Sky\s?lake|(HD|Iris|UHD) ((Plus|Pro)\s)?Graphics P?5\d{2}',
'code' => '',
'process' => 'Intel 14n',
},
'12' => {
'arch' => 'Gen9.5',
'pattern' => '7th Gen(eration)?|(Kaby|Coffee|Comet|Whiskey)\s?Lake|Goldmont (\+|Plus)|(HD|Iris|UHD) ((Plus|Pro)\s)?Graphics P?6\d{2}',
'code' => '',
'process' => 'Intel 14nm',
},

'13' => {
'arch' => 'Gen10',
'pattern' => '8th Gen(eration)?|Cannon\s?Lake',
'code' => 'Gen10',
'process' => 'Intel 10nm',
},
# Intel Xe-LP
'14' => {
'arch' => 'Gen11',
'pattern' => '9th Gen(eration)?|(Ice|Jasper)\s?Lake|Crystal\s?Well|Iris Plus Graphics G7',
'code' => '',
'process' => 'Intel 10nm',
},
'15' => {
'arch' => 'Gen12.1',
'pattern' => 'DG1|Iris Xe (MAX\s)?Graphics|(Rocket|Tiger)\s?Lake',
'code' => '',
'process' => 'Intel 10nm',
},
# Intel Xe 
'16' => {
'arch' => 'Gen12.2',
'pattern' => '10th Gen(eration)?|(Alder)\s?Lake',
'code' => '',
'process' => 'Intel 10nm',
},
'17' => {
'arch' => 'Arctic Sound',
'pattern' => 'Arctic',
'code' => 'Xe-HP/Gen12.5',
'process' => 'Intel 10nm',
},
# cancelled?
'18' => {
'arch' => 'Jupiter Sound',
'pattern' => 'Jupiter',
'code' => '',
'process' => '',
},
},
};

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

sub process {
	foreach my $key (sort keys %$active){
		# say "$active->{$key}{'pattern'}";
		my (@ids);
		if (my @result = grep {/\b($active->{$key}{'pattern'})\b/i} @$data){
			foreach my $item (@result){
				# say $item;
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
			say "\n$line\n$active->{$key}{'arch'}:\n", join("\n",@ids) if $dbg->[1];
			$output{$key} = {'arch' => $active->{$key}{'arch'}, 'ids' => [@ids]};
		}
	}
	say $line,"\n",join("\n",@$data) if @$data && $b_print_remains;
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
	if ($job eq 'amd'){
		$active = $amd_data->{$job};
	}
	elsif ($job eq 'intel'){
		$active = $intel_data->{$job};
	}
	else {
		$active = $nv_data->{$job};
	}
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
	'dbg:s' => sub {
		my ($opt,$arg) = @_;
		if ( $arg !~ /^\d+(,\d+)*$/){
			push(@errors,"Unsupported option for $opt: $arg");
		}
		else {
			foreach (split(/,/,$arg)){
				$dbg->[$_] = 1;
			}
		}
	},
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
	's|sep:s' => sub {
		my ($opt,$arg) = @_;
		if ($arg =~ /^.+$/){
			$sep_global = $arg;
		}
		else {
			push(@errors,"Unsupported option for -$opt:\n  Must be 1 character or more");
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
	say "--dbg [nums]  - comma separated list of debugger triggers:";
	say "                1: Print pci ids list raw before formatted id lists.";
	say "                2: Print raw driver list data before start of processing.";
	say "-h,--help     - This help option menu";
	say "-i,--ids      - Print product/pci ids list raw before formatted id lists.";
	say "-j,--job      - [$options] job selector.";
	say "                Using: $job";
	say "-l,--line-end - [empty|chars] Change line ending per line.";
	say "                Current: '$line_end'";
	say "-p,--plain    - Output single line, no breaks, no quotes or tabs";
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
	say Dumper $data if $dbg->[2];
	die "No \@data returned!" if !@$data;
	process();
	die "No \%output generated!" if !%output;
	output();
}
main();


