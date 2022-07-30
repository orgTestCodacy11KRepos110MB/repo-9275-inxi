#!/usr/bin/env perl
## ram_vendors.pl: Copyright (C) 2022 Harald Hope
## 
## License: GNU GPL v3 or greater
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
## If you don't understand what Free Software is, please read (or reread)
## this page: http://www.gnu.org/philosophy/free-sw.html
##
## This tool is what is used to create the disk vendor data. It uses a huge set 
## of raw disk data, and tests the set_vendors() matching tables against that 
## list. You can extend that list simply be adding the full disk name string 
## into the list, specify USB: or non as you'll see inthe disks.txt file.
## Because of the nature of disk names, there's always going be a big set that
## cannot be matched, but overall the results using this method are quite good.

use strict;
use warnings;
# use diagnostics;
use 5.010;

use Data::Dumper qw(Dumper); 
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure ('bundling', 'no_ignore_case', 
'no_getopt_compat', 'no_auto_abbrev','pass_through');

my $self_name = 'ram_vendors.pl';
my $self_version = '1.0';
my $self_date = '2022-05-30';

my ($b_log,$end,$start);
my ($vendors,$vendor_ids);
my $line = '------------------------------------------------------------------';
my $dbg = [];

my $job = '';
my $options = '';

# no testing samples yet, fill in as needed.
# [0]: string to test, [1]: vendor ID
my $tests = [
['',''],
['',''],
['',''],
['',''],
['',''],
];

## Copy entire block, from start to end ram vendor comments, including comments.

