#!/usr/bin/env perl

use strict;
use warnings;

my ($end,$start,$b_log) = ('','',0);

my $file = 'disks.txt';
open my $info, $file or die "Could not open $file: $!";

my @disks = ();
my @disks_full = ();
while( my $line = <$info>)  {   
	chomp($line);
	my $usb = ($line =~ /\s*USB/) ? 'USB: ':'' ;
	my $firewire = ($line =~ /\s*FireWire/) ? 'FireWire: ':'' ;
	my $thunderbolt = ($line =~ /\s*ThunderBolt/i) ? 'Thunderbolt: ':'' ;
	
	$line =~ s/^\s*((FireWire|USB)\s+)?model:\s*//;
	$line =~ s/_/ /g;
	my $size = $line;
	$size =~ s/^.*\s+size:\s+//;
	$line =~ s/\s+size:.+$//;
	my @result = device_vendor($line,0);
	if (!(grep {/^$line$/} @disks ) && !$result[0]){
		my $data = $usb . $firewire . $thunderbolt . $line . ' size: ' . $size . "\n";
		push @disks_full, $data;
		push @disks, $line;
	}
   #last if $. == 2;
}
#print @disks_full;

close $info;
my $filename = 'disks-unhandled.txt';
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
print $fh @disks_full;
close $fh;
print "done\n";

