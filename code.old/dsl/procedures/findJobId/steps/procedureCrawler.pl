############################################################################
#
#  Copyright 2016 Electric-Cloud Inc.
#
#############################################################################
use File::Path;

$[/myProject/scripts/perlHeaderJSON]

############################################################################
#
# parameters
#
############################################################################
my $pattern="$[projectPattern]";

############################################################################
#
# Global variables
#
############################################################################
$DEBUG=0;
my ($success, $xPath);
my $MAX=5000;
my $nbParams=0;
my $nbSteps=0;
my $nbProps=0;

# create filterList
my @filterList;
if ($pattern ne "") {
  push (@filterList, {"propertyName" => "projectName",
                      "operator" => "like",
                      "operand1" => $pattern
                    }
  );
}
push (@filterList, {"propertyName" => "pluginName",
                      "operator" => "isNull"});

# Get list of Project
my ($success, $xPath) = InvokeCommander("SuppressLog", "findObjects", "project",
                                      {maxIds => $MAX,
                                       numObjects => $MAX,
                                       filter => \@filterList });

foreach my $node ($xPath->findnodes('//project')) {
  my $pName=$node->{'projectName'};
  printf("Processing Project: %s\n", $pName) if ($DEBUG);

  #
  # process top level properties
  #
  my ($suc1, $res1) = InvokeCommander("SuppressLog", "getProperties",
    {
      projectName => $pName,
      recurse => 0,
      expand => 0
    });
  foreach my $prop ($res1->findnodes('//property')) {
    my $propName=$prop->{'propertyName'};
    my $value=$prop->{'value'};
    printf("  Property: %s\n", $propName) if ($DEBUG);

    if (grep (/jobId/, $value) ) {
      $nbProps++;
      printf("*** jobId in project property: %s::%s\n", $pName, $propName);
    }
    if (grep (/jobStepId/, $value) ) {
      $nbProps++;
      printf("*** jobStepId in project property: %s::%s\n", $pName, $propName);
    }
    if (grep (/workflowId/, $value) ) {
      $nbProps++;
      printf("*** workflowId in project property: %s::%s\n", $pName, $propName);
    }

  }

  # Process procedures
  #
  my ($suc2, $res2) = InvokeCommander("SuppressLog", "getProcedures", $pName);
  foreach my $proc ($res2->findnodes('//procedure')) {
    my $procName=$proc->{'procedureName'};
    printf("  Procedure: %s\n", $procName) if ($DEBUG);

    #
    # process procedure top level properties
    #
    my ($suc1, $res1) = InvokeCommander("SuppressLog", "getProperties",
      {
        projectName   => $pName,
        procedureName => $procName,
        recurse       => 0,
        expand        => 0
      });
    foreach my $prop ($res1->findnodes('//property')) {
      my $propName=$prop->{'propertyName'};
      my $value=$prop->{'value'};
      printf("  Property: %s\n", $propName) if ($DEBUG);

      if (grep (/jobId/, $value) ) {
        $nbProps++;
        printf("*** jobId in procedure property: %s::%s::%s\n", $pName, $procName, $propName);
      }
      if (grep (/jobStepId/, $value) ) {
        $nbProps++;
        printf("*** jobStepId in procedure property: %s::%s::%s\n", $pName, $procName, $propName);
      }
      if (grep (/workflowId/, $value) ) {
        $nbProps++;
        printf("*** workflowId in procedure property: %s::%s::%s\n", $pName, $procName, $propName);
      }
    }
    #
    # Loop over steps
    #
    my ($suc3, $res3) = InvokeCommander("SuppressLog", "getSteps", $pName, $procName);
    foreach my $node ($res3->findnodes("//step")) {
      my $stepName=$node->{stepName};
      printf("    Step: %s\n", $stepName) if ($DEBUG);

      # is this a sub-procedure call
      if ($node->{subprocedure}) {
        #
        # Loop over parameters
        #
        my ($ok4, $res4)=InvokeCommander("SuppressLog IgnoreError", 'getActualParameters',
          {
            'projectName' => $pName,
            'procedureName' => $procName,
            'stepName' => $stepName
          } );
        foreach my $param ($res4->findnodes('//actualParameter')) {
          my $paramName=$param->{actualParameterName};
          my $value=$param->{value};
          if (grep (/jobId/, $value) ) {
            $nbParams++;
            printf("*** jobId in parameter: %s::%s::%s::%s\n",
              $pName, $procName, $stepName, $paramName);
          }
          if (grep (/jobStepId/, $value) ) {
            $nbParams++;
            printf("*** jobStepId in parameter: %s::%s::%s::%s\n",
              $pName, $procName, $stepName, $paramName);
          }
          if (grep (/workflowId/, $value) ) {
            $nbParams++;
            printf("*** workflowId in parameter: %s::%s::%s::%s\n",
              $pName, $procName, $stepName, $paramName);
          }
        }
      }
      my $cmd=$node->{command};
      if (grep (/jobId/, $cmd) ) {
        $nbSteps++;
        printf("*** jobId in command: %s::%s::%s\n",
          $pName, $procName, $stepName);
      }
      if (grep (/jobStepId/, $cmd) ) {
        $nbSteps++;
        printf("*** jobStepId in command: %s::%s::%s\n",
          $pName, $procName, $stepName);
      }
      if (grep (/workflowId/, $cmd) ) {
        $nbSteps++;
        printf("*** workflowId in command: %s::%s::%s\n",
          $pName, $procName, $stepName);
      }
    }
  }
}

printf("\nSummary:\n");
printf("  Number of steps: $nbSteps\n");
printf("  Number of parameters: $nbParams\n");
printf("  Number of properties: $nbProps\n");

$ec->setProperty("/myJob/nbSteps", $nbSteps);
$ec->setProperty("/myJob/nbProps", $nbProps);
$ec->setProperty("/myJob/nbParams", $nbParams);
$ec->setProperty("summary", "Steps: $nbSteps\nParams: $nbParams\nProps: $nbProps");

$[/myProject/scripts/perlLibJSON]
