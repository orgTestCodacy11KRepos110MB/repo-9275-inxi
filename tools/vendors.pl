#!/usr/bin/env perl
## vendors.pl: Copyright (C) 2022 Harald Hope
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
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure ('bundling', 'no_ignore_case', 
'no_getopt_compat', 'no_auto_abbrev','pass_through');

my (@data);

my $self_name = 'vendors.pl';
my $self_version = '1.0';
my $self_date = '2022-05-17';

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
	say "-v,--version - show tool version and date.";
}
sub show_version {
	say "$self_name v: $self_version date: $self_date";
}

sub main {
	options();
}

main();