sub device_vendor {
	eval $start if $b_log;
	my ($model,$serial) = @_;
	my ($vendor) = ('');
	my (@data);
	return if !$model;
	# 0 - match pattern; 1 - replace pattern; 2 - vendor print; 3 - serial pattern
	# Data URLs: inxi-resources.txt Section: DiskData device_vendor()
	# $model = 'MEDIAMAX ';
	# $model = 'Patriot Memory';
	my @vendors = (
	## These go first because they are the most likely and common ##
	['(Crucial|^(FC)?CT|-CT|^M4\b)','Crucial','Crucial',''],
	['^(INTEL|SSD(PAM|SA2))','^INTEL','Intel',''],
	['(KINGSTON|DataTraveler|DT\s?(DUO|Microduo|101)|^SMS|^SHS|^SUV|^Ultimate CF|HyperX)','KINGSTON','Kingston',''], # maybe SHS: SHSS37A SKC SUV
	# must come before samsung MU. NOTE: toshiba can have: TOSHIBA_MK6475GSX: mush: MKNSSDCR120GB_
	['(^MKN|Mushkin)','Mushkin','Mushkin',''], # MKNS
	# MU = Multiple_Flash_Reader too risky: |M[UZ][^L] HD103SI HD start risky
	# HM320II HM320II
	['(SAMSUNG|^MCG[0-9]+GC|^MCC|^[GS]2 Portable|^DUO\b|^P3|^(HM|SP)[0-9]{2}|^MZMPC|^HD[0-9]{3}[A-Z]{2}$)','SAMSUNG','Samsung',''], # maybe ^SM, ^HM
	# Android UMS Composite?
	['(SanDisk|^SDS[S]?[DQ]|^SL([0-9]+)G|^AFGCE|ULTRA\sFIT|Clip Sport|Cruzer|^Extreme)','SanDisk','SanDisk',''],
	['^STEC\b','^STEC\b','STEC',''], # ssd drive, must come before seagate ST test
	# real, SSEAGATE Backup+; XP1600HE30002 | 024 HN (spinpoint)
	['(^ST[^T]|[S]?SEAGATE|^X[AFP]|^5AS|^BUP|Expansion Desk|FreeAgent|GoFlex|Backup(\+|\s?Plus)\s?(Hub)?|OneTouch)','[S]?SEAGATE','Seagate',''], 
	['^(WD|WL[0]9]|Western Digital|My (Book|Passport)|\d*LPCX|Elements|M000|EARX|EFRX|\d*EAVS|0JD|JPVX|[0-9]+(BEV|(00)?AAK|AAV|AZL|EA[CD]S))','(^WDC|Western\s?Digital)','Western Digital',''],
	## Then better known ones ##
	['^(A-DATA|ADATA|AXN|CH11|HV[1-9])','^(A-DATA|ADATA)','A-Data',''],
	['^ADTRON','^(ADTRON)','Adtron',''],
	['^ASUS','^ASUS','ASUS',''],
	['^ATP','^ATP[\s\-]','ATP',''],
	# Force MP500
	['^(Corsair|Force\s|(Flash\s*)?Voyager)','^Corsair','Corsair',''],
	['^(FUJITSU|MH[TVWYZ][0-9]|MP|MAP[0-9])','^FUJITSU','Fujitsu',''],
	# note: 2012:  wdc bought hgst
	['^(HGST|Touro|5450)','^HGST','HGST (Hitachi)',''], # HGST HUA
	['^(Hitachi|HD[ST]|DK[0-9]|IC|HT|HU)','^Hitachi','Hitachi',''], 
	# vb: VB0250EAVER but clashes with vbox; HP_SSD_S700_120G ;GB0500EAFYL GB starter too generic?
	['^(HP\b|MB0|G[BJ]0|v[0-9]{3}[bgorw]$|x[0-9]{3}[w]$)','^HP','HP',''], 
	['^(LSD|Lexar|JumpDrive|JD\s?Firefly)','^Lexar','Lexar',''], # mmc-LEXAR_0xb016546c; JD Firefly;
	# OCZSSD2-2VTXE120G is OCZ-VERTEX2_3.5
	['^(OCZ|APOC|D2|DEN|DEN|DRSAK|EC188|FTNC|GFGC|MANG|MMOC|NIMC|NIMR|PSIR|RALLY2|TALOS2|TMSC|TRSAK)','^OCZ[\s\-]','OCZ',''],
	['^OWC','^OWC[\s\-]','OWC',''],
	['^Philips','^Philips','Philips',''],
	['^PIONEER','^PIONEER','Pioneer',''],
	['^PNY','^PNY\s','PNY','','^PNY'],
	# note: get rid of: M[DGK] becasue mushkin starts with MK
	# note: seen: KXG50ZNV512G NVMe TOSHIBA 512GB | THNSN51T02DUK NVMe TOSHIBA 1024GB
	['(^[S]?TOS|^THN|TOSHIBA|TransMemory|^M[KQ][0-9])','[S]?TOSHIBA','Toshiba',''], # scsi-STOSHIBA_STOR.E_EDITION_
	## These go last because they are short and could lead to false ID, or are unlikely ##
	# unknown: AL25744_12345678; ADP may be usb 2.5" adapter; udisk unknown: Z1E6FTKJ 00AAKS
	# SSD2SC240G726A10 MRS020A128GTS25C EHSAJM0016GB
	['^5ACE','^5ACE','5ACE',''], # could be seagate: ST316021 5ACE
	['^Addlink','^Addlink','Addlink',''],
	['^Aireye','^Aireye','Aireye',''],
	['^Alfawise','^Alfawise','Alfawise',''],
	['^Android','^Android','Android',''],
	['^Apotop','^Apotop','Apotop',''],
	# must come before AP|Apacer
	['^(APPLE|iPod)','^APPLE','Apple',''],
	['^(AP|Apacer)','^Apacer','Apacer',''],
	['^(A-?RAM|ARSSD)','^A-?RAM','A-RAM',''],
	['^(ASM|2115)','^ASM','ASMedia',''],#asm1153e
	['^Bell\b','^Bell','Packard Bell',''],
	['^BHT','^BHT','BHT',''],
	['^BIOSTAR','^BIOSTAR','Biostar',''],
	['^BIWIN','^BIWIN','BIWIN',''],
	['^BUFFALO','^BUFFALO','Buffalo',''],
	['^Centerm','^Centerm','Centerm',''],
	['^CHN\b','','Zheino',''],
	['^Clover','^Clover','Clover',''],
	['^Colorful\b','^Colorful','Colorful',''],
	['^CSD','^CSD','CSD',''],
	['^(Dane-?Elec|Z Mate)','^Dane-?Elec','DaneElec',''],
	# Daplink vfs is an ARM software thing
	['^Dell\b','^Dell','Dell',''],
	['^DeLOCK','^Delock(\s?products)?','Delock',''],
	['^DGM','^DGM\b','DGM',''],
	['^DIGITAL\s?FILM','DIGITAL\s?FILM','Digital Film',''],
	['^Dogfish','^Dogfish','Dogfish',''],
	['^DragonDiamond','^DragonDiamond','DragonDiamond',''],
	['^DREVO\b','^DREVO','Drevo',''],
	['^(Eaget|V8$)','^Eaget','Eaget',''],
	['^EDGE','^EDGE','EDGE',''],
	['^Elecom','^ElecomE','Elecom',''],
	['^EXCELSTOR','^EXCELSTOR( TECHNO(LOGY)?)?','ExcelStor',''],
	['^EZLINK','^EZLINK','EZLINK',''],
	['^Fantom','^Fantom( Drive[s]?)?','Fantom Drives',''],
	['^Faspeed','^Faspeed','Faspeed',''],
	['^FASTDISK','^FASTDISK','FASTDISK',''],
	['^FORESEE','^FORESEE','Foresee',''],
	['^GALAX\b','^GALAX','GALAX',''],
	['^Galaxy\b','^Galaxy','Galaxy',''],
	['^Geil','^Geil','Geil',''],
	['^Generic','^Generic','Generic',''],
	['^Gigabyte','^Gigabyte','Gigabyte',''], # SSD
	['^Gigastone','^Gigastone','Gigastone',''],
	['^Gloway','^Gloway','Gloway',''],
	['^(GOODRAM|IR SSD)','^GOODRAM','GOODRAM',''],
	# supertalent also has FM: |FM
	['^(G[\.]?SKILL)','^G[\.]?SKILL','G.SKILL',''],
	['^HDC','^HDC\b','HDC',''],
	['^Hectron','^Hectron','Hectron',''],
	['^Hoodisk','^Hoodisk','Hoodisk',''],
	['^HUAWEI','^HUAWEI','Huawei',''],
	['^(IBM|DT)','^IBM','IBM',''], 
	['^IEI Tech','^IEI Tech(\.|nology)?( Corp(\.|oration)?)?','IEI Technology',''],
	['^(Imation|Nano\s?Pro|HQT)','^Imation(\sImation)?','Imation',''], # Imation_ImationFlashDrive; TF20 is imation/tdk
	['^(InnoDisk|Innolite)','^InnoDisk( Corp.)?','InnoDisk',''],
	['^Innostor','^Innostor','Innostor',''],
	['^Innovation','^Innovation','Innovation',''],
	['^(INM|Integral|V\s?Series)','^Integral(\s?Memory)?','Integral Memory',''],
	['^(Intenso|(Alu|Mobile|Rainbow|Speed) Line)','^Intenso','Intenso',''],
	['^(Iomega|ZIP\b)','^Iomega','Iomega',''], 
	['^JingX','^JingX','JingX',''], #JingX 120G SSD - not confirmed, but guessing
	# NOTE: ITY2 120GB hard to find
	['^JMicron','^JMicron','JMicron',''], #JMicron H/W raid
	['^KingDian','^KingDian','KingDian',''],
	['^Kingfast','^Kingfast','Kingfast',''],
	['^KingMAX','^KingMAX','KingMAX',''],
	['^KINGSHARE','^KINGSHARE','KingShare',''],
	['^KingSpec','^KingSpec','KingSpec',''],
	# kingwin docking, not actual drive
	['^(EZD|EZ-Dock)','','Kingwin Docking Station',''],
	['^KLEVV','^KLEVV','KLEVV',''],
	['^LDLC','^LDLC','LDLC',''],
	['^Lenovo','^Lenovo','Lenovo',''],
	['^RPFT','','Lenovo O.E.M.',''],
	['^LG\b','^LG','LG',''],
	['^(LITE[\-\s]?ON[\s\-]?IT)','^LITE[\-]?ON[\s\-]?IT','LITE-ON IT',''], # LITEONIT_LSS-24L6G
	['^(LITE[\-\s]?ON|PH[1-9])','^LITE[\-]?ON','LITE-ON',''], # PH6-CE240-L
	['^M-Systems','^M-Systems','M-Systems',''],
	['^(MAXTOR|Atlas|TM[0-9]{4})','^MAXTOR','Maxtor',''], # note M2 M3 is usually maxtor, but can be samsung
	['^(Memorex|TravelDrive)','^Memorex','Memorex',''],
	# note: C300/400 can be either micron or crucial, but C400 is M4 from crucial
	['(^MT|^M5|^Micron|00-MT|C[34]00)','^Micron','Micron',''],# C400-MTFDDAK128MAM
	['^MARSHAL\b','^MARSHAL','Marshal',''],
	['^MARVELL','^MARVELL','Marvell',''],
	['^MDT\b','^MDT','MDT (rebuilt WD/Seagate)',''], # mdt rebuilds wd/seagate hdd
	['^Medion','^Medion','Medion',''],
	['^(MEDIAMAX|WL[0-9]{2})','^MEDIAMAX','MediaMax',''],
	['^Morebeck','^Morebeck','Morebeck',''],
	['^Motorola','^Motorola','Motorola',''],
	['^MTRON','^MTRON','MTRON',''],
	['^MXSSD','^Mach\s*Xtreme','Mach Xtreme',''],
	['^Netac','^Netac','Netac',''],
	['^OOS[1-9]','','Utania',''],
	['^OWC','^OWC\b','OWC',''],
	['^PALIT','PALIT','Palit',''], # ssd 
	['^PERC\b','','Dell PowerEdge RAID Card',''], # ssd 
	['^(PS[8F]|Patriot)','^Patriot([-\s]?Memory)?','Patriot',''],
	['^Pioneer','Pioneer','Pioneer',''],
	['^PIX[\s]?JR','^PIX[\s]?JR','Disney',''],
	['^(PLEXTOR|PX-)','^PLEXTOR','Plextor',''],
	['^(PQI|Intelligent\s?Stick)','^PQI','PQI',''],
	['QEMU','^[0-9]*QEMU( QEMU)?','QEMU',''], # 0QUEMU QEMU HARDDISK
	['(^Quantum|Fireball)','^Quantum','Quantum',''],
	['^QUMO','^QUMO','Qumo',''],
	['^(R3|AMD\s?(RADEON)?)','AMD\s?(RADEON)?','AMD Radeon',''], # ssd 
	['^RENICE','^RENICE','Renice',''],
	['^(Ricoh|R5)','^Ricoh','Ricoh',''],
	['^RIM[\s]','^RIM','RIM',''],
	['^Runcore','^Runcore','Runcore',''],
	['^Sage','^Sage(\s?Micro)?','Sage Micro',''],
	['^SigmaTel','^SigmaTel','SigmaTel',''],
	# DIAMOND_040_GB
	['^(SILICON\s?MOTION|SM[0-9])','^SILICON\s?MOTION','Silicon Motion',''],
	['^(Silicon\s?Power|SP[CP]C|Silicon|Diamond|Haspeed)','Silicon\s?Power','Silicon Power',''],
	['Smartbuy','\s?Smartbuy','Smartbuy',''], # SSD Smartbuy 60GB; mSata Smartbuy 3
	# HFS128G39TND-N210A; seen nvme with name in middle
	['(SK\s?HYNIX|^HF[MS])','\s?SK\s?HYNIX','SK Hynix',''], 
	['hynix','hynix','Hynix',''],# nvme middle of string, must be after sk hynix
	['^SH','','Smart Modular Tech.',''],
	['^Skill','^Skill','Skill',''],
	['^(SMART( Storage Systems)?|TX)','^(SMART( Storage Systems)?)','Smart Storage Systems',''],
	['^(S[FR]-|Sony)','^Sony','Sony',''],
	['^STE[CK]','^STE[CK]','sTec',''], # wd bought this one
	['^STORFLY','^STORFLY','StorFly',''],
	['^SUNEAST','^SUNEAST','SunEast',''],
	# NOTE: F[MNETU] not reliable, g.skill starts with FM too: 
	# Seagate ST skips STT. 
	['^(STT|FHM[0-9])','','Super Talent',''], 
	['^(SF|Swissbit)','^Swissbit','Swissbit',''],
	# ['^(SUPERSPEED)','^SUPERSPEED','SuperSpeed',''], # superspeed is a generic term
	['^TANDBERG','^TANDBERG','Tanberg',''],
	['^TCSUNBOW','^TCSUNBOW','TCSunBow',''],
	['^(TDK|TF[1-9][0-9])','^TDK','TDK',''],
	['^TEAC','^TEAC','TEAC',''],
	['^TEAM','^TEAM( Group)?','Team',''],
	['^Teclast','^Teclast','Teclast',''],
	['^Teleplan','^Teleplan','Teleplan',''],
	['^Tigo','^Tigo','Tigo',''],
	['^TopSunligt','^TopSunligt','TopSunligt',''], # is this a typo? hard to know
	['^TopSunlight','^TopSunlight','TopSunlight',''],
	['^(TS|Transcend|JetFlash)','^Transcend','Transcend',''],
	# Twister Line but if we slice out Twister it would just say Line
	['^(TrekStor|DS maxi)','^TrekStor','TrekStor',''],
	['^UDinfo','^UDinfo','UDinfo',''],
	['^USBTech','^USBTech','USBTech',''],
	['^(UG|Unigen)','^Unigen','Unigen',''],
	['^VBOX','','VirtualBox',''],
	['^(Verbatim|STORE N GO)','^Verbatim','Verbatim',''],
	['^(Victorinox|Swissflash)','^Victorinox','Victorinox',''],
	['^VISIONTEK','^VISIONTEK','VisionTek',''],
	['^VMware','^VMware','VMware',''],
	['^(Vseky|Vaseky)','^Vaseky','Vaseky',''], # ata-Vseky_V880_350G_
	['^(YUCUN|R880)','^YUCUN','YUCUN',''],
	['^(Zheino|CHN[0-9])','^Zheino','Zheino',''],
	['^ZTC','^ZTC','ZTC',''],
	['^(ASMT|2115)','^ASMT','ASMT (case)',''],
	);
	foreach my $row (@vendors){
		if ($model =~ /$row->[0]/i || ($row->[3] && $serial && $serial =~ /$row->[3]/)){
			$vendor = $row->[2];
			$model =~ s/$row->[1]//i if $row->[1] && lc($model) ne lc($row->[1]);
			$model =~ s/^[\s\-_]+|[\s\-_]+$//g;
			$model =~ s/\s\s/ /g;
			@data = ($vendor,$model);
			last;
		}
	}
	eval $end if $b_log;
	return @data;
}
# Normally hddtemp requires root, but you can set user rights in /etc/sudoers.