## START RAM VENDOR ##
sub set_ram_vendors {
	$vendors = [
	# A-Data xpg: AX4U; AX\d{4} for axiom
	['^(A[DX]\dU|AVD|A[\s-]?Data)','A[\s-]?Data','A-Data',''],
	['^(A[\s-]?Tech)','A[\s-]?Tech','A-Tech',''], # don't know part nu
	['^(AX[\d]{4}|Axiom)','Axiom','Axiom',''],
	['^(BD\d|Black[s-]?Diamond)','Black[s-]?Diamond','Black Diamond',''],
	['^(-BN$|Brute[s-]?Networks)','Brute[s-]?Networks','Brute Networks',''],
	['^(CM|Corsair)','Corsair','Corsair',''],
	['^(CT\d|BL|Crucial)','Crucial','Crucial',''],
	['^(CY|Cypress)','Cypress','Cypress',''],
	['^(SNP|Dell)','Dell','Dell',''],
	['^(PE[\d]{4}|Edge)','Edge','Edge',''],
	['^(Elpida|EB)','^Elpida','Elpida',''],
	['^(GVT|Galvantech)','Galvantech','Galvantech',''],
	# if we get more G starters, make rules tighter
	['^(G[A-Z]|Geil)','Geil','Geil',''],
	# Note: FA- but make loose FA
	['^(F4|G[\s\.-]?Skill)','G[\s\.-]?Skill','G.Skill',''], 
	['^(HP)','','HP',''], # no IDs found
	['^(HX|HyperX)','HyperX','HyperX',''],
	# qimonda spun out of infineon, same ids
	# ['^(HYS]|Qimonda)','Qimonda','Qimonda',''],
	['^(HY|Infineon)','Infineon','Infineon',''],#HY[A-Z]\d
	['^(KSM|KVR|Kingston)','Kingston','Kingston',''],
	['^(LuminouTek)','LuminouTek','LuminouTek',''],
	['^(MT|Micron)','Micron','Micron',''],
	# seen: 992069 991434 997110S
	['^(M[BLERS][A-Z][1-7]|99[0-9]{3}|Mushkin)','Mushkin','Mushkin',''],
	['^(OCZ)','^OCZ\b','OCZ',''],
	['^([MN]D\d|OLOy)','OLOy','OLOy',''],
	['^(M[ERS]\d|Nemix)','Nemix','Nemix',''],
	# before patriot just in case
	['^(MN\d|PNY)','PNY\s','PNY',''],
	['^(P[A-Z]|Patriot)','Patriot','Patriot',''],
	['^(K[1-6][ABT]|K[1-6][\d]{3}|M[\d]{3}[A-Z]|Samsung)','Samsung','Samsung',''],
	['^(SP|Silicon[\s-]?Power)','Silicon[\s-]?Power','Silicon Power',''],
	['^(STK|Simtek)','Simtek','Simtek',''],
	['^(HM[ACT]|SK[\s-]?Hynix)','SK[\s-]?Hynix','SK-Hynix',''],
	# TED TTZD TLRD TDZAD TF4D4 TPD4 TXKD4 seen: HMT but could by skh
	#['^(T(ED|D[PZ]|F\d|LZ|P[DR]T[CZ]|XK)|Team[\s-]?Group)','Team[\s-]?Group','TeamGroup',''],
	['^(T[^\dR]|Team[\s-]?Group)','Team[\s-]?Group','TeamGroup',''],
	['^(TR\d|JM\d|Transcend)','Transcend','Transcend',''],
	['^(VK\d|Vaseky)','Vaseky','Vaseky',''],
	['^(Yangtze|Zhitai|YMTC)','Yangtze(\s*Memory)?','Yangtze Memory',''],
	];
}
# note: many of these are pci ids, not confirmed valid for ram
sub set_ram_vendor_ids {
	$vendor_ids = {
	'01f4' => 'Transcend',# confirmed
	'02fe' => 'Elpida',# confirmed
	'0314' => 'Mushkin',# confirmed
	'0420' => 'Chips and Technologies',
	'1014' => 'IBM',
	'1099' => 'Samsung',
	'10c3' => 'Samsung',
	'11e2' => 'Samsung',
	'1249' => 'Samsung',
	'144d' => 'Samsung',
	'15d1' => 'Infineon',
	'167d' => 'Samsung',
	'196e' => 'PNY',
	'1b1c' => 'Corsair',
	'1b85' => 'OCZ',
	'1c5c' => 'SK-Hynix',
	'1cc1' => 'A-Data',
	'1e49' => 'Yangtze Memory',# confirmed
	'0215' => 'Corsair',# confirmed
	'2646' => 'Kingston',
	'2c00' => 'Micron',# confirmed
	'5105' => 'Qimonda',# confirmed
	'802c' => 'Micron',# confirmed
	'80ad' => 'SK-Hynix',# confirmed
	'80ce' => 'Samsung',# confirmed
	'8551' => 'Qimonda',# confirmed
	'8564' => 'Transcend',
	'ad00' => 'SK-Hynix',# confirmed
	'c0a9' => 'Crucial',
	'ce00' => 'Samsung',# confirmed
	# '' => '',
	}
}
## END RAM VENDOR ##

sub ram_vendor {
	eval $end if $b_log;
	my ($id) = $_[0];
	set_ram_vendors() if !$vendors;
	my ($vendor);
	foreach my $row (@$vendors){
		if ($id =~ /$row->[0]/i){
			$vendor = $row->[2];
			# Usually we want to assign N/A at output phase, maybe do this logic there?
			if ($row->[1]){
				if ($id !~ m/$row->[1]$/i){
					$id =~ s/$row->[1]//i;
				}
				else {
					$id = 'N/A';
				}
			}
			$id =~ s/^[\/\[\s_-]+|[\/\s_-]+$//g;
			$id =~ s/\s\s/ /g;
			last;
		}
	}
	eval $end if $b_log;
	return [$vendor,$id];
}

## start tool logic
sub process {
	set_ram_vendor_ids();
	say "Starting ram vendor / model tests.";
	say $line;
	foreach my $item (@$tests){
		next if !$item->[0];
		my $result = ram_vendor($item->[0]);
		if ($result->[0]){
			say "Match found for $item->[0]:";
			say "  vendor: $result->[0]";
			say "  model: $result->[1]";
		}
		else {
			say "No result found for: $item->[0]";
		}
	}
	say $line;
	say "Complated tests.";
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
	say "                none yet";
	say "-h,--help     - This help option menu";
	say "-v,--version  - Show tool version and date.";
}
sub show_version {
	say "$self_name v: $self_version date: $self_date";
}
sub main {
	options();
	process();
}
main();
