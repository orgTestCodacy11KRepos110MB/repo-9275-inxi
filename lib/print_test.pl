#!/usr/bin/env perl
## File: print_test.pl
## Version: 1.0
## Date 2018-03-12
## License: GNU GPL v3 or greater
## Copyright (C) 2018 Harald Hope

use strict;
use warnings;
use 5.008;
use Data::Dumper qw(Dumper); # print_r

### START DEFAULT CODE ##

my $self_name='pinxi';
my $self_version='2.9.00';
my $self_date='2018-01-07';
my $self_patch='086-p';

my $prefix = 0; # for the primiary row hash key prefix

sub generate_test_data {
	eval $start if $b_log;
	my %data = (
	$prefix++ . '#System' => [
		{
		'1#Host' => 'fred',
		'02#Kernel' => '4.9.0-3.1-liquorix-686-pae i686',
		'3#bits' => '32',
		'4#gcc' => '6.2.1',
		},
		{
		'5#Desktop' => 'Xfce 4.12.3 (Gtk 2.24.31)',
		'6#info' => 'xfce4-panel',
		'7#dm' => 'lightdm',
		'08#Distro' => 'sidux-20070102-d:1',
		},
		
	],
	$prefix++ . '#CPU' => [
		{
		"0#CPU flags" => '3dnow 3dnowext 3dnowprefetch apic clflush cmov 
		cmp_legacy cr8_legacy cx16 cx8 de eagerfpu extapic extd_apicid fpu
		fxsr fxsr_opt ht lahf_lm lbrv lm mca mce mmx mmxext msr mtrr nx pae
		pat pge pni pse pse36 rdtscp rep_good sep sse sse2 svm syscall tsc
		vme vmmcall',
		},
	],
	$prefix++ . '#Network' => [
		{
		'0#Card' => 'Realtek RTL8101/2/6E PCI Express Fast/Gigabit Ethernet controller',
		'1#driver' => 'r8169',
		'2#v' => '2.3LK-NAPI',
		'3#port' => '2000',
		'4#bus-ID' => '02:00.0',
		'5#chip-ID' => '10ec:8136 fred bob george same gus byron henry george gus fred sandy jeff',
		},
		{
		'0#IF' => 'enp2s0',
		'1#state' => 'up',
		'2#speed' => '100 Mbps',
		'3#duplex' => 'full',
		'4#mac' => '00:23:8b:cd:27:82',
		},
		{
		'0#Card' => 'Realtek RTL8187B Wireless 802.11g 54Mbps Network Adapter',
		'1#usb-ID' => '001-003',
		'2#chip-ID' => '0bda:8189',
		},
		{
		'1#IF' => 'null-if-id',
		'2#state' => 'N/A',
		'3#mac' => 'N/A',
		},
	],
	$prefix++ . '#Repos' => [
		{
		'0#Active apt sources in file' => '/etc/apt/sources.list',
		},
		[
		'deb http: //mirrors.kernel.org/debian unstable main contrib non-free',
		'deb http: //mirrors.kernel.org/debian buster main contrib non-free',
		'deb http: //www.deb-multimedia.org/ buster main non-free',
		'deb http: //deb.opera.com/opera-stable stable non-free',
		'deb http: //liquorix.net/debian unstable main',
		],
		{
		'0#Active apt sources in file' => '/etc/apt/sources.list.d/google-earth.list',
		},
		[
		'deb http: //dl.google.com/linux/earth/deb/ stable main',
		],
	],);
	eval $end if $b_log;
	return %data;
}

my %row = generate_test_data();

## From generate_lines()
# 	if ($test[3]){
# 		%row = generate_test_data();
# 		assign_data(%row);
# 		return 1;
# 	}
