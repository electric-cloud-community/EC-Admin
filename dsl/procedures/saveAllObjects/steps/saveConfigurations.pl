#############################################################################
#
#  Save emailConfigs and tied objects (in DSL or XML)
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
# 2019-Apr-17 lrochette initial version: directory provider and emails
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
my $emailCount=0;
my $dirProvCount=0;

#
# Email configurations
#

# Get list of emailConfigs
my ($success, $xPath) = InvokeCommander("SuppressLog", "getEmailConfigs");

# Create the emailConfigs directory
mkpath("$path/emailConfigs");
chmod(0777, "$path/emailConfigs");
printf("Saving emailConfigs:\n");
printf("----------------\n");

foreach my $node ($xPath->findnodes('//emailConfig')) {
  my $configName=$node->{'configName'};

  # skip emailConfigs that don't fit the pattern
  next if ($configName !~ /$pattern/$[caseSensitive] ); # / for color mode

  printf("  Saving emailConfig: %s\n", $configName);
  my $fileConfigName=safeFilename($configName);
  mkpath("$path/emailConfigs/$fileConfigName");
  chmod(0777, "$path/emailConfigs/$fileConfigName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/emailConfigs/$fileConfigName/emailConfig",
    "/emailConfigs[$configName]", "$relocatable", $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("    Error exporting %s", $configName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $emailCount++;
  }
}

#
# Directory providers
#

# Get list of emailConfig Pages
($success, $xPath) = InvokeCommander("SuppressLog", "getDirectoryProviders");

# Create the emailConfig Pages directory
mkpath("$path/directoryProviders");
chmod(0777, "$path/directoryProviders");
printf("\nSaving directoryProviders:\n");
printf("--------------------\n");

foreach my $node ($xPath->findnodes('//directoryProvider')) {
  my $provName=$node->{'providerName'};

  # skip directoryProviders that don't fit the pattern
  next if ($provName !~ /$pattern/$[caseSensitive] ); # / for color mode

  printf("  Saving directoryProvider: %s\n", $provName);
  my $fileProvName=safeFilename($provName);

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/directoryProviders/$fileProvName",
    "/directoryProviders[$provName]", $relocatable, $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("    Error exporting %s", $provName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $dirProvCount++;
  }
}

my $str="";
$str .= createExportString($emailCount,       "emailConfig");
$str .= createExportString($dirProvCount,     "directoryProvider");

$ec->setProperty("preSummary", $str);

$ec->setProperty("/myJob/emailConfigExported", $emailCount);
$ec->setProperty("/myJob/directoryProviderExported", $dirProvCount);
exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
