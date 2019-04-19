#############################################################################
#
#  Save Resources (in DSL or XML)
#
#  Author: L.Rochette
#
#  Copyright 2013-2019 Electric-Cloud Inc.
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
my $relocatable      = "$[relocatable]";
my $format           = '$[format]';

#
# Global
#
my $errorCount=0;
my $resCount=0;

# Get list of resources
my ($success, $xPath) = InvokeCommander("SuppressLog", "getResources");

# Create the Resources directory
mkpath("$path/resources");
chmod(0777, "$path/resources");

foreach my $node ($xPath->findnodes('//resource')) {
  my $resName=$node->{'resourceName'};

  # skip resources that don't fit the pattern
  next if ($resName !~ /$pattern/$[caseSensitive] );  # / for color mode

  printf("Saving Resource: %s\n", $resName);
  my $fileResourceName=safeFilename($resName);
  mkpath("$path/resources/$fileResourceName");
  chmod(0777, "$path/resources/$fileResourceName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/resources/$fileResourceName/resource",
      "/resources[$resName]", $relocatable, $includeACLs, "false");
  if (! $success) {
    printf("  Error exporting %s", $resName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $resCount++;
  }
}
$ec->setProperty("preSummary", createExportString($resCount, "resources"));
$ec->setProperty("/myJob/resourceExported", $resCount);

exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
