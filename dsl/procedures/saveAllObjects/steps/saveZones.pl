#############################################################################
#
#  Save Zones (in DSL or XML)
#
#  Author: L.Rochette
#
#  Copyright 2015-2019 Electric-Cloud Inc.
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#
# History
# ---------------------------------------------------------------------------
# 2019-Feb-11 lrochette Foundation for merge DSL and XML export
# 2019-Feb 21 lrochette Changing paths to match EC-DslDeploy
#############################################################################
use File::Path;

$[/myProject/scripts/perlHeaderJSON]

#
# Parameters
#
my $path             = '$[pathname]';
my $pattern          = '$[pattern]';
my $includeACLs      = "$[includeACLs]";
my $includeNotifiers = "$[includeNotifiers]";
my $relocatable      = "$[relocatable]";
my $format           = '$[format]';

#
# Global
#
my $errorCount=0;
my $zoneCount=0;

# Get list of Zones
my ($success, $xPath) = InvokeCommander("SuppressLog", "getZones");

# Create the Zones directory
mkpath("$path/zones");
chmod(0777, "$path/zones");

foreach my $node ($xPath->findnodes('//zone')) {
  my $zoneName=$node->{'zoneName'};

  # skip zones that don't fit the pattern
  next if ($zoneName !~ /$pattern/$[caseSensitive] ); # / for color mode

  printf("Saving Zone: %s\n", $zoneName);
  my $fileZoneName=safeFilename($zoneName);
  mkpath("$path/zones/$fileZoneName");
  chmod(0777, "$path/zones/$fileZoneName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/zones/$fileZoneName/zone",
    "/zones[$zoneName]", $relocatable, $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("  Error exporting %s", $zoneName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $zoneCount++;
  }
}
$ec->setProperty("preSummary", createExportString($zoneCount, "zone"));
$ec->setProperty("/myJob/zoneExported", $zoneCount);
exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
