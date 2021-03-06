$[/plugins/EC-Admin/project/scripts/perlCommonLib]

#############################################################################
#
# Invoke a API call
#
#############################################################################
sub InvokeCommander {

    my $optionFlags = shift;
    my $commanderFunction = shift;
    my $result;
    my $success = 1;
	  my $errMsg;
	  my $errCode;

    my $bSuppressLog = $optionFlags =~ /SuppressLog/i;
    my $bSuppressResult = $bSuppressLog || $optionFlags =~ /SuppressResult/i;
    my $bIgnoreError = $optionFlags =~ /IgnoreError/i;

    # Run the command
    # print "Request to Commander: $commanderFunction\n" unless ($bSuppressLog);

    $ec->abortOnError(0) if $bIgnoreError;
    $result = $ec->$commanderFunction(@_);
    $ec->abortOnError(1) if $bIgnoreError;

    # Check for error return
    if (defined ($result->{responses}->[0]->{error})) {
    	$errCode=$result->{responses}->[0]->{error}->{code};
    	$errMsg =$result->{responses}->[0]->{error}->{message};
    }

    if ($errMsg ne "") {
        $success = 0;
    }
    if ($result) {
        print "Return data from Commander:\n" .
               Dumper($result) . "\n"
            unless $bSuppressResult;
    }

    # Return the result
    return ($success, $result, $errMsg, $errCode);
}


#############################################################################
#
# Return the agent version.
# Args:
#    NONE
#############################################################################
sub getVersion
{
  return $ec->getVersions()->{responses}->[0]->{serverVersion}->{version};
}

#############################################################################
#
# Return a hash of the properties contained in a Property Sheet.
# Args:
#    1. Property Sheet path
#    2. Recursive boolean
#############################################################################
sub getPS
{
  my $psPath=shift;
  my $recursive=shift;

  my $hashRef=undef;;

  my($success, $result, $errMsg, $errCode)=InvokeCommander("SuppressLog IgnoreError", "getProperties", {'path'=>$psPath});
  return $hashRef if (!$success);

  foreach my $node ($result->findnodes('//property')) {
	my $propName=$node->{'propertyName'};
    my $value=$node->{'value'};
    if (defined ($value)) {
      $hashRef->{$propName}=$node->{'value'};
    } else {
      # nested PropertySheet
      if ($recursive) {
        $hashRef->{$propName}=getPS("$psPath/$propName", $recursive);
      } else {
        $hashRef->{$propName}=undef;
      }
    }
  }
  return $hashRef;
}

#############################################################################
#
# Return property value or undef in case of error (non existing)
#
#############################################################################
sub getP
{
  my $prop=shift;
  my $expand=shift;

  my($success, $xPath, $errMsg, $errCode)= InvokeCommander("SuppressLog IgnoreError", "getProperty", $prop);

  return undef if ($success != 1);
  my $val= $xPath->findvalue("//value");
  return $val;
}
