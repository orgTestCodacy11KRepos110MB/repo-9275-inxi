## Changes to Parse::EDID 

## top, switched all _group_by2, which are pointless and an extra step, to 
## explicit sets of array references, without using a sub to create those.

# Got rid of: sub _group_by2, sub find_edid_in_string, and its helper:
# sub _edid_from_lines, those methods are not used or useful to inxi.

sub _edid_from_lines {
	my (@l) = @_;
	my $edid_str = join('', map { /\s+([0-9a-f]{32})$/ && $1 } @l);
	if (length($edid_str) % (2 * 128) != 0 || length($edid_str) == 0) {
		return ();
	}
	pack("C*", map { hex($_) } $edid_str =~ /(..)/g);
}
sub find_edid_in_string {
	my ($input) = @_;
	my @edids;
	while ($input =~ /(?:EDID_DATA|: EDID \(in hex\)|EDID):\n((.*\n){8})/g) {
		push @edids, _edid_from_lines(split '\n', $1);
	}
	if (!@edids) {
		@edids = _edid_from_lines(split '\n', $input);
	}
	@edids;
}
sub _group_by2 {
	my @l;
	for (my $i = 0; $i < @_; $i += 2) {
		push @l, [ $_[$i], $_[$i+1] ];
	}
	@l;
}

C# hanged external method to internal, to allow for error returns in the main data 
sub check_parsed_edid {
	my ($edid) = @_;
	$edid->{edid_version} >= 1 && $edid->{edid_version} <= 2 or return 'bad edid_version';
	$edid->{edid_revision} != 0xff or return 'bad edid_revision';
	if ($edid->{monitor_range}) {
		$edid->{monitor_range}{horizontal_min} && 
		  $edid->{monitor_range}{horizontal_min} <= $edid->{monitor_range}{horizontal_max} 
			or return 'bad HorizSync';
		$edid->{monitor_range}{vertical_min} &&
		  $edid->{monitor_range}{vertical_min} <= $edid->{monitor_range}{vertical_max} 
			or return 'bad VertRefresh';
	}
	'';
}
# new:
sub _check_parsed_edid {
	my $edid = shift @_;
	if (!defined $edid->{edid_version}){
		_edid_error('edid-version','undefined');
	}
	elsif ($edid->{edid_version} < 1 || $edid->{edid_version} > 2){
		_edid_error('edid-version',$edid->{edid_version});
	}
	if (!defined $edid->{edid_revision}){
		_edid_error('edid-revision','undefined');
	}
	elsif ($edid->{edid_revision} == 0xff){
		_edid_error('edid-revision',$edid->{edid_revision});
	}
	if ($edid->{monitor_range}){
		if (!$edid->{monitor_range}{horizontal_min}){
			_edid_error('edid-sync','no horizontal');
		}
		elsif ($edid->{monitor_range}{horizontal_min} > $edid->{monitor_range}{horizontal_max}){
			_edid_error('edid-sync', 
			"bad horizontal values: min: $edid->{monitor_range}{horizontal_min} max: $edid->{monitor_range}{horizontal_max}");
		}
		if (!$edid->{monitor_range}{vertical_min}){
			_edid_error('edid-sync','no vertical');
		}
		elsif ($edid->{monitor_range}{vertical_min} > $edid->{monitor_range}{vertical_max}){
			_edid_error('edid-sync',
			"bad vertical values: min: $edid->{monitor_range}{vertical_min} max: $edid->{monitor_range}{vertical_max}");
		}
	}
}
sub _edid_error {
	my ($edid,$error,$data) = @_;
	$edid{edid_error} = [] if !$edid{edid_error};
	push(@{$edid{edid_error}},main::message($error,$data));
}
# called here, in parse_edid():

	_check_parsed_edid();
	\%edid;
}


## This is a fallback in case we need to use Parse::EDID Perl module again

## pinxi.1 - about line 1438:

