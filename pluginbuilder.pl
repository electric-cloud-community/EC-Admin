#!/usr/bin/env perl

# Build, upload and promote EC-Admin using pluginbuilder
#		https://github.com/electric-cloud/ec-plugin-tool
# to make promotion faster


use Getopt::Long;
use XML::Simple qw(:strict);
use Data::Dumper;
use strict;
use File::Copy;

use ElectricCommander ();
$| = 1;
my $ec = new ElectricCommander->new({timeout => 600});

my $pluginVersion = "4.0.0";
my $pluginKey = "EC-Admin";


# Fix version in plugin.xml
# Update plugin.xml with  version,
print "[INFO] - Processing 'META-INF/plugin.xml' file...\n";
my $xs = XML::Simple->new(
	ForceArray => 1,
	KeyAttr    => { },
	KeepRoot   => 1,
);
my $xmlFile = "META-INF/plugin.xml";
my $ref  = $xs->XMLin($xmlFile);
$ref->{plugin}[0]->{version}[0] = $pluginVersion;
open(my $fh, '>', $xmlFile) or die "Could not open file '$xmlFile' $!";
print $fh $xs->XMLout($ref);
close $fh;

# Read buildCounter
my $buildCounter;
{
  local $/ = undef;
  open FILE, "buildCounter" or die "Couldn't open file: $!";
  $buildCounter = <FILE>;
  close FILE;

 $buildCounter++;
 $pluginVersion .= ".$buildCounter";
 print "[INFO] - Incrementing build number to $buildCounter...\n";

 open FILE, "> buildCounter" or die "Couldn't open file: $!";
 print FILE $buildCounter;
 close FILE;
}
my $pluginName = "${pluginKey}-${pluginVersion}";

print "[INFO] - Creating plugin '$pluginName'\n";

system ("BUILD_NUMBER=$buildCounter pluginbuilder build -df lib -f META-INF -f libs -f pages -f htdocs");

move("build/${pluginKey}.zip", "./${pluginKey}.jar");

# Uninstall old plugin
#print "[INFO] - Uninstalling old plugin...\n";
#$ec->uninstallPlugin($pluginKey) || print "No old plugin\n";

# Install plugin
print "[INFO] - Installing plugin ${pluginKey}.jar...\n";
system ('date');
$ec->installPlugin("${pluginKey}.jar");
system ('date');
print "\n";

# Promote plugin
print "[INFO] - Promoting plugin...\n";
system ('date');
$ec->promotePlugin($pluginName);
system ('date');
