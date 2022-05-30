#!/usr/bin/env perl
## cpu_arch.pl: Copyright (C) 2022 Harald Hope
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

my $self_name = 'cpu_arch.pl';
my $self_version = '1.0';
my $self_date = '2022-05-30';

my ($b_log,$end,$start);
my $line = '------------------------------------------------------------------';
my $dbg = [];

my $job = 'amd';
my $options = 'all|amd|centaur|elbrus|intel';
## NOTE: family is hex, model hex, stepping hex, name string
my $tests = {
'amd' => [
{'family' => '6', 'model' => '2', 'stepping' => '0', 'name' => '', },
{'family' => '15', 'model' => '14', 'stepping' => '1', 'name' => '', },
{'family' => '17', 'model' => '8', 'stepping' => '0', 'name' => '', },
{'family' => '19', 'model' => '72', 'stepping' => '1', 'name' => '', },
],
'centaur' => [
{'family' => '5', 'model' => '8', 'stepping' => '', 'name' => '', },
{'family' => '6', 'model' => 'D', 'stepping' => '', 'name' => '', },
{'family' => '', 'model' => '', 'stepping' => '', 'name' => '', },
{'family' => '', 'model' => '', 'stepping' => '', 'name' => '', },
],
'elbrus' => [
{'family' => '4', 'model' => '3', 'stepping' => '', 'name' => '', },
{'family' => '4', 'model' => 'B', 'stepping' => '', 'name' => '', },
{'family' => '5', 'model' => '9', 'stepping' => '', 'name' => '', },
{'family' => '6', 'model' => 'B', 'stepping' => '', 'name' => '', },
],
'intel' => [
{'family' => '6', 'model' => 'F', 'stepping' => '2', 'name' => '', },
{'family' => '6', 'model' => '47', 'stepping' => '', 'name' => '', },
{'family' => '6', 'model' => '55', 'stepping' => '9', 'name' => '', },
{'family' => '6', 'model' => '8E', 'stepping' => '11', 'name' => '', },
{'family' => '', 'model' => '', 'stepping' => '', 'name' => '', },
],
};

sub tester {
	if ($job eq 'all'){
		foreach my $key (sort keys %$tests){
			item($key);
		}
	}
	else {
		item($job);
	}
}
sub item {
	my ($key) = @_;
	foreach my $cpu (@{$tests->{$key}}){
		next if !$cpu->{'family'};
		my $result = cp_cpu_arch(
		$key, $cpu->{'family'}, $cpu->{'model'},$cpu->{'stepping'},$cpu->{'name'}
		);
		say $line;
		say "$key: fam: $cpu->{'family'} mod: $cpu->{'model'} step: $cpu->{'stepping'} name: $cpu->{'name'}";
		foreach my $sub (@$result){
			my $sub = (defined $sub) ? "  val: $sub " : '  val: undef ';
			say $sub;
		}
		# print Dumper $result,
	}
}
tester();

sub message {
	return 'check';
}

## Copy entire block, from start to end cpu arch comments, including comments.

