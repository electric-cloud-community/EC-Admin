#############################################################################
#
#  Script to backup the Deploy objects (application, environment, components,
#     releases, services, ...) in XML or DSL format
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
# 2019-Feb-22 lrochette Fix #166: save catalogs and catalogItems
#                       Fix #165: save dashbaords
##############################################################################
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
my $version=getVersion();
my $errorCount = 0;
my $appCount   = 0;
my $envCount   = 0;
my $compCount  = 0;
my $pipeCount  = 0;
my $relCount   = 0;
my $servCount  = 0;
my $catCount   = 0;
my $itemCount  = 0;
my $dashCount  = 0;
my $widgetCount= 0;

# Set the timeout to config value or 600 if not set
my $defaultTimeout = getP("/server/EC-Admin/cleanup/config/timeout");
$ec->setTimeout($defaultTimeout? $defaultTimeout : 600);

#
# Get list of Project
my ($success, $xPath) = InvokeCommander("SuppressLog", "getProjects");

# Create the Projects directory
mkpath("$path/projects");
chmod(0777, "$path/projects") or die("Can't change permissions on $path/projects: $!");

foreach my $node ($xPath->findnodes('//project')) {
  my $pName=$node->{'projectName'};
  my $pluginName=$node->{'pluginName',};

  # skip plugins
  next if ($pluginName ne "");

  # skip projects that don't fit the pattern
  next if ($pName !~ /$pattern/$[caseSensitive] ); # / just for the color

  # skip non Default project for version before 6.2
  next if (($pName ne "Default") && ($version < "6.2"));
  printf("Saving Project: %s\n", $pName);

  my $fileProjectName=safeFilename($pName);
  #
  # Save Applications
  #
  mkpath("$path/projects/$fileProjectName/applications");
  chmod(0777, "$path/projects/$fileProjectName/applications");

  my ($success, $xPath) = InvokeCommander("SuppressLog", "getApplications", $pName);
  foreach my $app ($xPath->findnodes('//application')) {
    my $appName=$app->{'applicationName'};

    # skip applications that don't fit the pattern
    next if (($pName  eq "Default") && ($appName !~ /$pattern/$[caseSensitive] )); # / just for the color

    my $fileAppName=safeFilename($appName);
    printf("  Saving Application: %s\n", $appName);

    mkpath("$path/projects/$fileProjectName/applications/$fileAppName");
    chmod(0777, "$path/projects/$fileProjectName/applications/$fileAppName");
    my ($success, $res, $errMsg, $errCode) =
      backupObject($format,
        "$path/projects/$fileProjectName/applications/$fileAppName/application.groovy",
        "/projects[$pName]applications[$appName]",
        $relocatable, $includeACLs, $includeNotifiers);

    if (! $success) {
      printf("  Error exporting application %s", $appName);
      printf("  %s: %s\n", $errCode, $errMsg);
      $errorCount++;
    }
    else {
      $appCount++;
    }

    #
    # backup Components
    mkpath("$path/projects/$fileProjectName/applications/$fileAppName/components");
    chmod(0777, "$path/projects/$fileProjectName/applications/$fileAppName/components");

    my ($ok, $json) = InvokeCommander("SuppressLog", "getComponents", $pName, {applicationName => $appName});
    foreach my $comp ($json->findnodes("//component")) {
      my $compName=$comp->{'componentName'};
      my $fileCompName=safeFilename($compName);
      printf("    Saving Component: %s\n", $compName);

      my ($success, $res, $errMsg, $errCode) =
        backupObject($format,
          "$path/projects/$fileProjectName/applications/$fileAppName/components/$fileCompName",
          "/projects[$pName]applications[$appName]components[$compName]",
          $relocatable, $includeACLs, $includeNotifiers);

      if (! $success) {
        printf("  Error exporting component %s in application", $compName, $appName);
        printf("  %s: %s\n", $errCode, $errMsg);
        $errorCount++;
      }
      else {
        $compCount++;
      }

    }
  }

  #
  # Save Environments definitions
  #
  mkpath("$path/projects/$fileProjectName/environments");
  chmod(0777, "$path/projects/$fileProjectName/environments");

  my ($success, $xPath) = InvokeCommander("SuppressLog", "getEnvironments", $pName);
  foreach my $proc ($xPath->findnodes('//environment')) {
    my $envName=$proc->{'environmentName'};

    # skip environments that don't fit the pattern
    next if (($pName  eq "Default") && ($envName !~ /$pattern/$[caseSensitive] ));  # / just for the color

    my $fileEnvName=safeFilename($envName);
    printf("  Saving Environment: %s\n", $envName);

    my ($success, $res, $errMsg, $errCode) =
      backupObject($format, "$path/projects/$fileProjectName/environments/$fileEnvName",
        "/projects[$pName]environments[$envName]",
        $relocatable, $includeACLs, $includeNotifiers);

    if (! $success) {
      printf("  Error exporting environment %s", $envName);
      printf("  %s: %s\n", $errCode, $errMsg);
      $errorCount++;
    }
    else {
      $envCount++;
    }
  }

  #
  # Export pipelines if the version is recent enough
  #
  if (compareVersion($version, "6.0") < 0) {
    printf("WARNING: Version 6.0 or greater is required to save Pipeline objects");
  } else {
    # Save pipeline definitions
    #
    mkpath("$path/projects/$fileProjectName/pipelines");
    chmod(0777, "$path/projects/$fileProjectName/pipelines");

    my ($success, $xPath) = InvokeCommander("SuppressLog", "getPipelines", $pName);
    foreach my $proc ($xPath->findnodes('//pipeline')) {
      my $pipeName=$proc->{'pipelineName'};

      # skip pipelines that don't fit the pattern
      next if (($pName  eq "Default") && ($pipeName !~ /$pattern/$[caseSensitive] )); # / just for the color

      my $filePipeName=safeFilename($pipeName);
      printf("  Saving Pipeline: %s\n", $pipeName);

      my ($success, $res, $errMsg, $errCode) =
        backupObject($format,
          "$path/projects/$fileProjectName/pipelines/$filePipeName",
          "/projects[$pName]pipelines[$pipeName]",
          $relocatable, $includeACLs, $includeNotifiers);

      if (! $success) {
        printf("  Error exporting pipeline %s", $pipeName);
        printf("  %s: %s\n", $errCode, $errMsg);
        $errorCount++;
      }
      else {
        $pipeCount++;
      }
    }         # Pipeline loop
  }           # Version greater than 6.0


  # Export releases if the version is recent enough
  #
  if (compareVersion($version, "6.1") < 0) {
    printf("WARNING: Version 6.1 or greater is required to save Release objects");
  } else {
    # Save release definitions
    #
    mkpath("$path/projects/$fileProjectName/releases");
    chmod(0777, "$path/projects/$fileProjectName/releases");

    my ($success, $xPath) = InvokeCommander("SuppressLog", "getReleases", $pName);
    foreach my $proc ($xPath->findnodes('//release')) {
      my $relName=$proc->{'releaseName'};

      # skip releases that don't fit the pattern
      next if (($pName  eq "Default") && ($relName !~ /$pattern/$[caseSensitive] ));  # / just for the color

      my $filePipeName=safeFilename($relName);
      printf("  Saving Release: %s\n", $relName);

      my ($success, $res, $errMsg, $errCode) =
        backupObject($format,
          "$path/projects/$fileProjectName/releases/$filePipeName",
          "/projects[$pName]releases[$relName]",
          $relocatable, $includeACLs, $includeNotifiers);

      if (! $success) {
        printf("  Error exporting release %s", $relName);
        printf("  %s: %s\n", $errCode, $errMsg);
        $errorCount++;
      }
      else {
        $relCount++;
      }
    }         # Release loop
  }           # Version greater than 6.1

  # Export services if the version is recent enough
  #
  if (compareVersion($version, "8.1") < 0) {
    printf("WARNING: Version 8.1 or greater is required to save Services objects");
  } else {
    # Save release definitions
    #
    mkpath("$path/projects/$fileProjectName/services");
    chmod(0777, "$path/projects/$fileProjectName/services");

    my ($success, $xPath) = InvokeCommander("SuppressLog", "getServices", $pName);
    foreach my $proc ($xPath->findnodes('//service')) {
      my $servName=$proc->{'serviceName'};

      # skip services that don't fit the pattern
      next if (($pName  eq "Default") && ($servName !~ /$pattern/$[caseSensitive] ));  # / just for the color

      my $fileServName=safeFilename($servName);
      printf("  Saving Service: %s\n", $servName);

      my ($success, $res, $errMsg, $errCode) =
        backupObject($format,
          "$path/projects/$fileProjectName/services/$fileServName",
          "/projects[$pName]services[$servName]",
          $relocatable, $includeACLs, $includeNotifiers);

      if (! $success) {
        printf("  Error exporting service %s", $servName);
        printf("  %s: %s\n", $errCode, $errMsg);
        $errorCount++;
      }
      else {
        $servCount++;
      }
    }         # service loop
  }           # Version greater than 8.1

  # Export catalogs if the version is recent enough
  #
  if (compareVersion($version, "7.3") < 0) {
    printf("WARNING: Version 7.3 or greater is required to save Catalog objects");
  } else {
    # Save catalog definitions
    #
    mkpath("$path/projects/$fileProjectName/catalogs");
    chmod(0777, "$path/projects/$fileProjectName/catalogs");

    my ($success, $xPath) = InvokeCommander("SuppressLog", "getCatalogs", $pName);
    foreach my $proc ($xPath->findnodes('//catalog')) {
      my $catName=$proc->{'catalogName'};

      # skip catalogs that don't fit the pattern
      next if (($pName  eq "Default") && ($catName !~ /$pattern/$[caseSensitive] ));  # / just for the color

      my $fileCatName=safeFilename($catName);
      printf("  Saving Catalog: %s\n", $catName);

     mkpath("$path/projects/$fileProjectName/catalogs/$fileCatName");
     chmod(0777, "$path/projects/$fileProjectName/catalogs/$fileCatName");

      my ($success, $res, $errMsg, $errCode) =
        backupObject($format,
          "$path/projects/$fileProjectName/catalogs/$fileCatName/catalog",
          "/projects[$pName]catalogs[$catName]",
          $relocatable, $includeACLs, $includeNotifiers);

      if (! $success) {
        printf("  Error exporting catalog %s", $catName);
        printf("  %s: %s\n", $errCode, $errMsg);
        $errorCount++;
      }
      else {
        $servCount++;
      }

      # backup catalogItems
      my ($ok, $json) = InvokeCommander("SuppressLog", "getCatalogItems", $pName, $catName);
      foreach my $item ($json->findnodes("//catalogItem")) {
        my $itemName=$item->{'catalogItemName'};
        my $fileItemName=safeFilename($itemName);
        printf("    Saving Catalog Item: %s\n", $itemName);
        mkpath("$path/projects/$fileProjectName/catalogs/$fileCatName/items");
        chmod(0777, "$path/projects/$fileProjectName/catalogs/$fileCatName/items");

        my ($success, $res, $errMsg, $errCode) =
          backupObject($format,
            "$path/projects/$fileProjectName/catalogs/$fileCatName/items/$fileItemName",
            "/projects[$pName]catalogs[$catName]catalogItems[$itemName]",
            $relocatable, $includeACLs, $includeNotifiers);

        if (! $success) {
          printf("  Error exporting catalog item %s in catalog", $itemName, $catName);
          printf("  %s: %s\n", $errCode, $errMsg);
          $errorCount++;
        }
        else {
          $itemCount++;
        }

      }

    }         # catalog loop
  }           # Version greater than 7.3


  # Export dashboards if the version is recent enough
  #
  if (compareVersion($version, "7.1") < 0) {
    printf("WARNING: Version 7.1 or greater is required to save Dashboards objects");
  } else {
    # Save dashboard definitions
    #
    mkpath("$path/projects/$fileProjectName/dashboards");
    chmod(0777, "$path/projects/$fileProjectName/dashboards");

    my ($success, $xPath) = InvokeCommander("SuppressLog", "getDashboards", $pName);
    foreach my $dash ($xPath->findnodes('//dashboard')) {
      my $dashName=$dash->{'dashboardName'};

      # skip dashboards that don't fit the pattern
      next if (($pName  eq "Default") && ($dashName !~ /$pattern/$[caseSensitive] ));  # / just for the color

      my $fileDashName=safeFilename($dashName);
      printf("  Saving Dashboard: %s\n", $dashName);

     mkpath("$path/projects/$fileProjectName/dashboards/$fileDashName");
     chmod(0777, "$path/projects/$fileProjectName/dashboards/$fileDashName");

      my ($success, $res, $errMsg, $errCode) =
        backupObject($format,
          "$path/projects/$fileProjectName/dashboards/$fileDashName/dashboard",
          "/projects[$pName]dashboards[$dashName]",
          $relocatable, $includeACLs, $includeNotifiers);

      if (! $success) {
        printf("  Error exporting dashboard %s", $dashName);
        printf("  %s: %s\n", $errCode, $errMsg);
        $errorCount++;
      }
      else {
        $servCount++;
      }

      # backup widget
      my ($ok, $json) = InvokeCommander("SuppressLog", "getWidgets", $pName, $dashName);
      foreach my $widget ($json->findnodes("//widget")) {
        my $widgetName=$widget->{'widgetName'};
        my $fileWidgetName=safeFilename($widgetName);
        printf("    Saving Widget: %s\n", $widgetName);
        mkpath("$path/projects/$fileProjectName/dashboards/$fileDashName/widgets");
        chmod(0777, "$path/projects/$fileProjectName/dashboards/$fileDashName/widgets");

        my ($success, $res, $errMsg, $errCode) =
          backupObject($format,
            "$path/projects/$fileProjectName/dashboards/$fileDashName/widgets/$fileWidgetName",
            "/projects[$pName]dashboards[$dashName]widgets[$widgetName]",
            $relocatable, $includeACLs, $includeNotifiers);

        if (! $success) {
          printf("  Error exporting widget %s in dashboard", $widgetName, $dashName);
          printf("  %s: %s\n", $errCode, $errMsg);
          $errorCount++;
        }
        else {
          $widgetCount++;
        }

      }

    }         # dashboard loop
  }           # Version greater than 7.3

}             # project loop

