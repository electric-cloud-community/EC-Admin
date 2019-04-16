#############################################################################
#
# Save Groups in DSL or XML Format
#
# Author: L.Rochette
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

$DEBUG=1;

#
# Parameters
#
my $path='$[pathname]';
my $pattern     = '$[pattern]';
my $includeACLs="$[includeACLs]";
my $includeNotifiers="$[includeNotifiers]";
my $relocatable="$[relocatable]";
my $format           = '$[format]';

#
# Global
#
my $errorCount=0;
my $groupCount=0;

# Get list of groups
my ($success, $xPath) = InvokeCommander("SuppressLog", "getGroups", {maximum=>1000});

# Create the Resources directory
mkpath("$path/groups");
chmod(0777, "$path/groups");

foreach my $node ($xPath->findnodes('//group')) {
  my $groupName=$node->{'groupName'};

  # skip groups that don't fit the pattern
  next if ($groupName !~ /$pattern/$[caseSensitive] );  # / for color mode

  printf("Saving group: %s\n", $groupName);
  my $fileGroupName=safeFilename($groupName);

  mkpath("$path/groups/$fileGroupName");
  chmod(0777, "$path/groups/$fileGroupName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/groups/$fileGroupName/group",
  		"/groups[$groupName]", $relocatable, $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("  Error exporting %s", $groupName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $groupCount++;
  }
}

$ec->setProperty("preSummary", createExportString($groupCount, "group"));
$ec->setProperty("/myJob/groupExported", $groupCount);

exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
