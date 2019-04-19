#############################################################################
#
#  Save Gateways (in DSL or XML)
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
my $gateCount=0;

# Get list of gateways
my ($success, $xPath) = InvokeCommander("SuppressLog", "getGateways");

# Create the Gateways directory
mkpath("$path/gateways");
chmod(0777, "$path/gateways");

foreach my $node ($xPath->findnodes('//gateway')) {
  my $gateName=$node->{'gatewayName'};

  # skip gateways that don't fit the pattern
  next if ($gateName !~ /$pattern/$[caseSensitive] );   # / for color mode

  printf("Saving Gateway: %s\n", $gateName);
  my $fileGatewayName=safeFilename($gateName);
  mkpath("$path/gateways/$fileGatewayName");
  chmod(0777, "$path/gateways/$fileGatewayName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/gateways/$fileGatewayName/gateway",
      "/gateways[$gateName]", $relocatable, $includeACLs, $includeNotifiers);

  if (! $success) {
    printf("  Error exporting %s", $gateName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $gateCount++;
  }
}

$ec->setProperty("preSummary", createExportString($gateCount, "gateway"));
$ec->setProperty("/myJob/gatewayExported", $gateCount);

exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