\- Adds \fBMonitor\fR lines. Monitors are a subset of a \fBScreen\fR (X.org) or 
\fBDisplay\fR (Wayland), each of which can have one or more monitors. Normally a 
dual monitor setup is 2 monitors run by one Xorg Screen/Wayland Display. 

For best monitor data (Linux only), install Perl module \fBParse::EDID\fR, which 
can give much better monitor information. Each monitor has the following data, 
if available: Monitor ID, position (\fBpos:\fR), model, resolution (\fBres:\fR), 
dpi, diagonal (\fBdiag:\fR). 

## pinxi.1 - about line 2120

.TP
.B \-\-edid\fR
Shortcut. See \fB\-\-force edid\fR.

## pinxi.1 - about line 2132

\- \fBedid\fR \- Force parsing of binary edid file in /sys for monitor data.

## pinxi CheckRecommends, around line 2957

	elsif ($type eq 'recommended Perl modules'){
		@data = qw(File::Copy File::Find File::Spec::Functions HTTP::Tiny IO::Socket::SSL 
		Time::HiRes JSON::PP Cpanel::JSON::XS JSON::XS XML::Dumper Net::FTP);
		if (!$bsd_type){
				push(@data,'Parse::EDID');
		}
		if ($bsd_type && $bsd_type eq 'openbsd'){
			push(@data, qw(OpenBSD::Pledge OpenBSD::Unveil));
		}
		$b_perl_module = 1;
		$item = 'Perl Module';
		$extra = ' (Optional)';
		$extra2 = "None of these are strictly required, but if you have them all, 
		you can eliminate some recommended non Perl programs from the install. ";
		$extra3 = "HTTP::Tiny and IO::Socket::SSL must both be present to use as a 
		downloader option. For json export Cpanel::JSON::XS is preferred over 
		JSON::XS, but JSON::PP is in core modules. To run --debug 20-22 File::Copy,
		File::Find, and File::Spec::Functions must be present (most distros have 
		these in Core Modules).
		";
		if (!$bsd_type){
			$extra3 .= ' Parse::EDID gives fantastic Monitor data if /sys/class/drm 
			edid file available.';
		}
	}
	
## pinxi CheckRecommends - around line 3551

	'Parse::EDID' => {
	'info' => '-Gxx, -Gxxx, -Ga Monitor data (recommended).',
	'info-bsd' => 'not supported, requires /sys/class/drm.',
	'apt' => 'libparse-edid-perl',
	'pacman' => 'unknown',
	'rpm' => 'perl-Parse-EDID',
	},
	
## pinxi show_options - around line 5131 

	'edid' => sub {
		$force{'edid'} = 1;},
		