## START CPU ARCH ##
sub cp_cpu_arch {
	eval $start if $b_log;
	my ($type,$family,$model,$stepping,$name) = @_;
	# we can get various random strings for rev/stepping, particularly for arm,ppc
	# but we want stepping to be integer for math comparisons, so convert, or set
	# to 0 so it won't break anything.
	if (defined $stepping && $stepping =~ /^[A-F0-9]{1,3}$/i){
		$stepping = hex($stepping);
	}
	else {
		$stepping = 0
	}
	$family ||= '';
	$model = '' if !defined $model; # model can be 0
	my ($arch,$gen,$note,$process,$year);
	my $check = main::message('note-check');
	# See: docs/inxi-resources.txt 
	# print "type:$type fam:$family model:$model step:$stepping\n";
	if ($type eq 'amd'){
		if ($family eq '3'){
			$arch = 'Am386';
			$process = 'AMD 900-1500nm';
			$year = '1991-92';
		}
		elsif ($family eq '4'){
			if ($model =~ /^(3|7|8|9|A)$/){
				$arch = 'Am486';
				$process = 'AMD 350-700nm';
				$year = '1993-95';}
			elsif ($model =~ /^(E|F)$/){
				$arch = 'Am5x86';
				$process = 'AMD 350nm';
				$year = '1995-99';}
		}
		elsif ($family eq '5'){
			if ($model =~ /^(0|1|2|3)$/){
				$arch = 'K5';
				$process = 'AMD 350-500nm';
				$year = '1996';}
			elsif ($model =~ /^(6|7)$/){
				$arch = 'K6';
				$process = 'AMD ' . ($model eq '6') ? '350nm' : '250nm';
				$year = '1997-98';}
			elsif ($model =~ /^(8)$/){
				$arch = 'K6-2';
				$process = 'AMD 250nm';
				$year = '1998-2003';}
			elsif ($model =~ /^(9|D)$/){
				$arch = 'K6-3';
				$process = 'AMD 180-250nm';
				$year = '1999-2003';}
			elsif ($model =~ /^(A)$/){
				$arch = 'Geode';
				$process = 'AMD 150-350nm';
				$year = '';} # dates uncertain, 1999 start
		}
		elsif ($family eq '6'){
			if ($model =~ /^(1|2)$/){
				$arch = 'K7 Athlon Classic';
				$process = 'AMD 180-250nm';
				$year = '1999-2002';}
			elsif ($model =~ /^(3|4)$/){
				$arch = 'K7 Thunderbird';
				$process = 'AMD 180nm';
				$year = '2000-01';}
			elsif ($model =~ /^(6|7|8|A)$/){
				$arch = 'K7 Palomino+'; # athlon xp
				$process = 'AMD 130-180nm';
				$year = '2001';}
			else {
				$arch = 'K7';
				$process = 'AMD 130-250nm';
				$year = '';}
		}
		elsif ($family eq 'F'){
			if ($model =~ /^(4|5|7|8|B|C|E|F|14|15|17|18|1B|1C|1F)$/){
				$arch = 'K8';
				$process = 'AMD 65-130nm';
				$year = '';}
			elsif ($model =~ /^(21|23|24|25|27|28|2C|2F)$/){
				$arch = 'K8 rev.E';
				$process = 'AMD 65-130nm';
				$year = '';}
			elsif ($model =~ /^(41|43|48|4B|4C|4F|5D|5F|68|6B|6C|6F|7C|7F|C1)$/){
				$arch = 'K8 rev.F+';
				$process = 'AMD 65-130nm';
				$year = '';}
			else {
				$arch = 'K8';
				$process = 'AMD 65-130nm';
				$year = '';}
		}
		elsif ($family eq '10'){
			if ($model =~ /^(2|4|5|6|8|9|A)$/){
				$arch = 'K10';
				$process = 'AMD 32-65nm';
				$year = '2007-12';}
			else {
				$arch = 'K10';
				$process = 'AMD 32-65nm';
				$year = '2007-12';}
		}
		# very loose, all stepping 1: covers athlon x2, sempron, turion x2
		# years unclear, could be 2005 start, or 2008
		elsif ($family eq '11'){
			if ($model =~ /^(3)$/){
				$arch = 'Athlon X2/Turion X2'; # unclear: K8 or K10
				$note = $check;
				$process = 'AMD 45-90nm';
				$year = ''; } 
		}
		# might also need cache handling like 14/16
		elsif ($family eq '12'){
			if ($model =~ /^(1)$/){
				$arch = 'Fusion';
				$process = 'GF 32nm';
				$year = '';}
			else {
				$arch = 'Fusion';
				$process = 'GF 32nm';
				$year = '';}
		}
		# SOC, apu
		elsif ($family eq '14'){
			if ($model =~ /^(1|2)$/){
				$arch = 'Bobcat';
				$process = 'GF 40nm';
				$year = '2011-13';}
			else {
				$arch = 'Bobcat';
				$process = 'GF 40nm';
				$year = '2011-13';}
		}
		elsif ($family eq '15'){
			# note: only model 1 confirmd
			if ($model =~ /^(0|1|3|4|5|6|7|8|9|A|B|C|D|E|F)$/){
				$arch = 'Bulldozer';
				$process = 'GF 32nm';
				$year = '2011';}
			# note: only 2,11,13 confirmed
			elsif ($model =~ /^(2|10|11|12|13|14|15|16|17|18|19|1A|1B|1C|1D|1E|1F)$/){
				$arch = 'Piledriver';
				$process = 'GF 32nm';
				$year = '2012-13';}
			# note: only 30,38 confirmed
			elsif ($model =~ /^(30|31|32|33|34|35|36|37|38|39|3A|3B|3C|3D|3E|3F)$/){
				$arch = 'Steamroller';
				$process = 'GF 28nm';
				$year = '2014';}
			# note; only 60,65,70 confirmed
			elsif ($model =~ /^(60|61|62|63|64|65|66|67|68|69|6A|6B|6C|6D|6E|6F|70|71|72|73|74|75|76|77|78|79|7A|7B|7C|7D|7E|7F)$/){
				$arch = 'Excavator';
				$process = 'GF 28nm';
				$year = '2015';}
			else {
				$arch = 'Bulldozer';
				$process = 'GF 32nm';
				$year = '2011-12';}
		}
		# SOC, apu
		elsif ($family eq '16'){
			if ($model =~ /^(0|1|2|3|4|5|6|7|8|9|A|B|C|D|E|F)$/){
				$arch = 'Jaguar';
				$process = 'GF 28nm';
				$year = '2013-14';}
			elsif ($model =~ /^(30|31|32|33|34|35|36|37|38|39|3A|3B|3C|3D|3E|3F)$/){
				$arch = 'Puma';
				$process = 'GF 28nm';
				$year = '2014-15';}
			else {
				$arch = 'Jaguar';
				$process = 'GF 28nm';
				$year = '2013-14';}
		}
		elsif ($family eq '17'){
			# can't find stepping/model for no ht 2x2 core/die models, only first ones
			if ($model =~ /^(1|11|20)$/){
				$arch = 'Zen';
				$process = 'GF 14nm';
				$year = '2017-19';}
			# Seen: stepping 1 is Zen+ Ryzen 7 3750H. But stepping 1 Zen is: Ryzen 3 3200U
			# AMD Ryzen 3 3200G is stepping 1, Zen+
			# Unknown if stepping 0 is Zen or either.
			elsif ($model =~ /^(18)$/){
				$arch = 'Zen/Zen+';
				$gen = '1';
				$process = 'GF 12nm';
				$note = $check;
				$year = '2019';}
			# shares model 8 with zen, stepping unknown
			elsif ($model =~ /^(8)$/){
				$arch = 'Zen+';
				$gen = '2';
				$process = 'GF 12nm';
				$year = '2018-21';}
			# used this but it didn't age well:  ^(2[0123456789ABCDEF]|
			elsif ($model =~ /^(31|47|60|68|71|90)$/){
				$arch = 'Zen 2';
				$gen = '3';
				$process = 'TSMC n7 (7nm)'; # some consumer maybe GF 14nm
				$year = '2020-22';}
			else {
				$arch = 'Zen';
				$note = $check;
				$process = '7-14nm';
				$year = '';}
		}
		# Joint venture between AMD and Chinese companies. Type amd? or hygon?
		elsif ($family eq '18'){
			# model 0, zen 1 
			$arch = 'Zen (Hygon Dhyana)';
			$gen = '1';
			$process = 'GF 14nm';
			$year = '';}
		elsif ($family eq '19'){
			# ext model 7,8, but no base models yet
			# 10 engineering sample
			if ($model =~ /^(10|7\d|8\d)$/){
				$arch = 'Zen 4';
				$gen = '5';
				$process = 'TSMC n5 (5nm)';
				$year = '2022';}
			# double check 40, 44
			elsif ($model =~ /^(40|44)$/){
				$arch = 'Zen 3+';
				$gen = '4';
				$process = 'TSMC n6 (7nm)';
				$year = '2022';}
			# 21, 50: step 0; 
			elsif ($model =~ /^(0|1|8|21|50)$/){
				$arch = 'Zen 3';
				$gen = '4';
				$process = 'TSMC n7 (7nm)';
				$year = '2021-22';}
			else {
				$arch = 'Zen 3/4';
				$note = $check;
				$process = 'TSMC n5 (5nm)-7';
				$year = '2021-22';}
			# Zen 5: TSCM n3
		}
	}
	elsif ($type eq 'arm'){
		if ($family ne ''){
			$arch="ARMv$family";}
		else {
			$arch='ARM';}
	}
# 	elsif ($type eq 'ppc'){
# 		$arch='PPC';
# 	}
	# aka VIA
	elsif ($type eq 'centaur'){ 
		if ($family eq '5'){
			if ($model =~ /^(4)$/){
				$arch = 'WinChip C6';
				$process = '250nm';
				$year = '';}
			elsif ($model =~ /^(8)$/){
				$arch = 'WinChip 2';
				$process = '250nm';
				$year = '';}
			elsif ($model =~ /^(9)$/){
				$arch = 'WinChip 3';
				$process = '250nm';
				$year = '';}
		}
		elsif ($family eq '6'){
			if ($model =~ /^(6)$/){
				$arch = 'WinChip-based';
				$process = '150nm'; # guess
				$year = '';}
			elsif ($model =~ /^(7|8)$/){
				$arch = 'C3';
				$process = '150nm';
				$year = '';}
			elsif ($model =~ /^(9)$/){
				$arch = 'C3-2';
				$process = '130nm';
				$year = '';}
			elsif ($model =~ /^(A|D)$/){
				$arch = 'C7';
				$process = '90nm';
				$year = '';}
			elsif ($model =~ /^(F)$/){
				$arch = 'Isaiah';
				$process = '90nm'; # guess
				$year = '';} 
		}
	}
	# note, to test uncoment $cpu{'type'} = Elbrus in proc/cpuinfo logic
	elsif ($type eq 'elbrus'){ 
		# E8CB
		if ($family eq '4'){
			if ($model eq '1'){
				$arch = 'Elbrus';
				$process = '';
				$year = '';}
			elsif ($model eq '2'){
				$arch = 'Elbrus-S';
				$process = '';
				$year = '';}
			elsif ($model eq '3'){
				$arch = 'Elbrus-4C';
				$process = '65nm';
				$year = '';}
			elsif ($model eq '4'){
				$arch = 'Elbrus-2C+';
				$process = '90nm';
				$year = '';}
			elsif ($model eq '6'){
				$arch = 'Elbrus-2CM';
				$process = '90nm';
				$year = '';}
			elsif ($model eq '7'){
				if ($stepping >= 2){
					$arch = 'Elbrus-8C1';
					$process = '28nm';
					$year = '';}
				else {
					$arch = 'Elbrus-8C';
					$process = '28nm';
					$year = '';}
			} # note: stepping > 1 may be 8C1
			elsif ($model eq '8'){
				$arch = 'Elbrus-1C+';
				$process = 'TSMC 40nm';
				$year = '';}
			# 8C2 morphed out of E8CV, but the two were the same die
			elsif ($model eq '9'){
				$arch = 'Elbrus-8CV/8C2';
				$process = 'TSMC 28nm';
				$note = $check;
				$year = '';}
			elsif ($model eq 'A'){
				$arch = 'Elbrus-12C';
				$process = 'TSMC 16nm'; # guess
				$year = '';}
			elsif ($model eq 'B'){
				$arch = 'Elbrus-16C';
				$process = 'TSMC 16nm';
				$year = '';}
			elsif ($model eq 'C'){
				$arch = 'Elbrus-2C3';
				$process = 'TSMC 16nm';
				$year = '';}
			else {
				$arch = 'Elbrus-??';;
				$year = '';
				$note = $check;
				$year = '';}
		}
		elsif ($family eq '5'){
			if ($model eq '9'){
				$arch = 'Elbrus-8C2';
				$process = 'TSMC 28nm';
				$year = '';}
			else {
				$arch = 'Elbrus-??';
				$note = $check;
				$process = '';
				$year = '';}
		}
		elsif ($family eq '6'){
			if ($model eq 'A'){
				$arch = 'Elbrus-12C';
				$process = 'TSMC 16nm'; # guess
				$year = '';}
			elsif ($model eq 'B'){
				$arch = 'Elbrus-16C';
				$process = 'TSMC 16nm';
				$year = '';}
			elsif ($model eq 'C'){
				$arch = 'Elbrus-2C3';
				$process = 'TSMC 16nm';
				$year = '';}
			else {
				$arch = 'Elbrus-??';
				$note = $check;
				$process = '';
				$year = '';}
		}
		else {
			$arch = 'Elbrus-??';
			$note = $check;
		}
	}
	elsif ($type eq 'intel'){
		if ($family eq '4'){
			if ($model =~ /^(0|1|2|3|4|5|6|7|8|9)$/){
				$arch = '486';
				$process = '600-1000nm';
				$year = '';}
		}
		elsif ($family eq '5'){
			if ($model =~ /^(1|2|3|7)$/){
				$arch = 'P5';
				$process = 'Intel 350-800nm';
				$year = '';}
			elsif ($model =~ /^(4|8)$/){
				$arch = 'P5';
				$process = 'Intel 350-800nm'; # MMX
				$year = '';}
			elsif ($model =~ /^(9|A)$/){
				$arch = 'Lakemont';
				$process = 'Intel 350-800nm';
				$year = '';}
		}
		elsif ($family eq '6'){
			if ($model =~ /^(1)$/){
				$arch = 'P6 Pro';
				$process = 'Intel 350nm';
				$year = '';}
			elsif ($model =~ /^(3)$/){
				$arch = 'P6 II Klamath';
				$process = 'Intel 350nm';
				$year = '';}
			elsif ($model =~ /^(5)$/){
				$arch = 'P6 II Deschutes';
				$process = 'Intel 250nm';
				$year = '';}
			elsif ($model =~ /^(6)$/){
				$arch = 'P6 II Mendocino';
				$process = 'Intel 250nm';
				$year = '';}
			elsif ($model =~ /^(7)$/){
				$arch = 'P6 III Katmai';
				$process = 'Intel 250nm';
				$year = '1999';}
			elsif ($model =~ /^(8)$/){
				$arch = 'P6 III Coppermine';
				$process = 'Intel 180nm';
				$year = '1999';}
			elsif ($model =~ /^(9)$/){
				$arch = 'M Banias'; # Pentium M
				$process = 'Intel 130nm';
				$year = '2003';}
			elsif ($model =~ /^(A)$/){
				$arch = 'P6 III Xeon';
				$process = 'Intel 180-250nm';
				$year = '1999';}
			elsif ($model =~ /^(B)$/){
				$arch = 'P6 III Tualitin';
				$process = 'Intel 130nm';
				$year = '2001';}
			elsif ($model =~ /^(D)$/){
				$arch = 'M Dothan'; # Pentium M
				$process = 'Intel 90nm';
				$year = '2003-05';}
			elsif ($model =~ /^(E)$/){
				$arch = 'M Yonah';
				$process = 'Intel 65nm';
				$year = '2006-08';}
			elsif ($model =~ /^(F|16)$/){
				$arch = 'Core2 Merom';
				$process = 'Intel 65nm';
				$year = '2006-09';}
			elsif ($model =~ /^(15)$/){
				$arch = 'M Tolapai'; # pentium M system on chip
				$process = 'Intel 90nm';
				$year = '2008';} 
			elsif ($model =~ /^(1D)$/){
				$arch = 'Penryn';
				$process = 'Intel 45nm';
				$year = '2007-08';}
			elsif ($model =~ /^(17)$/){
				$arch = 'Penryn Yorkfield';
				$process = 'Intel 45nm';
				$year = '2008';}
			# had 25 also, but that's westmere, at least for stepping 2
			elsif ($model =~ /^(1A|1E|1F|2C|2E|2F)$/){
				$arch = 'Nehalem';
				$process = 'Intel 45nm';
				$year = '2008-10';}
			elsif ($model =~ /^(1C|26)$/){
				$arch = 'Bonnell';
				$process = 'Intel 45nm';
				$year = '2008-13';} # atom Bonnell? 27?
			# 25 may be nahelem in a stepping, check. Stepping 2 is westmere
			elsif ($model =~ /^(25|2C|2F)$/){
				$arch = 'Westmere'; # die shrink of nehalem
				$process = 'Intel 32nm';
				$year = '2010-11';}
			elsif ($model =~ /^(27|35|36)$/){
				$arch = 'Saltwell';
				$process = 'Intel 32nm';
				$year = '2011-13';}
			elsif ($model =~ /^(2A|2D)$/){
				$arch = 'Sandy Bridge';
				$process = 'Intel 32nm';
				$year = '2010-12';}
			elsif ($model =~ /^(37|4A|4D|5A|5D)$/){
				$arch = 'Silvermont';
				$process = 'Intel 22nm';
				$year = '2013-15';}
			elsif ($model =~ /^(3A|3E)$/){
				$arch = 'Ivy Bridge';
				$process = 'Intel 22nm';
				$year = '2012-15';}
			elsif ($model =~ /^(3C|3F|45|46)$/){
				$arch = 'Haswell';
				$process = 'Intel 22nm';
				$year = '2013-15';}
			elsif ($model =~ /^(3D|47|4F|56)$/){
				$arch = 'Broadwell';
				$process = 'Intel 14nm';
				$year = '2015-18';}
			elsif ($model =~ /^(4C)$/){
				$arch = 'Airmont';
				$process = 'Intel 14nm';
				$year = '2015-17';}
			elsif ($model =~ /^(4E)$/){
				$arch = 'Skylake';
				$process = 'Intel 14nm';
				$year = '2015';} 
			# need to find stepping for these, guessing stepping 4 is last for SL
			elsif ($model =~ /^(55)$/){
				if ($stepping >= 5 && $stepping <= 7){
					$arch = 'Cascade Lake';
					$process = 'Intel 14nm';
					$year = '2019';}
				elsif ($stepping >= 8){
					$arch = 'Cooper Lake';
					$process = 'Intel 14nm';
					$year = '2020';}
				else {
					$arch = 'Skylake';
					$process = 'Intel 14nm';
					$year = '';}}
			elsif ($model =~ /^(57)$/){
				$arch = 'Knights Landing';
				$process = 'Intel 14nm';
				$year = '2016+';}
			elsif ($model =~ /^(5C|5F)$/){
				$arch = 'Goldmont';
				$process = 'Intel 14nm';
				$year = '2016';}
			elsif ($model =~ /^(5E)$/){
				$arch = 'Skylake-S';
				$process = 'Intel 14nm';
				$year = '2015';}
			elsif ($model =~ /^(66)$/){
				$arch = 'Cannon Lake';
				$process = 'Intel 10nm';
				$year = '2018';}
			# 6 are servers, 7 not
			elsif ($model =~ /^(6A|6C|7D|7E)$/){
				$arch = 'Ice Lake';
				$process = 'Intel 10nm';
				$year = '2019-21';}
			elsif ($model =~ /^(7A)$/){
				$arch = 'Goldmont Plus';
				$process = 'Intel 14nm';
				$year = '2017';} 
			elsif ($model =~ /^(85)$/){
				$arch = 'Knights Mill';
				$process = 'Intel 14nm';
				$year = '2017-19';}
			elsif ($model =~ /^(8A|96|9C)$/){
				$arch = 'Tremont';
				$process = 'Intel 10nm';
				$year = '2019';}
			elsif ($model =~ /^(8C|8D)$/){
				$arch = 'Tiger Lake';
				$process = 'Intel 10nm';
				$year = '2020';}
			elsif ($model =~ /^(8E)$/){
				# can be AmberL or KabyL
				if ($stepping == 9){
					$arch = 'Amber/Kaby Lake';
					$note = $check;
					$process = 'Intel 14nm';
					$year = '2017';}
				elsif ($stepping == 10){
					$arch = 'Coffee Lake';
					$process = 'Intel 14nm';
					$year = '2017';}
				elsif ($stepping == 11){
					$arch = 'Whiskey Lake';
					$process = 'Intel 14nm';
					$year = '2018';}
				# can be WhiskeyL or CometL
				elsif ($stepping == 12){
					$arch = 'Comet/Whiskey Lake';
					$note = $check;
					$process = 'Intel 14nm';
					$year = '2018';}
				# note: had it as > 13, but 0xC seems to be CL
				elsif ($stepping >= 13){
					$arch = 'Comet Lake'; # guess, have not seen docs yet
					$process = 'Intel 14nm';
					$year = '2019-20';}
				# NOTE: not enough info to lock this down
				else {
					$arch = 'Kaby Lake';
					$note = $check;
					$process = 'Intel 14nm';
					$year = '~2018-20';} 
			}
			elsif ($model =~ /^(8F)$/){
				$arch = 'Sapphire Rapids';
				$process = 'Intel 7 (10nm ESF)';
				$year = '2021';} # server
			elsif ($model =~ /^(97|9A)$/){
				$arch = 'Alder Lake';
				$process = 'Intel 7 (10nm ESF)';
				$year = '2021';}
			## IDS UNKNOWN, release late 2022
			# elsif ($model =~ /^()$/){
			#	$arch = 'Raptor Lake'; #
			#	$process = 'Intel 7 (10nm)';}
			# elsif ($model =~ /^()$/){
			#	$arch = 'Meteor Lake';
			#	$process = 'Intel 4';}
			# Granite Rapids: INtel 3 (7nm)
			elsif ($model =~ /^(9E)$/){
				if ($stepping == 9){
					$arch = 'Kaby Lake';
					$process = 'Intel 14nm';
					$year = '2018';}
				elsif ($stepping >= 10 && $stepping <= 13){
					$arch = 'Coffee Lake';
					$process = 'Intel 14nm';
					$year = '2018';}
				else {
					$arch = 'Kaby Lake';
					$note = $check;
					$process = 'Intel 14nm';
					$year = '2018';} 
			}
			elsif ($model =~ /^(A5)$/){
				$arch = 'Comet Lake'; # stepping 0-5
				$process = 'Intel 14nm';
				$year = '2020';}
			elsif ($model =~ /^(A7)$/){
				$arch = 'Rocket Lake'; # stepping 1
				$process = 'Intel 14nm';
				$year = '2021+';} 
			# More info: comet: shares family/model, need to find stepping numbers
			# Coming: meteor lake; granite rapids; diamond rapids
		}
		# itanium 1 family 7 all recalled
		elsif ($family eq 'B'){
			if ($model =~ /^(0)$/){
				$arch = 'Knights Ferry';
				$process = 'Intel 45nm';
				$year = '2010-11';}
			if ($model =~ /^(1)$/){
				$arch = 'Knights Corner';
				$process = 'Intel 22nm';
				$year = '2012-13';}
		}
		# pentium 4
		elsif ($family eq 'F'){
			if ($model =~ /^(0|1)$/){
				$arch = 'Netburst Willamette';
				$process = 'Intel 180nm';
				$year = '2000-01';}
			elsif ($model =~ /^(2)$/){
				$arch = 'Netburst Northwood';
				$process = 'Intel 130nm';
				$year = '2002-03';}
			elsif ($model =~ /^(3)$/){
				$arch = 'Netburst Prescott';
				$process = 'Intel 90nm';
				$year = '2004-06';} # 6? Nocona
			elsif ($model =~ /^(4)$/){
				if ($stepping == 1){
					$arch = 'Netburst Prescott';
					$process = 'Intel 90nm';
					$year = '2004-06';} 
				else {
					$arch = 'Netburst Smithfield';
					$process = 'Intel 90nm';
					$year = '2005-06';} # 6? Nocona
			}
			elsif ($model =~ /^(6)$/){
				$arch = 'Netburst Presler';
				$process = 'Intel 65nm';
				$year = '2006';}
			else {
				$arch = 'Netburst';
				$process = 'Intel 90-180nm';
				$year = '2000-06';}
		}
		# this is not going to e accurate, WhiskyL or Kaby L can ID as Skylake
		# but if it's a new cpu microarch not handled yet, it may give better 
		# than nothing result. This is intel only
		# This is probably the gcc/clang -march/-mtune value, which is not 
		# necessarily the same as actual microarch, and varies between gcc/clang versions
		if (!$arch){
			my $file = '/sys/devices/cpu/caps/pmu_name';
			$arch = main::reader($file,'strip',0) if -r $file;
			$note = $check if $arch;
		}
		# gen 1 had no gen, only 3 digits: Core i5-661 Core i5-655K; Core i5 M 520
		# EXCEPT gen 1: Core i7-720QM Core i7-740QM Core i7-840QM
		# 2nd: Core i5-2390T Core i7-11700F Core i5-8400
		if ($name){
			if ($name =~ /\bi[357][\s-]([A-Z][\s-]?)?(\d{3}([^\d]|\b)|[78][24]00M)/){
				$gen = ($gen) ? "$gen (core 1)": 'core 1';
			}
			elsif ($name =~ /\bi[3579][\s-]([A-Z][\s-]?)?([2-9]|1[0-4])\d{3}/){
				$gen = ($gen) ? "$gen (core $1)" : "core $1";
			}
		}
	}
	eval $end if $b_log;
	return [$arch,$note,$process,$gen,$year];
}
## END CPU ARCH ##

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
	say "-h,--help     - This help option menu";
	say "-j,--job      - [$options] job selector.";
	say "                Using: $job";
	say "-v,--version  - Show tool version and date.";
}
sub show_version {
	say "$self_name v: $self_version date: $self_date";
}
sub main {
	options();
	tester();
}
main();
