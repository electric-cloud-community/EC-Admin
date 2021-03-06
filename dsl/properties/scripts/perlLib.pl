$[/plugins/EC-Admin/project/scripts/perlCommonLib]

#############################################################################
#
# Invoke a API call
#
#############################################################################
sub InvokeCommander {

    my $optionFlags = shift;
    my $commanderFunction = shift;
    my $xPath;
    my $success = 1;

    my $bSuppressLog = $optionFlags =~ /SuppressLog/i;
    my $bSuppressResult = $bSuppressLog || $optionFlags =~ /SuppressResult/i;
    my $bIgnoreError = $optionFlags =~ /IgnoreError/i;

    # Run the command
    # print "Request to Commander: $commanderFunction\n" unless ($bSuppressLog);

    $ec->abortOnError(0) if $bIgnoreError;
    $xPath = $ec->$commanderFunction(@_);
    $ec->abortOnError(1) if $bIgnoreError;

    # Check for error return
    my $errMsg = $ec->checkAllErrors($xPath);
    my $errCode=$xPath->findvalue('//code',)->value();
    if ($errMsg ne "") {
        $success = 0;
    }
    if ($xPath) {
        print "Return data from Commander:\n" .
               $xPath->findnodes_as_string("/") . "\n"
            unless $bSuppressResult;
    }

    # Return the result
    return ($success, $xPath, $errMsg, $errCode);
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

  my $hashRef=undef;

  my($success, $result, $errMsg, $errCode)=InvokeCommander("SuppressLog IgnoreError", "getProperties", {'path'=>$psPath});
  return $hashRef if (!$success);


  foreach my $node ($result->findnodes('//property')) {
    my $propName=$node->findvalue('propertyName');
    my $value   =$node->findvalue('value')->string_value();
    my $psId    =$node->findvalue('propertySheetId');

    # this is not a nested PS
    if ($psId eq '') {
      $hashRef->{$propName}=$value;
      printf("%s: %s\n", $propName, $value);
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
  return $val? $val->value : undef;
}
