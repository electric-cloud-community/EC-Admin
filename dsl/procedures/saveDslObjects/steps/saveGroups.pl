#############################################################################
#
#  Copyright 2013-206 Electric-Cloud Inc.
#
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

  my ($success, $res, $errMsg, $errCode) =
      saveDslFile("$path/groups/$fileGroupName".".groovy",
  					"/groups[$groupName]", $includeACLs);
  if (! $success) {
    printf("  Error exporting %s", $groupName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $groupCount++;
  }
}
$ec->setProperty("preSummary", "$groupCount groups exported");
$ec->setProperty("/myJob/groupExported", $groupCount);
exit($errorCount);

$[/myProject/scripts/backup/safeFilename]
$[/myProject/scripts/backup/saveDslFile]

$[/myProject/scripts/perlLibJSON]
