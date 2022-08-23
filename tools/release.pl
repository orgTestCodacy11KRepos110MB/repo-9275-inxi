#!/usr/bin/env perl
## This takes the actual raw data, from live pinxi -hy, man2html, and the 
## pinxi.1 man page, stores those values in scalars, then updates the *-temp.htm
## files with the $date/$version below, copies those temp files to the live 
## files, replacing their content, then replaces the '%%%' value with the stored
## data value. This makes HTML page updates trivial and instant.

## Prepare html doc pages for release 
use strict;
use warnings;
# use diagnostics;
use 5.020;

use File::Copy;
use Data::Dumper qw(Dumper); 
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure ('bundling', 'no_ignore_case', 
'no_getopt_compat', 'no_auto_abbrev','pass_through');

my $self_name = 'release.pl';
my $self_version = '1.2';
my $self_date = '2022-08-09';

## Update these to release date and version
my $date = '2022-08-22';
my $version = '3.3.21';

# note: you need to make a symbolic link from real html /docs/ directory to here:
my $dev = "$ENV{'HOME'}/bin/scripts/inxi/svn/branches/inxi-perl/";
my $file_inxi = "$ENV{'HOME'}/bin/scripts/inxi/svn/trunk/inxi";
my $file_pinxi = "${dev}pinxi";
my $file_changelog = "$file_pinxi.changelog";
my $html_changelog = "${dev}smxi.org-docs/inxi-changelog.htm";
my $html_changelog_temp = "${dev}smxi.org-docs/inxi-changelog-temp.htm";
my $html_options="${dev}smxi.org-docs/inxi-options.htm";
my $html_options_temp="${dev}smxi.org-docs/inxi-options-temp.htm";
my $html_man="${dev}smxi.org-docs/inxi-man.htm";
my $html_man_temp="${dev}smxi.org-docs/inxi-man-temp.htm";

my ($b_docs,$b_sync,$b_verify);
my ($changelog_contents,$man_contents,$options_contents,@data);
my $line = '------------------------------------------------------------------';

sub validate_man {
	say $line;
	print "Validating pinxi.1 man page... ";
	my $invalid = qx(LC_ALL=en_US.UTF-8 MANROFFSEQ='' MANWIDTH=80 man --warnings -E UTF-8 -l -Tutf8 -Z $file_pinxi.1 >/dev/null);
	die "\n$file_pinxi.1 is invalid and gave errors!" if $invalid;
	say "man file valid.";
}
sub load_data {
	say $line;
	print "Loading changelog, help, and man data... ";
	$changelog_contents = join("\n",reader($file_changelog));
	die "\n\@changelog raw data empty!" if !$changelog_contents;
	$changelog_contents =~ s/</&lt;/g;
	$changelog_contents =~ s/>/&gt;/g;
	my $cmd = "mman -Thtml ${dev}pinxi.1 | sed -e '/^<!DOCTYPE/,/^<body/{/^<!DOCTYPE/!{/^<body/!d}}' -e '/^<!DOCTYPE/d' -e '/^<body/d'";
	$man_contents = qx($cmd);
	@data = split("\n",$man_contents);
	@data = map {
	$_ =~ s%\s*<br/>%%;
	$_ =~ s%(</body>|</html>)%%;
	$_} @data;
	$man_contents = join("\n",@data);
	die "\n\$man_contents data is empty!" if !$man_contents;
	$options_contents = qx(pinxi -yh | sed 's/pinxi/inxi/g');
	die "\n\$options raw date empty!" if !$options_contents;
	say "data loaded";
}

