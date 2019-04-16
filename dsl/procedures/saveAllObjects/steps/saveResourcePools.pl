#############################################################################
#
#  Save Resources Pools (in DSL or XML)
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
my $includeNotifiers = "$[includeNotifiers]";
my $relocatable      = "$[relocatable]";
my $format           = '$[format]';

#
# Global
#
my $errorCount=0;
my $poolCount=0;

# Get list of resource pools
my ($success, $xPath) = InvokeCommander("SuppressLog", "getResourcePools");

# Create the Resources directory
mkpath("$path/resourcePools");
chmod(0777, "$path/resourcePools");

foreach my $node ($xPath->findnodes('//resourcePool')) {
  my $poolName=$node->{'resourcePoolName'};

  # skip pools that don't fit the pattern
  next if ($poolName !~ /$pattern/$[caseSensitive] ); # / for color mode

  printf("Saving Resource Pool: %s\n", $poolName);
  my $filePoolName=safeFilename($poolName);
  mkpath("$path/resourcePools/$filePoolName");
  chmod(0777, "$path/resourcePools/$filePoolName");

  my ($success, $res, $errMsg, $errCode) =
      backupObject($format, "$path/resourcePools/$filePoolName/resourcePool",
  			"/resourcePools/[$poolName]", $relocatable, $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("  Error exporting %s", $poolName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
	$poolCount++;
  }
}

$ec->setProperty("preSummary", createExportString($poolCount, "pool"));
$ec->setProperty("/myJob/poolExported", $poolCount);
exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