my $str=sprintf("   $appCount applications exported\n" );
$str .= sprintf("   $envCount environments exported\n");
$str .= sprintf("   $compCount components exported\n");
$str .= sprintf("   $pipeCount pipelines exported\n");
$str .= sprintf("   $relCount releases exported\n");
$str .= sprintf("   $servCount services exported\n");
$str .= sprintf("   $catCount catalogs exported\n");
$str .= sprintf("   $itemCount catalog items exported\n");
$str .= sprintf("   $dashCount dashboards exported\n");
$str .= sprintf("   $dashCount widgets exported\n");

$ec->setProperty("preSummary", $str);

$ec->setProperty("/myJob/papplicationExported", $appCount);
$ec->setProperty("/myJob/environmentExported",  $envCount);
$ec->setProperty("/myJob/componentExported",    $compCount);
$ec->setProperty("/myJob/pipelineExported",     $pipeCount);
$ec->setProperty("/myJob/releaseExported",      $relCount);
$ec->setProperty("/myJob/serviceExported",      $servCount);
$ec->setProperty("/myJob/catalogExported",      $catCount);
$ec->setProperty("/myJob/catalogItemExported",  $itemCount);
$ec->setProperty("/myJob/dashboardExported",    $dashCount);
$ec->setProperty("/myJob/widgetExported",       $widgetCount);
exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