sub update_temp_files {
	say $line;
	say "Updating -temp.htm files with version/date...";
	foreach my $file (($html_changelog_temp,$html_options_temp,$html_man_temp)){
		@data = reader($file);
		@data = map {
		$_ =~ s/^inxi version: .*/inxi version: $version/;
		$_ =~ s/^inxi date: .*/inxi date: $date/;
		$_} @data;
		writer(\@data,$file);
	}
	say "Files updated.";
}
sub copy_files {
	say $line;
	say "Copying *-temp.htm files to *.htm files...";
	foreach my $temp (($html_changelog_temp,$html_man_temp,$html_options_temp)){
		say " Copying:\n $temp";
		my $file = $temp;
		$file =~ s/-temp//;
		copy($temp,$file) or die " Copy to $file failed...";
	}
	say "Files copied";
}
sub process {
	say $line;
	say "Updating HTML content...";
	my %process = (
	'changelog' => [$html_changelog,$changelog_contents],
	'man' => [$html_man,$man_contents],
	'options' => [$html_options,$options_contents],
	);
	foreach my $key (sort keys %process){
		say "\n Working on $key file...";
		@data = reader($process{$key}->[0]);
		# replace %%% with contents of file
		@data = map {
		if ($_ eq '%%%'){
			$_ = $process{$key}->[1];
		}
		$_;} @data;
		writer(\@data,$process{$key}->[0]);
		say " Done with $key file data.";
	}
	say "Done updating HTML content";
}
# make sure pinxi runs!!
sub verify {
	my $exit_status;
	say $line;
	say "Verifying pinxi comands...";
	print "Testing bad arg: 'pinxi --arg'... ";
	$exit_status = system("$file_pinxi --arg >/dev/null");
	die "\n'pinxi --arg' worked but should have failed!" if !$exit_status;
	say 'passed';
	print "Testing 'pinxi'... ";
	$exit_status = system("$file_pinxi 1>/dev/null");
	die "\n'pinxi' has errors!" if $exit_status;
	say 'passed';
	print "Testing 'pinxi -b'... ";
	$exit_status = system("$file_pinxi -b 1>/dev/null");
	die "\n'pinxi -b' has errors!" if $exit_status;
	say 'passed';
	print "Testing 'pinxi -F'... ";
	$exit_status = system("$file_pinxi -F 1>/dev/null");
	die "\n'pinxi -F' has errors!" if $exit_status;
	say 'passed';
	print "Testing 'pinxi -v8'... ";
	$exit_status = system("$file_pinxi -v8 1>/dev/null");
	die "\n'pinxi -v8' has errors!" if $exit_status;
	say 'passed';
	print "Checking pinxi version against local version: $version... ";
	my @data = reader($file_pinxi);
	foreach (@data){
		if (/^my \$self_version='([^'']+)'/){
			if ($1 ne $version){
				say "\npinxi version $1 does not equal $version!";
				exit 1;
			}
			else {
				say "versions match";
			}
			last;
		}
	}
	say "All pinxi verification tests passed.";
}
sub sync_inxi {
	say $line;
	print "Copying pinxi* files to inxi* files... ";
	copy($file_pinxi,$file_inxi) or die "\nCopy to $file_inxi failed.";
	copy($file_pinxi . '.1',$file_inxi . '.1') or die "\nCopy to $file_inxi.1 failed...";
	copy($file_pinxi . '.changelog',$file_inxi . '.changelog') or die "\nCopy to $file_inxi.changelog failed.";
	say "files copied";
	print "Updating data in inxi... ";
	my $result = qx(sed -E -i -e "s/self_name='pinxi'/self_name='inxi'/" -e "s/self_patch='[0-9]{2}'/self_patch='00'/" $file_inxi);
	say "inxi updated";
	say "Synced pinxi* to inxi*";
}

## TOOLS ##
sub writer {
	my ($data,$file) = @_;
	say " Writing html data to:\n $file";
	open(my $fh, '>', $file) or die "Could not open file '$file' $!";
	print $fh join("\n",@$data);
	close $fh;
	say " Data written.";
}

sub reader {
	my $file = $_[0];
	my @data;
	if (!$file || ! -r $file){
		die "$file does not exist, or is not readable!";
	}
	open(my $fh, '<', $file) or die "Reading $file failed with error: $!";
	chomp(@data = <$fh>);
	close $fh;
	die "\@data had no data!" if !@data;
	return @data;
}
sub options {
	my @errors;
	Getopt::Long::GetOptions (
	'd|docs' => sub {
		$b_docs = 1;
	},
	'h|help' => sub {
		show_options();
		exit 0;
	},
	's|sync' => sub {
		$b_sync = 1;
		$b_verify = 1;
	},
	'v|version' => sub {
		show_version();
		exit 0;
	},
	'V|verify' => sub {
		$b_verify = 1;
	},
	'<>' => sub {
		my ($opt,$arg) = @_;
		push(@errors,"Unsupported option $opt");
	},
	);
	if (!$b_docs && !$b_sync && !$b_verify){
		push(@errors,"-d, -r, -V were not selected. Nothing to do.");
	}
	if ($b_sync && !$b_docs){
		push(@errors,"It is not safe to sync -s without -d updates.");
	}
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
	say "-d,--docs    - Update HTML docs for smxi.org";
	say "-h,--help    - This help option menu";
	say "-s,--sync    - pinxi verification tests, sync and update pinxi* to";
	say "               inxi*. Must use with -d to avoid errors.";
	say "-v,--version - Show tool version and date.";
	say "-V,--verify  - Run pinxi verification tests.";
}
sub show_version {
	say "$self_name v: $self_version date: $self_date";
}
sub finalize {
	say $line;
	say "Ok all done now!";
}
sub main {
	options();
	if ($b_docs){
		validate_man();
		load_data();
		update_temp_files();
		copy_files();
		process();
	}
	if ($b_verify){
		verify();
	}
	if ($b_sync){
		sync_inxi();
	}
	finalize();
}
main();
