#############################################################################
#
#  Save Workspaces (in DSL or XML)
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
my $wksCount=0;

# Get list of workspaces
my ($success, $xPath) = InvokeCommander("SuppressLog", "getWorkspaces");

# Create the Workspaces directory
mkpath("$path/workspaces");
chmod(0777, "$path/workspaces");

foreach my $node ($xPath->findnodes('//workspace')) {
  my $wksName=$node->{'workspaceName'};

  # skip workspaces that don't fit the pattern
  next if ($wksName !~ /$pattern/$[caseSensitive] );  # / for color mode

  printf("Saving Workspace: %s\n", $wksName);
  my $fileWorkspaceName=safeFilename($wksName);
  mkpath("$path/workspaces/$fileWorkspaceName");
  chmod(0777, "$path/workspaces/$fileWorkspaceName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/workspaces/$fileWorkspaceName/workspace",
  		"/workspaces[$wksName]", $relocatable, $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("  Error exporting %s", $wksName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $wksCount++;
  }
}
$ec->setProperty("preSummary", createExportString($wksCount, "workspace"));
$ec->setProperty("/myJob/workspaceExported", $wksCount);
exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
