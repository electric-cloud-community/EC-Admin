#############################################################################
#
#  Save Users (in DSL or XML)
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
my $userCount=0;

# Get list of users
my ($success, $xPath) = InvokeCommander("SuppressLog", "getUsers", {maximum=>1000});

# Create the Resources directory
mkpath("$path/users");
chmod(0777, "$path/users");

foreach my $node ($xPath->findnodes('//user')) {
  my $userName=$node->{'userName'};

  # skip project that don't fit the pattern
  next if ($userName !~ /$pattern/$[caseSensitive] ); # / for color mode

  printf("Saving User: %s\n", $userName);
  my $fileUserName=safeFilename($userName);
  mkpath("$path/users/$fileUserName");
  chmod(0777, "$path/users/$fileUserName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/users/$fileUserName/user",
  		"/users[$userName]", $relocatable, $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("  Error exporting %s", $userName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $userCount++;
  }
}
$ec->setProperty("preSummary", createExportString($userCount, "user"));
$ec->setProperty("/myJob/userExported", $userCount);
exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
