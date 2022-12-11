#!/usr/bin/env perl
## disk_vendors.pl: Copyright (C) 2022 Harald Hope
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
## into the list, specify USB: or non as you'll see in the disks.txt file.
## Because of the nature of disk names, there's always going be a big set that
## cannot be matched, but overall the results using this method are quite good.

use strict;
use warnings;
# use diagnostics;
use 5.024;

use Data::Dumper qw(Dumper); 
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure ('bundling', 'no_ignore_case', 
'no_getopt_compat', 'no_auto_abbrev','pass_through');

my $self_name = 'disk_vendors.pl';
my $self_version = '1.7';
my $self_date = '2022-10-07';

my $disks_raw = 'lists/disks.full';
my $disks_unhandled = 'lists/disks.unhandled';
my $disks_read = $disks_raw;

my ($data,$vendors);

my ($b_log,$end,$start);
my $line = '------------------------------------------------------------------';
my $dbg = [];

## Copy everything including start/end disk vendor block comments. These are the 
## rules you need to update to add unmatched vendors or vendor products. Always 
## make sure you understand how this works before proceeding or you will be sad.
## Paste into pinxi, replace including start/end comments

## START DISK VENDOR BLOCK ##
# 0 - match pattern; 1 - replace pattern; 2 - vendor print; 3 - serial pattern
sub set_disk_vendors {
	eval $start if $b_log;
	$vendors = [
	## MOST LIKELY/COMMON MATCHES ##
	['(Crucial|^(C[34]00$|(C300-)?CTF|(FC)?CT|DDAC|M4(\b|SSD))|-CT|Gizmo!)','Crucial','Crucial',''],
	# H10 HBRPEKNX0202A NVMe INTEL 512GB
	['(\bINTEL\b|^(SSD(PAM|SA2)|HBR|(MEM|SSD)PEB?K|SSD(MCE|S[AC])))','\bINTEL\b','Intel',''], 
	# note: S[AV][1-9]\d can trigger false positives
	['(K(ING)?STON|^(OM8P|RBU|S[AV][1234]00|S[HMN]S|SK[CY]|SQ5|SS200|SVP|SS0|SUV|SNV|T52|T[AB]29|Ultimate CF)|V100|DataTraveler|DT\s?(DUO|Microduo|101)|HyperX|13fe\b)','(KINGSTON|13fe)','Kingston',''], # maybe SHS: SHSS37A SKC SUV
	# must come before samsung MU. NOTE: toshiba can have: TOSHIBA_MK6475GSX: mush: MKNSSDCR120GB_
	['(^MKN|Mushkin)','Mushkin','Mushkin',''], # MKNS
	# MU = Multiple_Flash_Reader too risky: |M[UZ][^L] HD103SI HD start risky
	# HM320II HM320II HM
	['(SAMSUNG|^(AWMB|[BC]DS20|[BC]WB|BJ[NT]|[BC]GND|CJN|CUT|[DG]3 Station|DUO\b|DUT|CKT|[GS]2 Portable|GN|HD\d{3}[A-Z]{2}$|(HM|SP)\d{2}|HS\d|M[AB]G\d[FG]|MCC|MCBOE|MCG\d+GC|[CD]JN|MZ|^G[CD][1-9][QS]|P[BM]\d|(SSD\s?)?SM\s?841)|^SSD\s?[89]\d{2}\s(DCT|PRO|QVD|\d+[GT]B)|\bEVO\b|SV\d|[BE][A-Z][1-9]QT|YP\b|[CH]N-M|MMC[QR]E)','SAMSUNG','Samsung',''], # maybe ^SM, ^HM
	# Android UMS Composite?U1
	['(SanDisk|0781|^(A[BCD]LC[DE]|AFGCE|D[AB]4|DX[1-9]|Extreme|Firebird|S[CD]\d{2}G|SD(S[S]?[ADQ]|SL\d+G|SU\d)|SDW[1-9]|SE\d{2}|SEM[1-9]|\d[STU]|U(3\b|1\d0))|Clip Sport|Cruzer|iXpand|SSD (Plus|U1[01]0) [1-9]|ULTRA\s(FIT|trek|II)|X[1-6]\d{2})','(SanDisk|0781)','SanDisk',''],
	# these are HP/Sandisk cobranded. DX110064A5xnNMRI ids as HP and Sandisc
	['(^DX[1-9])','^(HP\b|SANDDISK)','Sandisk/HP',''], # ssd drive, must come before seagate ST test
	# real, SSEAGATE Backup+; XP1600HE30002 | 024 HN (spinpoint) ; possible usb: 24AS
	# ST[numbers] excludes other ST starting devices
	['([S]?SEAGATE|^((Barra|Fire)Cuda|BUP|Expansion|(ATA\s|HDD\s)?ST\d{2}|5AS|X[AFP])|Expansion Desk|FreeAgent|GoFlex|INIC|Backup(\+|\s?Plus)\s?(Hub)?|OneTouch|Slim\s?BK)','[S]?SEAGATE','Seagate',''], 
	['^(WD|WL[0]9]|Western Digital|My (Book|Passport)|\d*LPCX|Elements|easystore|EA[A-Z]S|EARX|EFRX|EZRX|\d*EAVS|G[\s-]Drive|i HTS|0JD|JP[CV]|MD0|M000|\d+(BEV|(00)?AAK|AAV|AZL|EA[CD]S)|PC\sSN|SPZX|3200[AB]|2500[BJ]|20G2|5000[AB]|6400[AB]|7500[AB]|00[ABL][A-Z]{2}|SSC\b)','(^WDC|Western\s?Digital)','Western Digital',''],
	# rare cases WDC is in middle of string
	['(\bWDC\b|1002FAEX)','','Western Digital',''],
	## THEN BETTER KNOWN ONESs ##
	['^Acer','^Acer','Acer',''],
	# A-Data can be in middle of string
	['^(.*\bA-?DATA|ASP\d|AX[MN]|CH11|HV[1-9]|IM2|HD[1-9]|HDD\s?CH|IUM|SX\d|Swordfish)','A-?DATA','A-Data',''],
	['^(ASUS|ROG)','^ASUS','ASUS',''], # ROG ESD-S1C
	# ATCS05 can be hitachi travelstar but not sure
	['^ATP','^ATP\b','ATP',''],
	# Force MP500
	['^(Corsair|Force\s|(Flash\s*)?(Survivor|Voyager)|Neutron|Padlock)','^Corsair','Corsair',''],
	['^(FUJITSU|MJA|MH[TVWYZ]\d|MP|MAP\d|F\d00s?-)','^FUJITSU','Fujitsu',''],
	# MAB3045SP shows as HP or Fujitsu, probably HP branded fujitsu
	['^(MAB\d)','^(HP\b|FUJITSU)','Fujitsu/HP',''],
	# note: 2012:  wdc bought hgst
	['^(DKR|HGST|Touro|54[15]0|7250|HC[CT]\d)','^HGST','HGST (Hitachi)',''], # HGST HUA
	['^((ATA\s)?Hitachi|HCS|HD[PST]|DK\d|IC|(HDD\s)?HT|HU|HMS|HDE|0G\d|IHAT)','Hitachi','Hitachi',''], 
	# vb: VB0250EAVER but clashes with vbox; HP_SSD_S700_120G ;GB0500EAFYL GB starter too generic?
	['^(HP\b|[MV]B[0-6]|G[BJ]\d|DF\d|F[BK]|0-9]|MM\d{4}|PSS|XR\d{4}|c350|v\d{3}[bgorw]$|x\d{3}[w]$|VK0|HC[CPY]\d|EX9\d\d|VO0)','^HP','HP',''], 
	['^(Lexar|LSD|JumpDrive|JD\s?Firefly|LX\d|WorkFlow)','^Lexar','Lexar',''], # mmc-LEXAR_0xb016546c; JD Firefly;
	# these must come before maxtor because STM
	['^STmagic','^STmagic','STmagic',''],
	['^(STMicro|SMI|CBA)','^(STMicroelectronics|SMI)','SMI (STMicroelectronics)',''],
	# note M2 M3 is usually maxtor, but can be samsung. Can conflict with Team: TM\d{4}|
	['^(MAXTOR|Atlas|4R\d{2}|E0\d0L|L(250|500)|[KL]0[1-9]|Y\d{3}[A-Z]|STM\d|F\d{3}L)','^MAXTOR','Maxtor',''], 
	# OCZSSD2-2VTXE120G is OCZ-VERTEX2_3.5
	['^(OCZ|Agility|APOC|D2|DEN|DEN|DRSAK|EC188|FTNC|GFGC|MANG|MMOC|NIMC|NIMR|PSIR|RALLY2|TALOS2|TMSC|TRSAK|VERTEX|Trion|Onyx|Vector[\s-]?15)','^OCZ[\s-]','OCZ',''],
	['^(OWC|Aura|Mercury[\s-]?(Electra|Extreme))','^OWC\b','OWC',''],
	['^(Philips|GoGear)','^Philips','Philips',''],
	['^PIONEER','^PIONEER','Pioneer',''],
	['^(PNY|Hook\s?Attache|SSD2SC|(SSD7?)?EP7|CS\d{3}|Elite\s?P)','^PNY\s','PNY','','^PNY'],
	# note: get rid of: M[DGK] becasue mushkin starts with MK
	# note: seen: KXG50ZNV512G NVMe TOSHIBA 512GB | THNSN51T02DUK NVMe TOSHIBA 1024GB 
	['(TOSHIBA|TransMemory|KBG4|^((A\s)?DT01A|M[GKQ]\d|HDW|SA\d{2}G$|(008|016|032|064|128)G[379E][0-9A]$|[S]?TOS|THN)|0930|KSG\d)','S?(TOSHIBA|0930)','Toshiba',''], # scsi-STOSHIBA_STOR.E_EDITION_
	## LAST: THEY ARE SHORT AND COULD LEAD TO FALSE ID, OR ARE UNLIKELY ##
	# unknown: AL25744_12345678; ADP may be usb 2.5" adapter; udisk unknown: Z1E6FTKJ 00AAKS
	# SSD2SC240G726A10 MRS020A128GTS25C EHSAJM0016GB
	['^2[\s-]?Power','^2[\s-]?Power','2-Power',''], 
	['^(3ware|9650SE)','^3ware','3ware (controller)',''], 
	['^5ACE','^5ACE','5ACE',''], # could be seagate: ST316021 5ACE
	['^(Aar(vex)?|AX\d{2})','^AARVEX','AARVEX',''],
	['^(AbonMax|ASU\d)','^AbonMax','AbonMax',''],
	['^Acasis','^Acasis','Acasis (hub)',''],
	['^Acclamator','^Acclamator','Acclamator',''],
	['^(Actions|HS USB Flash|10d6)','^(Actions|10d6)','Actions',''],
	['^Addlink','^Addlink','Addlink',''],
	['^(ADplus|SuperVer\b)','^ADplus','ADplus',''],
	['^ADTRON','^ADTRON','Adtron',''],
	['^(Advantech|SQF)','^Advantech','Advantech',''],
	['^AEGO','^AEGO','AEGO',''],
	['^AFOX','^AFOX','AFOX',''],
	['^(Agile|AGI)','^(AGI|Agile\s?Gear\s?Int[a-z]*)','AGI',''],
	['^Aigo','^Aigo','Aigo',''],
	['^Aireye','^Aireye','Aireye',''],
	['^Alcatel','^Alcatel','Alcatel',''],
	['^(Alcor(\s?Micro)?|058F)','^(Alcor(\s?Micro)?|058F)','Alcor Micro',''],
	['^Alfawise','^Alfawise','Alfawise',''],
	['^Android','^Android','Android',''],
	['^ANACOMDA','^ANACOMDA','ANACOMDA',''],
	['^Anucell','^Anucell','Anucell',''],
	['^Apotop','^Apotop','Apotop',''],
	# must come before AP|Apacer
	['^(APPLE|iPod|SSD\sSM\d+[CEGT])','^APPLE','Apple',''],
	['^(AP|Apacer)','^Apacer','Apacer',''],
	['^(Apricom|SATAWire)','^Apricom','Apricom',''],
	['^(A-?RAM|ARSSD)','^A-?RAM','A-RAM',''],
	['^Arch','^Arch(\s*Memory)?','Arch Memory',''],
	['^(Asenno|AS[1-9])','^Asenno','Asenno',''],
	['^Asgard','^Asgard','Asgard',''],
	['^(ASM|2115)','^ASM','ASMedia',''],#asm1153e
	['^ASolid','^ASolid','ASolid',''],
	['^(AVEXIR|AVSSD)','^AVEXIR','Avexir',''],
	['^Axiom','^Axiom','Axiom',''],
	['^(Baititon|BT\d)','^Baititon','Baititon',''],
	['^Bamba','^Bamba','Bamba',''],
	['^(Beckhoff)','^Beckhoff','Beckhoff',''],
	['^Bell\b','^Bell','Packard Bell',''],
	['^(BelovedkaiAE|GhostPen)','^BelovedkaiAE','BelovedkaiAE',''],
	['^(BHT|WR20)','^BHT','BHT',''],
	['^(Big\s?Reservoir|B[RG][_\s-])','^Big\s?Reservoir','Big Reservoir',''],
	['^BIOSTAR','^BIOSTAR','Biostar',''],
	['^BIWIN','^BIWIN','BIWIN',''],
	['^Blackpcs','^Blackpcs','Blackpcs',''],
	['^(BlitzWolf|BW-?PSSD)','^BlitzWolf','BlitzWolf',''],
	['^(BlueRay|SDM\d)','^BlueRay','BlueRay',''],
	['^Bory','^Bory','Bory',''],
	['^Braveeagle','^Braveeagle','BraveEagle',''],
	['^(BUFFALO|BSC)','^BUFFALO','Buffalo',''], # usb: BSCR05TU2
	['^Bugatek','^Bugatek','Bugatek',''],
	['^Bulldozer','^Bulldozer','Bulldozer',''],
	['^BUSlink','^BUSlink','BUSlink',''],
	['^(Canon|MP49)','^Canon','Canon',''],
	['^Centerm','^Centerm','Centerm',''],
	['^(Centon|DS pro)','^Centon','Centon',''],
	['^(CFD|CSSD)','^CFD','CFD',''],
	['^CHIPAL','^CHIPAL','CHIPAL',''],
	['^(Chipsbank|CHIPSBNK)','^Chipsbank','Chipsbank',''],
	['^Clover','^Clover','Clover',''],
	['^CODi','^CODi','CODi',''],
	['^Colorful\b','^Colorful','Colorful',''],
	# note: www.cornbuy.com is both a brand and also sells other brands, like newegg
	# addlink; colorful; goldenfir; kodkak; maxson; netac; teclast; vaseky
	['^Corn','^Corn','Corn',''],
	['^CnMemory|Spaceloop','^CnMemory','CnMemory',''],
	['^(Creative|(Nomad\s?)?MuVo)','^Creative','Creative',''],
	['^CSD','^CSD','CSD',''],
	['^(Dane-?Elec|Z Mate)','^Dane-?Elec','DaneElec',''],
	['^DATABAR','^DATABAR','DataBar',''],
	# Daplink vfs is an ARM software thing
	['^Dataram','^Dataram','Dataram',''],
	['^DELAIHE','^DELAIHE','DELAIHE',''],
	# DataStation can be Trekstore or I/O gear
	['^Dell\b','^Dell','Dell',''],
	['^DeLOCK','^Delock(\s?products)?','Delock',''],
	['^Derler','^Derler','Derler',''],
	['^detech','^detech','DETech',''],
	['^DGM','^DGM\b','DGM',''],
	['^(DICOM|MAESTRO)','^DICOM','DICOM',''],
	['^Digifast','^Digifast','Digifast',''],
	['^DIGITAL\s?FILM','DIGITAL\s?FILM','Digital Film',''],
	['^(Digma|Run(\sY2)?\b)','^Digma','Digma',''],
	['^Dikom','^Dikom','Dikom',''],
	['^Disain','^Disain','Disain',''],
	['^(Disney|PIX[\s]?JR)','^Disney','Disney',''],
	['^(Doggo|DQ-|Sendisk|Shenchu)','^(doggo|Sendisk(.?Shenchu)?|Shenchu(.?Sendisk)?)','Doggo (SENDISK/Shenchu)',''],
	['^(Dogfish|M\.2 2242|Shark)','^Dogfish(\s*Technology)?','Dogfish Technology',''],
	['^DragonDiamond','^DragonDiamond','DragonDiamond',''],
	['^(DREVO\b|X1\s\d+[GT])','^DREVO','Drevo',''],
	['^DSS','^DSS DAHUA','DSS DAHUA',''],
	['^(Duex|DX\b)','^Duex','Duex',''], # DX\d may be starter for sandisk string
	['^(Dynabook|AE[1-3]00)','^Dynabook','Dynabook',''],
	# DX1100 is probably sandisk, but could be HP, or it could be hp branded sandisk
	['^(Eaget|V8$)','^Eaget','Eaget',''],
	['^(Easy[\s-]?Memory)','^Easy[\s-]?Memory','Easy Memory',''],
	['^EDGE','^EDGE','EDGE Tech',''],
	['^Elecom','^Elecom','Elecom',''],
	['^Eluktro','^Eluktronics','Eluktronics',''],
	['^Emperor','^Emperor','Emperor',''],
	['^Emtec','^Emtec','Emtec',''],
	['^ENE\b','^ENE','ENE',''],
	['^Energy','^Energy','Energy',''],
	['^eNova','^eNOVA','eNOVA',''],
	['^Epson','^Epson','Epson',''],
	['^(Etelcom|SSD051)','^Etelcom','Etelcom',''],
	['^EURS','^EURS','EURS',''],
	['^eVAULT','^eVAULT','eVAULT',''],
	# NOTE: ESA3... may be IBM PCIe SAD card/drives
	['^(EXCELSTOR|r technology)','^EXCELSTOR( TECHNO(LOGY)?)?','ExcelStor',''],
	['^EYOTA','^EYOTA','EYOTA',''],
	['^EZCOOL','^EZCOOL','EZCOOL',''],
	['^EZLINK','^EZLINK','EZLINK',''],
	['^Fantom','^Fantom( Drive[s]?)?','Fantom Drives',''],
	['^Fanxiang','^Fanxiang','Fanxiang',''],
	['^(Faspeed|K3[\s-])','^Faspeed','Faspeed',''],
	['^FASTDISK','^FASTDISK','FASTDISK',''],
	['^Festtive','^Festtive','Festtive',''],
	['^FiiO','^FiiO','FiiO',''],
	['^Fordisk','^Fordisk','Fordisk',''],
	# FK0032CAAZP/FB160C4081 FK or FV can be HP but can be other things
	['^(FORESEE|B[123]0)|P900F|S900M','^FORESEE','Foresee',''],
	['^Founder','^Founder','Founder',''],
	['^(FOXLINE|FLD)','^FOXLINE','Foxline',''], # russian vendor?
	['^(GALAX\b|Gamer\s?L|TA\dD|Gamer[\s-]?V)','^GALAX','GALAX',''],
	['^Freecom','^Freecom(\sFreecom)?','Freecom',''],
	['^Gaiver','^Gaiver','Gaiver',''],
	['^Galaxy\b','^Galaxy','Galaxy',''],
	['^Gamer[_\s-]?Black','^Gamer[_\s-]?Black','Gamer Black',''],
	['^(Garmin|Fenix|Nuvi|Zumo)','^Garmin','Garmin',''],
	['^Geil','^Geil','Geil',''],
	['^GelL','^GelL','GelL',''], # typo for Geil? GelL ZENITH R3 120GB
	['^(Generic|G1J3|SCA128|SLD|UY[67])','^Generic','Generic',''],
	['^(Genesis(\s?Logic)?|05e3)','(Genesis(\s?Logic)?|05e3)','Genesis Logic',''],
	['^Geonix','^Geonix','Geonix',''],
	['^Getrich','^Getrich','Getrich',''],
	['^(Gigabyte|GP-G)','^Gigabyte','Gigabyte',''], # SSD
	['^Gigastone','^Gigastone','Gigastone',''],
	['^Gigaware','^Gigaware','Gigaware',''],
	['^(Gloway|FER\d)','^Gloway','Gloway',''],
	['^GLOWY','^GLOWY','Glowy',''],
	['^Goldendisk','^Goldendisk','Goldendisk',''],
	['^Goldenfir','^Goldenfir','Goldenfir',''],
	['^Golden[\s_-]?Memory','^Golden[\s_-]?Memory','Golden Memory',''],
	['^(Goldkey|GKP)','^Goldkey','GoldKey',''],
	# Wilk Elektronik SA, poland
	['^(Wilk\s*)?(GOODRAM|GOODDRIVE|IR[\s-]?SSD|IRP|SSDPR|Iridium)','^GOODRAM','GOODRAM',''],
	['^Gritronix','^Gritronixx?','Gritronix',''],
	# supertalent also has FM: |FM
	['^(G[\.]?SKILL)','^G[\.]?SKILL','G.SKILL',''],
	['^G[\s-]*Tech','^G[\s-]*Tech(nology)?','G-Technology',''],
	['^(Hajaan|HS[1-9])','^Haajan','Haajan',''],
	['^Haizhide','^Haizhide','Haizhide',''],
	['^(Hama|FlashPen\s?Fancy)','^Hama','Hama',''],
	['^HDC','^HDC\b','HDC',''],
	['^Hectron','^Hectron','Hectron',''],
	['^HEMA','^HEMA','HEMA',''],
	['(HEORIADY|^HX-0)','^HEORIADY','HEORIADY',''],
	['^(Hikvision|HKVSN|HS-SSD)','^Hikvision','Hikvision',''],
	['^Hoodisk','^Hoodisk','Hoodisk',''],
	['^HUAWEI','^HUAWEI','Huawei',''],
	['^Hypertec','^Hypertec','Hypertec',''],
	['^HyperX','^HyperX','HyperX',''],
	['^(Hyundai|Sapphire)','^Hyundai','Hyundai',''],
	['^(IBM|DT|ESA[1-9]|ServeRaid)','^IBM','IBM',''], # M5110 too common
	['^IEI Tech','^IEI Tech(\.|nology)?( Corp(\.|oration)?)?','IEI Technology',''],
	['^(IGEL|UD Pocket)','^IGEL','IGEL',''],
	['^(Imation|Nano\s?Pro|HQT)','^Imation(\sImation)?','Imation',''], # Imation_ImationFlashDrive; TF20 is imation/tdk
	['^(IMC|Kanguru)','^IMC\b','IMC',''],
	['^(Inateck|FE20)','^Inateck','Inateck',''],
	['^(Inca\b|Npenterprise)','^Inca','Inca',''],
	['^(Indilinx|IND-)','^Indilinx','Indilinx',''],
	['^INDMEM','^INDMEM','INDMEM',''],
	['^(Infokit)','^Infokit','Infokit',''],
	# note: Initio default controller, means master/slave jumper is off/wrong, not a vendor
	['^Inland','^Inland','Inland',''],
	['^(InnoDisk|Innolite|SATA\s?Slim|DRPS)','^InnoDisk( Corp.)?','InnoDisk',''],
	['(Innostor|1f75)','(Innostor|1f75)','Innostor',''],
	['(^Innovation|Innovation\s?IT)','Innovation(\s*IT)?','Innovation IT',''],
	['^Innovera','^Innovera','Innovera',''],
	['^(I\.?norys|INO-?IH])','^I\.?norys','I.norys',''],
	['^Intaiel','^Intaiel','Intaiel',''],
	['^(INM|Integral|V\s?Series)','^Integral(\s?Memory)?','Integral Memory',''],
	['^(lntenso|Intenso|(Alu|Basic|Business|Micro|c?Mobile|Premium|Rainbow|Slim|Speed|Twister|Ultra) Line|Rainbow)','^Intenso','Intenso',''],
	['^(I-?O Data|HDCL)','^I-?O Data','I-O Data',''], 
	['^(INO-|i\.?norys)','^i\.?norys','i.norys',''], 
	['^(Integrated[\s-]?Technology|IT\d+)','^Integrated[\s-]?Technology','Integrated Technology',''], 
	['^(Iomega|ZIP\b|Clik!)','^Iomega','Iomega',''], 
	['^ISOCOM','^ISOCOM','ISOCOM (Shenzhen Longsys Electronics)',''],
	['^iTE[\s-]*Tech','^iTE[\s-]*Tech(nology)?','iTE Tech',''],
	['^(James[\s-]?Donkey|JD\d)','^James[\s-]?Donkey','James Donkey',''], 
	['^(Jaster|JS\d)','^Jaster','Jaster',''], 
	['^JingX','^JingX','JingX',''], #JingX 120G SSD - not confirmed, but guessing
	['^Jingyi','^Jingyi','Jingyi',''],
	# NOTE: ITY2 120GB hard to find
	['^JMicron','^JMicron(\s?Tech(nology)?)?','JMicron Tech',''], #JMicron H/W raid
	['^JSYERA','^JSYERA','Jsyera',''],
	['^(Jual|RX7)','^Jual','Jual',''], 
	['^Kazuk','^Kazuk','Kazuk',''],
	['(\bKDI\b|^OM3P)','\bKDI\b','KDI',''],
	['^KEEPDATA','^KEEPDATA','KeepData',''],
	['^KLLISRE','^KLLISRE','KLLISRE',''],
	['^KimMIDI','^KimMIDI','KimMIDI',''],
	['^Kimtigo','^Kimtigo','Kimtigo',''],
	['^Kingbank','^Kingbank','Kingbank',''],
	['^Kingchux[\s-]?ing','^Kingchux[\s-]?ing','Kingchuxing',''],
	['^KINGCOMP','^KINGCOMP','KingComp',''],
	['(KingDian|^NGF|S(280|400))','KingDian','KingDian',''],
	['^(Kingfast|TYFS)','^Kingfast','Kingfast',''],
	['^KingMAX','^KingMAX','KingMAX',''],
	['^Kingrich','^Kingrich','Kingrich',''],
	['^Kingsand','^Kingsand','Kingsand',''],
	['KING\s?SHA\s?RE','KING\s?SHA\s?RE','KingShare',''],
	['^(KingSpec|ACSC|C3000|KS[DQ]|N[ET]-\d|P3$|P4\b|PA[_-]?(18|25)|Q-180|T-(3260|64|128)|Z(\d\s|F\d))','^KingSpec','KingSpec',''],
	['^KingSSD','^KingSSD','KingSSD',''],
	# kingwin docking, not actual drive
	['^(EZD|EZ-Dock)','','Kingwin Docking Station',''],
	['^Kingwin','^Kingwin','Kingwin',''],
	['^KLLISRE','^KLLISRE','KLLISRE',''],
	['(KIOXIA|^K[BX]G\d)','KIOXIA','KIOXIA',''], # company name comes after product ID
	['^(KLEVV|NEO\sN|CRAS)','^KLEVV','KLEVV',''],
	['^Kodak','^Kodak','Kodak',''],
	['^(KUAIKAI|MSAM)','^KUAIKAI','KuaKai',''],
	['(KUIJIA|DAHUA)','^KUIJIA','KUIJIA',''],
	['^KUNUP','^KUNUP','KUNUP',''],
	['^KUU','^KUU\b','KUU',''], # KUU-128GB
	['^(Lacie|P92|itsaKey|iamaKey)','^Lacie','LaCie',''],
	['^LANBO','^LANBO','LANBO',''],
	['^LANTIC','^LANTIC','Lantic',''],
	['^Lapcare','^Lapcare','Lapcare',''],
	['^(Lazos|L-?ISS)','^Lazos','Lazos',''],
	['^LDLC','^LDLC','LDLC',''],
	# LENSE30512GMSP34MEAT3TA / UMIS RPITJ256PED2MWX
	['^(LEN|UMIS)','^Lenovo','Lenovo',''],
	['^RPFT','','Lenovo O.E.M.',''],
	# JAJS300M120C JAJM600M256C JAJS600M1024C JAJS600M256C JAJMS600M128G 
	['^(Leven|JAJ[MS])','^Leven','Leven',''],
	['^(LG\b|Xtick)','^LG','LG',''],
	['(LITE[-\s]?ON[\s-]?IT)','LITE[-]?ON[\s-]?IT','LITE-ON IT',''], # LITEONIT_LSS-24L6G
	# PH6-CE240-L; CL1-3D256-Q11 NVMe LITEON 256GB
	['(LITE[-\s]?ON|^PH[1-9]|^DMT|^CV\d-|L(8[HT]|AT|C[HST]|JH|M[HST]|S[ST])-|^S900)','LITE[-]?ON','LITE-ON',''], 
	['^LONDISK','^LONDISK','LONDISK',''],
	['^Longline','^Longline','Longline',''],
	['^LuminouTek','^LuminouTek','LuminouTek',''],
	['^(LSI|MegaRAID)','^LSI\b','LSI',''],
	['^(M-Systems|DiskOnKey)','^M-Systems','M-Systems',''],
	['^(Mach\s*Xtreme|MXSSD|MXU|MX[\s-])','^Mach\s*Xtreme','Mach Xtreme',''],
	['^(MacroVIP|MV\d)','^MacroVIP','MacroVIP',''],
	['^Mainic','^Mainic','Mainic',''],
	['^Maxell','^Maxell','Maxell',''],
	['^Maximus','^Maximus','Maximus',''],
	['^Maxone','^Maxone','Maxone',''],
	['^(Memorex|TravelDrive|TD\s?Classic)','^Memorex','Memorex',''],
	['^(MARSHAL\b|MAL\d)','^MARSHAL','Marshal',''],
	['^MARVELL','^MARVELL','Marvell',''],
	['^Maxsun','^Maxsun','Maxsun',''],
	['^MDT\b','^MDT','MDT (rebuilt WD/Seagate)',''], # mdt rebuilds wd/seagate hdd
	# MD1TBLSSHD, careful with this MD starter!!
	['^MD[1-9]','^Max\s*Digital','MaxDigital',''],
	['^Medion','^Medion','Medion',''],
	['^(MEDIAMAX|WL\d{2})','^MEDIAMAX','MediaMax',''],
	['^Mengmi','^Mengmi','Mengmi',''],
	['^MGTEC','^MGTEC','MGTEC',''],
	# must come before micron
	['^(Mtron|MSP)','^Mtron','Mtron',''],
	# note: C300/400 can be either micron or crucial, but C400 is M4 from crucial
	['(^(Micron|2200[SV]|MT|M5|(\d+|[CM]\d+)\sMTF)|00-MT)','^Micron','Micron',''],# C400-MTFDDAK128MAM
	['^(Microsoft|S31)','^Microsoft','Microsoft',''],
	['^MidasForce','^MidasForce','MidasForce',''],
	['^Milan','^Milan','Milan',''],
	['^(Mimoco|Mimobot)','^Mimoco','Mimoco',''],
	['^MINIX','^MINIX','MINIX',''],
	['^Miracle','^Miracle','Miracle',''],
	['^MLLSE','^MLLSE','MLLSE',''],
	['^Moba','^Moba','Moba',''],
	# Monster MONSTER DIGITAL
	['^(Monster\s)+(Digital)?|OD[\s-]?ADVANCE','^(Monster\s)+(Digital)?','Monster Digital',''],
	['^Morebeck','^Morebeck','Morebeck',''],
	['^(Moser\s?Bear|MBIL)','^Moser\s?Bear','Moser Bear',''],
	['^(Motile|SSM\d)','^Motile','Motile',''],
	['^(Motorola|XT\d{4})','^Motorola','Motorola',''],
	['^Moweek','^Moweek','Moweek',''],
	#MRMAD4B128GC9M2C
	['^(MRMA|Memoright)','^Memoright','Memoright',''],
	['^MSI\b','^MSI\b','MSI',''],
	['^MTASE','^MTASE','MTASE',''],
	['^MTRON','^MTRON','MTRON',''],
	['^(MyDigitalSSD|BP[4X])','^MyDigitalSSD','MyDigitalSSD',''], # BP4 = BulletProof4
	['^(Myson)','^Myson([\s-]?Century)?([\s-]?Inc\.?)?','Myson Century',''],
	['^(Neo\s*Forza|NFS\d)','^Neo\s*Forza','Neo Forza',''],
	['^(Netac|OnlyDisk|S535N)','^Netac','Netac',''],
	['^NFHK','^NFHK','NFHK',''],
	# NGFF is a type, like msata, sata
	['^Nik','^Nikimi','Nikimi',''],
	['^NOREL','^NOREL(SYS)?','NorelSys',''],
	['^ODYS','^ODYS','ODYS',''],
	['^Olympus','^Olympus','Olympus',''],
	['^Orico','^Orico','Orico',''],
	['^Ortial','^Ortial','Ortial',''],
	['^OSC','^OSC\b','OSC',''],
	['^oyunkey','^oyunkey','Oyunkey',''],
	['^PALIT','PALIT','Palit',''], # ssd 
	['^Panram','^Panram','Panram',''], # ssd 
	['^(Parker|TP00)','^Parker','Parker',''],
	['^(Pasoul|OASD)','^Pasoul','Pasoul',''],
	['^(Patriot|PS[8F]|P2\d{2}|PBT|VPN|Viper|Burst|Blast|Blaze|Pyro|Ignite)','^Patriot([-\s]?Memory)?','Patriot',''],#Viper M.2 VPN100
	['^PERC\b','','Dell PowerEdge RAID Card',''], # ssd 
	['(PHISON[\s-]?|ESR\d)','PHISON[\s-]?','Phison',''],# E12-256G-PHISON-SSD-B3-BB1
	['^(Pichau[\s-]?Gaming|PG\d{2})','^Pichau[\s-]?Gaming','Pichau Gaming',''],
	['^Pioneer','Pioneer','Pioneer',''],
	['^Platinet','Platinet','Platinet',''],
	['^(PLEXTOR|PX-)','^PLEXTOR','Plextor',''],
	['^(PQI|Intelligent\s?Stick|Cool\s?Drive)','^PQI','PQI',''],
	['^(Premiertek|QSSD|Quaroni)','^Premiertek','Premiertek',''],
	['^(-?Pretec|UltimateGuard)','-?Pretec','Pretec',''],
	['^(Prolific)','^Prolific( Technolgy Inc\.)?','Prolific',''],
	# PS3109S9 is the result of an error condition with ssd drive
	['^PUSKILL','^PUSKILL','Puskill',''],
	['QEMU','^\d*QEMU( QEMU)?','QEMU',''], # 0QUEMU QEMU HARDDISK
	['(^Quantum|Fireball)','^Quantum','Quantum',''],
	['^QUMO','^QUMO','Qumo',''],
	['^Qunion','^Qunion','Qunion',''],
	['^(R[3-9]|AMD\s?(RADEON)?|Radeon)','AMD\s?(RADEON)?','AMD Radeon',''], # ssd 
	['^(Ramaxel|RT|RM|RPF|RDM)','^Ramaxel','Ramaxel',''],
	['^(Ramsta|R[1-9])','^Ramsta','Ramsta',''],
	['^RCESSD','^RCESSD','RCESSD',''],
	['^(Realtek|RTL)','^Realtek','Realtek',''],
	['^(Reletech)','^Reletech','Reletech',''], # id: P400 but that's too short
	['^RENICE','^RENICE','Renice',''],
	['^RevuAhn','^RevuAhn','RevuAhn',''],
	['^(Ricoh|R5)','^Ricoh','Ricoh',''],
	['^RIM[\s]','^RIM','RIM',''],
	 #RTDMA008RAV2BWL comes with lenovo but don't know brand
	['^Runcore','^Runcore','Runcore',''],
	['^(S3Plus|S3\s?SSD)','^S3Plus','S3Plus',''],
	['^(Sabrent|Rocket)','^Sabrent','Sabrent',''],
	['^Sage','^Sage(\s?Micro)?','Sage Micro',''],
	['^SAMSWEET','^SAMSWEET','Samsweet',''],
	['^SandForce','^SandForce','SandForce',''],
	['^Sannobel','^Sannobel','Sannobel',''],
	['^(Sansa|fuse\b)','^Sansa','Sansa',''],
	# SATADOM can be innodisk or supermirco: dom == disk on module
	# SATAFIRM is an ssd failure message
	['^(Sea\s?Tech|Transformer)','^Sea\s?Tech','Sea Tech',''],
	['^SigmaTel','^SigmaTel','SigmaTel',''],
	# DIAMOND_040_GB
	['^(SILICON\s?MOTION|SM\d|090c)','^(SILICON\s?MOTION|090c)','Silicon Motion',''],
	['(Silicon[\s-]?Power|^SP[CP]C|^Silicon|^Diamond|^HasTopSunlightpeed)','Silicon[\s-]?Power','Silicon Power',''],
	# simple drive could also maybe be hgst
	['^(Simple\s?Tech|Simple[\s-]?Drive)','^Simple\s?Tech','SimpleTech',''],
	['^SINTECHI?','^SINTECHI?','SinTech (adapter)',''],
	['^SiS\b','^SiS','SiS',''],
	['Smartbuy','\s?Smartbuy','Smartbuy',''], # SSD Smartbuy 60GB; mSata Smartbuy 3
	# HFS128G39TND-N210A; seen nvme with name in middle
	['(SK\s?HYNIX|^HF[MS]|^H[BC]G|^BC\d{3}|^SC[234]\d\d\sm?SATA)','\s?SK\s?HYNIX','SK Hynix',''], 
	['(hynix|^HAG\d|h[BC]8aP|PC\d{3})','hynix','Hynix',''],# nvme middle of string, must be after sk hynix
	['^SH','','Smart Modular Tech.',''],
	['^Skill','^Skill','Skill',''],
	['^(SMART( Storage Systems)?|TX)','^(SMART( Storage Systems)?)','Smart Storage Systems',''],
	['^Sobetter','^Sobetter','Sobetter',''],
	['^(S[FR]-|Sony|IM9)','^Sony','Sony',''],
	['^(SSSTC|CL1-)','^SSSTC','SSSTC',''],
	['^STE[CK]','^STE[CK]','sTec',''], # wd bought this one
	['^STORFLY','^STORFLY','StorFly',''],
	['\dSUN\d','^SUN(\sMicrosystems)?','Sun Microsystems',''],
	['^Sundisk','^Sundisk','Sundisk',''],
	['^SUNEAST','^SUNEAST','SunEast',''],
	['^SuperMicro','^SuperMicro','SuperMicro',''],
	['^Supersonic','^Supersonic','Supersonic',''],
	['^SuperSSpeed','^SuperSSpeed','SuperSSpeed',''],
	# NOTE: F[MNETU] not reliable, g.skill starts with FM too: 
	# Seagate ST skips STT. 
	['^(Super\s*Talent|STT|F[HTZ]M\d|PicoDrive|Teranova)','','Super Talent',''], 
	['^(SF|Swissbit)','^Swissbit','Swissbit',''],
	# ['^(SUPERSPEED)','^SUPERSPEED','SuperSpeed',''], # superspeed is a generic term
	['^Taisu','^Taisu','Taisu',''],
	['^(TakeMS|ColorLine)','^TakeMS','TakeMS',''],
	['^Tammuz','^Tammuz','Tammuz',''],
	['^TANDBERG','^TANDBERG','Tanberg',''],
	['^(TC[\s-]*SUNBOW|X3\s\d+[GT])','^TC[\s-]*SUNBOW','TCSunBow',''],
	['^(TDK|TF[1-9]\d|LoR)','^TDK','TDK',''],
	['^TEAC','^TEAC','TEAC',''],
	['^(TEAM|T[\s-]?Create|L\d\s?Lite|T\d{3,}[A-Z]|TM\d|(Dark\s?)?L3\b|T[\s-]?Force)','^TEAM(\s*Group)?','TeamGroup',''],
	['^(Teclast|CoolFlash)','^Teclast','Teclast',''],
	['^Teelkoou','^Teelkoou','Teelkoou',''],
	['^Tele2','^Tele2','Tele2',''],
	['^Teleplan','^Teleplan','Teleplan',''],
	['^TEUTONS','^TEUTONS','TEUTONS',''],
	['^(Textorm)','^Textorm','Textorm',''], # B5 too short
	['^THU','^THU','THU',''],
	['^Tiger[\s_-]?Jet','^Tiger[\s_-]?Jet','TigerJet',''],
	['^Tigo','^Tigo','Tigo',''],
	['^(Timetec|35TT)','^Timetec','Timetec',''],
	['^TKD','^TKD','TKD',''],
	['^TopSunligt','^TopSunligt','TopSunligt',''], # is this a typo? hard to know
	['^TopSunlight','^TopSunlight','TopSunlight',''],
	['^TOROSUS','^TOROSUS','Torosus',''],
	['(Transcend|^((SSD\s|F)?TS|EZEX|USDU)|1307|JetDrive|JetFlash)','\b(Transcend|1307)\b','Transcend',''], 
	['^(TrekStor|DS (maxi|pocket)|DataStation)','^TrekStor','TrekStor',''],
	['^Turbox','^Turbox','Turbox',''],
	['^(TwinMOS|TW\d)','^TwinMOS','TwinMOS',''],
	# note: udisk means usb disk, it's not a vendor ID
	['^UDinfo','^UDinfo','UDinfo',''],
	['^UMAX','^UMAX','UMAX',''],
	['^(UMIS|RP[IJ]TJ)','^UMIS','UMIS',''],
	['^USBTech','^USBTech','USBTech',''],
	['^(UNIC2)','^UNIC2','UNIC2',''],
	['^(UG|Unigen)','^Unigen','Unigen',''],
	['^(USBest|UT16)','^USBest','USBest',''],
	['^(OOS[1-9]|Utania)','Utania','Utania',''],
	['^U-TECH','U-TECH','U-Tech',''],
	['^VBOX','','VirtualBox',''],
	['^(Veno|Scorp)','^Veno','Veno',''],
	['^(Verbatim|STORE\s?\'?N\'?\s?(FLIP|GO)|Vi[1-9]|OTG\s?Tiny)','^Verbatim','Verbatim',''],
	['^V-GEN','^V-GEN','V-Gen',''],
	['^V[\s-]?(7|Seven)','^V[\s-]?(7|Seven)\b','VSeven',''],
	['^(Victorinox|Swissflash)','^Victorinox','Victorinox',''],
	['^(Visipro|SDVP)','^Visipro','Visipro',''],
	['^VISIONTEK','^VISIONTEK','VisionTek',''],
	['^VMware','^VMware','VMware',''],
	['^(Vseky|Vaseky|V8\d{2})','^Vaseky','Vaseky',''], # ata-Vseky_V880_350G_
	['^(Walgreen|Infinitive)','^Walgreen','Walgreen',''],
	['^Walram','^Walram','WALRAM',''],
	['^Walton','^Walton','Walton',''],
	['^(Wearable|Air-?Stash)','^Wearable','Wearable',''],
	['^Wellcomm','^Wellcomm','Wellcomm',''],
	['^(wicgtyp|N900)','^wicgtyp','wicgtyp',''],
	['^Wilk','^Wilk','Wilk',''],
	['^(WinMemory|SWG\d)','^WinMemory','WinMemory',''],
	['^(Winton|WT\d{2})','^Winton','Winton',''],
	['^WPC','^WPC','WPC',''], # WPC-240GB
	['^(Wortmann(\sAG)?|Terra\s?US)','^Wortmann(\sAG)?','Wortmann AG',''],
	['^(XinTop|XT-)','^XinTop','XinTop',''],
	['^Xintor','^Xintor','Xintor',''],
	['^XPG','^XPG','XPG',''],
	['^XrayDisk','^XrayDisk','XrayDisk',''],
	['^Xstar','^Xstar','Xstar',''],
	['^(XUM|HX\d)','^XUM','XUM',''],
	['^XUNZHE','^XUNZHE','XUNZHE',''],
	['^(Yangtze|ZhiTai|PC00[5-9]|SC00[1-9])','^Yangtze(\s*Memory)?','Yangtze Memory',''],
	['^(Yeyian|valk)','^Yeyian','Yeyian',''],
	['^(YingChu|YGC)','^YingChu','YingChu',''],
	['^(YUCUN|R880)','^YUCUN','YUCUN',''],
	['^(ZALMAN|ZM\b)','^ZALMAN','Zalman',''],
	# Zao/J.Zau: marvell ssd controller
	['^ZXIC','^ZXIC','ZXIC',''],
	['^(Zebronics|ZEB)','^Zebronics','Zebronics',''],
	['^Zenfast','^Zenfast','Zenfast',''],
	['^Zenith','^Zenith','Zenith',''],
	['^ZEUSLAP','^ZEUSLAP','ZEUSLAP',''],
	['^(Zheino|CHN|CNM)','^Zheino','Zheino',''],
	['^(Zotac|ZTSSD)','^Zotac','Zotac',''],
	['^ZSPEED','^ZSPEED','ZSpeed',''],
	['^ZTC','^ZTC','ZTC',''],
	['^ZTE','^ZTE','ZTE',''],
	['^(ZY|ZhanYao)','^ZhanYao([\s-]?data)','ZhanYao',''],
	['^(ASMT|2115)','^ASMT','ASMT (case)',''],
	];
	eval $end if $b_log;
}
## END DISK VENDOR BLOCK ##
# 
# You should not need to change device_vendor(), but if you do, make sure to 
#  also change the version in pinxi at the same time.
sub disk_vendor {
	eval $start if $b_log;
	my ($model,$serial) = @_;
	my ($vendor) = ('');
	return if !$model;
	# 0 - match pattern; 1 - replace pattern; 2 - vendor print; 3 - serial pattern
	# Data URLs: inxi-resources.txt Section: DriveItem device_vendor()
	# $model = 'H10 HBRPEKNX0202A NVMe INTEL 512GB';
	# $model = 'Patriot Memory';
	set_disk_vendors() if !$vendors;
	# prefilter this one, some usb enclosurs and wrong master/slave hdd show default
	$model =~ s/^Initio[\s_]//i;
	foreach my $row (@$vendors){
		if ($model =~ /$row->[0]/i || ($row->[3] && $serial && $serial =~ /$row->[3]/)){
			$vendor = $row->[2];
			# Usually we want to assign N/A at output phase, maybe do this logic there?
			if ($row->[1]){
				if ($model !~ m/$row->[1]$/i){
					$model =~ s/$row->[1]//i;
				}
				else {
					$model = 'N/A';
				}
			}
			$model =~ s/^[\/\[\s_-]+|[\/\s_-]+$//g;
			$model =~ s/\s\s/ /g;
			last;
		}
	}
	eval $end if $b_log;
	return [$vendor,$model];
}

sub process {
	my (@disks,@disks_removable,@disks_standard,@sizes);
	my ($holder,$type_holder) = ('','');
	say "Starting processing of disk data in $disks_read.";
	say "There are " . scalar @$data . " disk names in the list.";
	say "This can take a while. Be patient...";
	@$data = sort { lc($a) cmp lc($b) } @$data;
	uniq($data);
	push(@$data,'#-EOF-#');
	foreach my $disk (@$data){
		# it's always going to have type: set in the primary data file
		$disk =~ s/^\s*type:\s*(0-int|0-na|FireWire|ThunderBolt|USB)\s+model:\s*//i;
		my $type = ($1) ? $1 : '0-na';
		$disk =~ s/_/ /g;
		my $size = $disk;
		$size =~ s/^.*\s+size:\s+//;
		$disk =~ s/\s+size:.+$//;
		if ($type && $type eq '0-int' && $disk =~ /Flash\s?D(isk|rive)/){
			$type = 'USB';
		}
		if (lc($holder) eq lc($disk)){
			push(@sizes,$size) if $size && !grep {$_ eq $size} @sizes;
		}
		else {
			my $result = ($holder) ? disk_vendor($holder,0) : ();
			# say "$holder :: $disk";
			if ($holder && !$result->[0] && @sizes){
				my $data = 'type: ' . $type_holder . ' model: ' . $holder . ' size: ' . join('/',@sizes);
				if ($type_holder eq '0-int' || $type_holder eq '0-na'){
					push(@disks_standard,$data);
				}
				else {
					push(@disks_removable,$data);
				}}
			last if $disk eq '#-EOF-#';
			@sizes = ();
			push(@sizes,$size) if $size;
			$holder = $disk;
			$type_holder = $type;
		}
	}
	# note, lc is character set agnostic
	@disks_standard = sort { lc($a) cmp lc($b) } @disks_standard;
	@disks_removable = sort { lc($a) cmp lc($b) } @disks_removable;
	my @disks_unhandled = (@disks_standard, @disks_removable);
	if ($dbg->[1]){
		say $line;
		say "Unhandled Disks:\n$line";
		say join("\n",@disks_unhandled);
	}
	say $line;
	say "There are " . scalar(@disks_unhandled) . " unhandled disks.";
	if (@disks_unhandled){
		write_unhandled(\@disks_unhandled);
	}
	say "Completed unhandled disk vendor processing.";
}
sub write_unhandled {
	my $unhandled = $_[0];
	print "Writing unhandled disk names to $disks_unhandled... ";
	open(my $fh, '>', $disks_unhandled) or die "Could not open file '$disks_unhandled' $!";
	print $fh join("\n",@$unhandled);
	close $fh;
	say "Data written.";
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
}
sub uniq {
	my %seen;
	@{$_[0]} = grep !$seen{$_}++, @{$_[0]};
}
sub checks {
	my @errors;
	if (! -e $self_name ){
		push(@errors,"You must start $self_name from the directory it is located in!");
	}
	if (! -e $disks_raw){
		push(@errors,"Unable to locate $disks_raw file!");
	}
	if (! -r $disks_raw){
		push(@errors,"Unable to read $disks_raw file!");
	}
	if (! -e $disks_unhandled){
		push(@errors,"Unable to locate $disks_unhandled file!");
	}
	if (! -r $disks_unhandled){
		push(@errors,"Unable to read $disks_unhandled file!");
	}
	if (@errors){
		print "The following errors were encountered:\n* ";
		say join("* ", @errors);
		exit 1;
	}
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
	'h|help' => sub {
		show_options();
		exit 0;
	},
	'u|unhandled' => sub {
		$disks_read = $disks_unhandled;
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
	say "                1: Print unhandled disks to screen.";
	say "                2: Print raw driver list data before start of processing.";
	say "-h,--help      - This help option menu";
	say "-u,--unhandled - Use unhandled file instead of primary. Use this after ";
	say "                 the first iteration creating the new master unhandled.";
	say "-v,--version   - Show tool version and date.";
	say '';
	say "Note: make sure to run $self_name on new datasets 1x, then with -u again";
	say "to get rid of some duplicates that the first pass doesn't get. Use -u";
	say "after the first non -u run, after that you will be working only with the";
	say "unhandled list, which is much faster.";
}
sub show_version {
	say "$self_name v: $self_version date: $self_date";
}

sub main {
	checks();
	options();
	reader($disks_read);
	say Dumper $data if $dbg->[2];
	die 'No @$data present!' if !@$data;
	process();
}

main();
