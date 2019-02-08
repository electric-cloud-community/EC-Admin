#############################################################################
#
#  Copyright 2013-2016 Electric-Cloud Inc.
#
#############################################################################
use File::Path;

$[/myProject/scripts/perlHeaderJSON]

#
# Parameters
#
my $path    = '$[pathname]';
my $pattern = '$[pattern]';
my $includeACLs="$[includeACLs]";

#
# Global
#
my $errorCount=0;
my $wksCount=0;

# Get list of workspaces
my ($success, $xPath) = InvokeCommander("SuppressLog", "getWorkspaces");

# Create the Workspaces directory
mkpath("$path/Workspaces");
chmod(0777, "$path/Workspaces");

foreach my $node ($xPath->findnodes('//workspace')) {
  my $wksName=$node->{'workspaceName'};

  # skip workspaces that don't fit the pattern
  next if ($wksName !~ /$pattern/$[caseSensitive] );  # / for color mode

  printf("Saving Workspace: %s\n", $wksName);
  my $fileWorkspaceName=safeFilename($wksName);

  my ($success, $res, $errMsg, $errCode) =
      saveDslFile("$path/Workspaces/$fileWorkspaceName".".groovy",
  					      "/workspaces[$wksName]", $includeACLs);
  if (! $success) {
    printf("  Error exporting %s", $wksName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $wksCount++;
  }
}
$ec->setProperty("preSummary", "$wksCount workspaces exported");
$ec->setProperty("/myJob/workspaceExported", $wksCount);
exit($errorCount);

$[/myProject/scripts/backup/safeFilename]
$[/myProject/scripts/backup/saveDslFile]

$[/myProject/scripts/perlLibJSON]
