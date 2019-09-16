#############################################################################
#
#  Copyright 2013 Electric-Cloud Inc.
#
#############################################################################

use DateTime;
$[/myProject/scripts/perlHeader]
$[/myProject/scripts/perlLib]

#############################################################################
#
#  Assign Commander parameters to variables
#
#############################################################################
my $executeDeletion="$[executeDeletion]";

my ($success, $xPath) = InvokeCommander("SuppressLog", "getRepositories");
my $nodeset = $xPath->find('//repository');

foreach my $node ($nodeset->get_nodelist) {
  my $repoName=$node->findvalue('repositoryName');
  my $repoServerName;

  # The resourceName for the 'default' repository will be 'local' rather than the hostname
  if ($repoName eq "default") {
    $repoServerName = "local";
  } else {
    $repoServerName = $node->findvalue('url');
  }

  my $repoDisabled = $node->findvalue('repositoryDisabled');

  printf("AR: %s\n", $repoName);
  #
  # Skip disable repositories
  if ($repoDisabled) {
    printf ("  Repository disabled: Skipping!\n");
    next;
  }

  # Need to access . for FQDN
  # Issue #92
  $repoServerName =~ s#https?://([\-\w\.]+)(:\d+)?#$1#;

  # checking that the resource exist and is enabled
  #
  ($success, $xPath) = InvokeCommander("SuppressLog IgnoreError", "getResource", $repoServerName);
  if (! $success) {
    printf("  Associated resource '%s' does not exist. Skipping!\n", $repoServerName);
    next;
  }
  my $resDisabled=$xPath->findvalue('//resource/resourceDisabled');
  if ($resDisabled eq "1") {
    printf("  Associated resource '%s' disabled. Skipping!\n", $repoServerName);
    next;
  }

  my $agentAlive=$xPath->findvalue('//resource/agentState/alive');
  if ($agentAlive eq "0") {
    printf("  Associated resource '%s' is not alive. Skipping!\n", $repoServerName);
    next;
  }

  my $stepName = "clean Step For ".$repoName;
  $ec->createJobStep({'jobStepName' => $stepName,
                      'subprocedure' => 'cleanupRepository',
                      'actualParameter' => [{'actualParameterName' => 'executeDeletion', 'value'=>$executeDeletion},
                                         {'actualParameterName' => 'resource', 'value'=>$repoServerName},
                                        ]
                  });
}