## pinxi show_options - around line 5150 

	'force:s' => sub {
		my ($opt,$arg) = @_;
		if ($arg){
			my $wl = 'colors|cpuinfo|display|dmidecode|edid|hddtemp|lsusb|man|meminfo|';
			$wl .= 'no-dig|no-doas|no-html-wan|no-sudo|pkg|usb-sys|vmstat|wayland|wmctrl';
			for (split(',',$arg)){
				if ($_ =~ /\b($wl)\b/){
					$force{lc($1)} = 1;
				}
				else {
					main::error_handler('bad-arg', $opt, $_);
				}
			}
		}
		
## pinxi: GraphicItem - around 51153 
sub set_monitors_sys {
	eval $start if $b_log;
	my $pattern = '/sys/class/drm/card[0-9]/device/driver/module/drivers/*';
	my @cards_glob = main::globber($pattern);
	$pattern = '/sys/class/drm/card*-*/{edid,enabled,status,modes}';
	my @ports_glob = main::globber($pattern);
	# print Data::Dumper::Dumper \@cards_glob;
	# print Data::Dumper::Dumper \@ports_glob;
	my ($b_perl_edid,$card,%cards,@data,$edid_prog,$file,$item,$path,$port);
	foreach $file (@cards_glob){
		next if ! -e $file;
		if ($file =~ m|^/sys/class/drm/(card\d+)/.+?/drivers/(\S+):(\S+)$|){
			push(@{$cards{$1}},[$2,$3]);
		}
	}
	if (main::check_perl_module('Parse::EDID')){
		$b_perl_edid = 1;
		Parse::EDID->import();
	}
	else {
		$edid_prog = main::check_program('parse-edid');
	}
	# print Data::Dumper::Dumper \%cards;
	foreach $file (sort @ports_glob){
		next if ! -r $file;
		$item = $file;
		$item =~ s|(/.*/(card\d+)-([^/]+))/(.+)||;
		$path = $1;
		$card = $2;
		$port = $3;
		$item = $4;
		next if !$1;
		$monitor_ids = {} if !$monitor_ids;
		$monitor_ids->{$port}{'monitor'} = $port;
		if (!$monitor_ids->{$port}{'drivers'} && $cards{$card}){
			foreach my $info (@{$cards{$card}}){
				push(@{$monitor_ids->{$port}{'drivers'}},$info->[1]);
			}
		}
		$monitor_ids->{$port}{'path'} = readlink($path);
		$monitor_ids->{$port}{'path'} =~ s|^\.\./\.\.|/sys|;
		if ($item eq 'status' || $item eq 'enabled'){
			# print "$file\n";
			$monitor_ids->{$port}{$item} = main::reader($file,'strip',0);
		}
		# arm: U:1680x1050p-0
		elsif ($item eq 'modes'){
			@data = main::reader($file,'strip');
			next if !@data;
			if (scalar @data == 1 || $data[-1] eq $data[0]){
				$monitor_ids->{$port}{'modes-min-max'} = $data[0];
			}
			else {
				$monitor_ids->{$port}{'modes-min'} = $data[-1];
				$monitor_ids->{$port}{'modes-max'} = $data[0];
			}
		}
		elsif ($item eq 'edid'){
			next if -s $file;
			monitor_edid_data($file,$port,$b_perl_edid,$edid_prog);
		}
	}
	main::log_data('dump','$ports ref',$monitor_ids) if $b_log;
	print Data::Dumper::Dumper $monitor_ids if $dbg[44];
	eval $end if $b_log;
}
sub monitor_edid_data {
	eval $start if $b_log;
	my ($file,$port,$b_perl_edid,$edid_prog) = @_;
	my (@data);
	if ($b_perl_edid){
		open my $fh, '<:raw', $file or return; # it failed, but give up, don't tru
		my $edid;
		my $edid_raw = do { local $/; <$fh> };
		$edid = Pars::eEDID::parse_edid($edid_raw) if $edid_raw;
		main::log_data('dump','Parse::EDID',$edid) if $b_log;
		print Data::Dumper::Dumper $edid if $dbg[44];
		return if !$edid;
		$monitor_ids->{$port}{'build-date'} = $edid->{'year'};
		if ($edid->{'gamma'}){
			$monitor_ids->{$port}{'gamma'} = ($edid->{'gamma'}/100 + 0);
		}
		if ($edid->{'monitor_name'}){
			$monitor_ids->{$port}{'model'} = main::clean($edid->{'monitor_name'}); 
		}
		if ($edid->{'diagonal_size'}){
			$monitor_ids->{$port}{'diagonal-m'} = sprintf('%.0f',($edid->{'diagonal_size'}*25.4)) + 0;
			$monitor_ids->{$port}{'diagonal'} = sprintf('%.1f',$edid->{'diagonal_size'}) + 0;
		}
		$monitor_ids->{$port}{'ratio'} = $edid->{'ratio_name'};
		if (!$edid->{'detailed_timings'}){
			$monitor_ids->{$port}{'res-x'} = $edid->{'detailed_timings'}[0]{'horizontal_active'};
			$monitor_ids->{$port}{'res-y'} = $edid->{'detailed_timings'}[0]{'vertical_active'};
			if ($edid->{'detailed_timings'}[0]{'horizontal_image_size'}){
				$monitor_ids->{$port}{'size-x'} = $edid->{'detailed_timings'}[0]{'horizontal_image_size'};
				$monitor_ids->{$port}{'size-x-i'} = sprintf('%.1f',($edid->{'detailed_timings'}[0]{'horizontal_image_size'}/25.4)) + 0;
			}
			if ($edid->{'detailed_timings'}[0]{'vertical_image_size'}){
				$monitor_ids->{$port}{'size-y'} = $edid->{'detailed_timings'}[0]{'vertical_image_size'};
				$monitor_ids->{$port}{'size-y-i'} = sprintf('%.1f',($edid->{'detailed_timings'}[0]{'vertical_image_size'}/25.4)) + 0;
			}
			if ($edid->{'detailed_timings'}[0]{'horizontal_dpi'}){
				$monitor_ids->{$port}{'dpi'} = sprintf('%.0f',$edid->{'detailed_timings'}[0]{'horizontal_dpi'}) + 0;
			}
		}
		if ($edid->{'serial_number'}){
			$monitor_ids->{$port}{'serial'} = main::clean_dmi($edid->{'serial_number'}); 
		}
	}
	elsif ($edid_prog){
		@data = main::grabber("cat $file | $edid_prog 2>/dev/null");
		main::log_data('dump','parse-edid @data',\@data) if $b_log;
		print 'edid prog read: ', Data::Dumper::Dumper \@data if $dbg[44];
		@data = map {s/^(\s+(#\s+)?)//;$_} @data;
		return if !@data;
		my @working;
		shift @data;
		pop @data;
		foreach (@data){
			if (/^ModelName "([^"]+)"/){
				$monitor_ids->{$port}{'model'} = main::clean($1);
			}
			elsif (/^Monitor Manufactured .* (\d{4})/){
				$monitor_ids->{$port}{'build-date'} = $1;
			}
			elsif (/^DisplaySize (\d+) (\d+)/){
				$monitor_ids->{$port}{'size-x'} = $1;
				$monitor_ids->{$port}{'size-y'} = $2;
				$monitor_ids->{$port}{'size-x-i'} = sprintf("%.1f", ($1/25.4));
				$monitor_ids->{$port}{'size-y-i'} = sprintf("%.1f", ($2/25.4));
			}
			elsif (/^Gamma ([\d.]+)/){
				$monitor_ids->{$port}{'gamma'} = ($1 + 0);
			}
		}
	}
	# NOTE: not using this fallback by default, the data is too unreliable.
	elsif ($force{'edid'}) {
		@data = main::reader($file,'strip');
		print 'edid bin read: ', Data::Dumper::Dumper \@data if $dbg[44];
		main::log_data('dump','string read @data',\@data) if $b_log;
		return if !@data;
		if ($data[1]){
			# trim off first non ascii characters
			$monitor_ids->{$port}{'model'} = main::clean($data[1]);
			# trim off first non ascii characters
			$monitor_ids->{$port}{'model'} =~ s/^[^[:print:]]+//;
			# WG'HL!:q8-@X,ESoBrQ n(USoBSONY TV, too many variants, just dump if the
			# string was not clean. 
			if ($monitor_ids->{$port}{'model'} =~ /[@!^&=£°#\[\]]|[^[:print:]]/){
				delete $monitor_ids->{$port}{'model'};
			}
			# print length($monitor_ids->{$port}{'model'}),"\n";
		}
		# I don't know what this value actually refers to, sometimes serial
		if ($data[2]){
			$monitor_ids->{$port}{'model-info'} = main::clean($data[2]);
			# trim off first non ascii characters
			$monitor_ids->{$port}{'model-info'} =~ s/^[^[:print:]]+//;
			if ($monitor_ids->{$port}{'model-info'} =~ /[@!^&=£°#\[\]]|[^[:print:]]/){
				delete $monitor_ids->{$port}{'model-info'};
			}
		}
	}
	eval $end if $b_log;
}

