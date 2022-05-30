====================================================================
README for development branch of inxi Perl version: pinxi
====================================================================
FILE:    README.txt
VERSION: 4.0
DATE:    2018-09-01

NOTE: While the real program name will never change, for the sake
of clarity, the inxi-perl branch inxi is called pinxi, so it can be
run next to either inxi-legacy (binxi) or master (inxi).

====================================================================

Clone just this branch:

git clone https://github.com/smxi/inxi --branch inxi-perl --single-branch

Install pinxi for testing. Note that the -U option works the same as 
master branch inxi, so only the initial install is required:

wget -O pinxi https://github.com/smxi/inxi/raw/inxi-perl/pinxi

Shortcut download path for github (easier to remember and type):
wget -O pinxi smxi.org/pinxi

pinxi -U --man also installs the man page from pinxi, which is the 
development branch for the master man page.

====================================================================

Donate:

Help support the project with a one time or sustaining donation.

Paypal: https://www.paypal.com/donate/?hosted_button_id=77DQVM6A4L5E2

Open Collective: https://opencollective.com/inxi

====================================================================

DOCS:

/docs contain the data needed to develop pinxi.

See: docs/Perl-programming.txt
Tips and hints on how to translate other language logic to Perl, and 
Bash stuff in particular. Note, I will never be a Perl expert, nor do 
I want to be. I want the code to be 'newbie' friendly, and to be accessible
to reasonably smart people who do not happen to be Perl experts, but do 
understand basic programming logic. 

Perl was selected because it is much easier to work with than the 
bash/gawk/sed/grep/etc mix that ran in binxi, and because the 5.x 
branch has proved itself to be very solid over years, without breaking 
stuff needlessly on updates. In a way, it was a blessing that Larry 
made Perl6, and now calls it a different language, because that removed  
the pressure from Perl 5 to break itself by trying to become Perl 6. 

See: docs/Perl-setup.txt
How to set up your Perl dev stuff

See: docs/Perl-version-support.txt
Notes on what features can be used for the Perl version. 5.08 is the current 
cutoff. No newer features will be used, this lets inxi maintain its core
mission of supporting almost everything, no matter how old.

See: docs/inxi-data.txt
Notes and some research URLs listed by Package/Function name. This helps
avoid the clutter of the main pinxi/inxi body with data source etc comments.

See: docs/inxi-resources.txt
Listed by Package/function name, URLs used for data sources. Cneck between 
inxi-data.txt and inxi-resources.txt for complete lists since I don't always 
sync those two files.

See: docs/inxi-tools.txt
Core tools available for features and modules. Since most log their 
data, it's always preferable using a core tool than to recode it again.
With some exceptions, for example, extreme repetitions where you want
to remove any possible overhead in the action.

See: docs/inxi-values.txt
User config options; the values of the primary hashes that contain the 
switches used for layout, option control, downloader, konvi etc. 
inxi-values.txt is the primary reference document for working on 
inxi/pinxi.

====================================================================

TOOLS:

There are a few backend tools that are used to generate matching tables for 
various types of data. These are located in inxi-perl/tools/ and all have a -h / 
--help menu and significant and useful debugger output tools so you can see what 
is happening if something isn't working as hoped.

1. cpu_arch.pl - tool to update cp_cpu_arch, as with vendors.pl, this is the 
master copy of cp_cpu_arch, which you copy from cpu_arch.pl to replace 
cp_cpu_arch in pinxi. Includes debuggers to test cpu types, model, stepping,
name strings.

2. disk_vendors.pl - create new set_vendors() sub for pinxi, use this to add new
vendor and vendor product matches. Don't touch if you don't know regex quite 
well!

Creates matching table for disk vendors: item.

* lists/disks.**.txt - the various lists of disk data used, and generated.

3. gpu_ids.pl - tool to generate nvidia microarch and legacy driver ids for the
inxi nvidia graphics architecture and non-free driver information. 

Creates raw matching IDs for gpu_data item, again matching hash tables.

* lists/gpu.[vendor].xxx contain the various text files for arch/legacy 
matching.

4. gpu_raw.pl - generate intel and amd raw id files from source data using some 
clever transformation tricks, makes all source data turn into the same output so 
ids.pl can read it easily.

Creates source data files for ids.pl.

* uses pci.id.xxx files from 2 locations, one global pci ids, and one per type, 
amd and intel for the moment, raw will then transform those into a format ids.pl 
can use.

5. ram_vendors.pl - similar to vendors.pl only much more simple.

====================================================================

BASIC IDEA:

I was sufficiently impressed switching from xiin python script
to creating two small Perl functions to do the primary /sys debugging
actions that Perl for inxi struck me as an increasingly interesting
idea. Plus, Perl was so comically, absurdly, fast, that I could not
ignore it.

Another big reason this is being given real thought is that while 
an absolutely core, primary, requirement, for inxi, is that it run
anywhere, on any nix system, no matter how old (practially speaking,
10 years old or newer), that is, you can pop inxi on an old server
and it will work. Bash + Gawk will always, and has always, met that
requirement, but that combination, with the lack of any real way
to pass data, create complex data structures, etc., has always been 
a huge headache to work with.

However, unlike in 2007, when the basic logic of inxi was started,
and Perl 6 was looming as a full replacement for Perl 5, in 2017, 
Perl 5 is now a standalone project, and seems to have a bright 
future, and given that 5.08 is now old enough to satisfy the basic
run anywhere on anything option, that would be the basic Perl version
that would be used and tested against. I've vacillated a bit between
5.10 and 5.8, but after more research, I've realized there will 
always be old Redhat servers etc out there that are running Perl 5.8,
and there is not a huge gain to using 5.10 from what I can see.

pinxi/inxi has been tested on systems that run 5.08, 5.10, 5.12, 
and of course, modern Perl 5.26. So yes, there are plenty of old 
servers and systems out there still running Perl 5.08.

====================================================================

ROADMAP:

pinxi now running as the development branch of inxi. As such, it will
be either the same as, or ahead of, briefly, inxi, until the two are 
synced, where it starts over.

There is only one feature remaining from the original roadmap that
is left as a to-do:

1. Adding support for language hashes, that would replace the hack 
   key values in the print arrays with the alternate language 
   equivalent. Or, if missing that key, print the english. That would
   solve the issue of people flaking out on language support over time.
   Status: NOT Started (but support is designed in as I go along)

This will only be added if there is real support and interest, there is
an active issue on the master branch inxi about this, so if someone steps
forwards and wants to do contribute, then it will happen, and if nobody 
does, then it will not happen.

====================================================================

BSD Development:

Please note, after really struggling with BSD development, I have 
concluded that I will only do it under these circumstances:

1. a fully tested robust patch that does not break any existing 
logic is given.

2. I am given direct SSH access to the machine, or a machine/OS 
very much like it. VMs do not cut it for most advanced hardware stuff,
but are OK for basic development work.

Anything else is simply too time consuming for me to justify at this 
point. Note that I have access to some BSD machines, and those reflect
accuratnely where the support can go if I have access. This means
ok, but not totally complete, which is the best I can really hope 
for given the diverse state of the BSD OS ecosystem, which is 
simply too splintered to really support at random (didn't anyone ever 
hear the warning fable about sticks in a bundle being harder to break
than a thick stick alone?). But with machine access my experience has 
shown me that I can make quite good progress on most BSDs, at least 
those that have available data, which is not always a given.


