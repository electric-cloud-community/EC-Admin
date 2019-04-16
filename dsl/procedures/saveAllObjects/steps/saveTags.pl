#############################################################################
#
#  Save Tags (in DSL or XML)
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
my $tagCount=0;

# tags were introduced in 8.5
my $version=getVersion();
if (compareVersion($version, "8.5") < 0) {
  $ec->setProperty("summary", "Tags were introduced only in 8.5");
  exit(0);
}

# Get list of Tags
my ($success, $xPath) = InvokeCommander("SuppressLog", "getTags");

# Create the Tags directory
mkpath("$path/tags");
chmod(0777, "$path/tags");

foreach my $node ($xPath->findnodes('//tag')) {
  my $tagName=$node->{'tagName'};

  # skip tags that don't fit the pattern
  next if ($tagName !~ /$pattern/$[caseSensitive] ); # / for color mode

  printf("Saving Tag: %s\n", $tagName);
  my $fileTagName=safeFilename($tagName);
  mkpath("$path/tags/$fileTagName");
  chmod(0777, "$path/tags/$fileTagName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/tags/$fileTagName/tag",
    "/tags[$tagName]", $relocatable, $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("  Error exporting %s", $tagName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $tagCount++;
  }
}
$ec->setProperty("preSummary", createExportString($tagCount, "tag"));
$ec->setProperty("/myJob/tagExported", $tagCount);
exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
