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
# 2019-Apr-16 lrochette Fix format to match EC-DslDeploy
# 2019-Jun-05 lrochette Issue 38: add support for devOpsInsightDataSources
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
my $errorCount  = 0;
my $appCount    = 0;
my $envCount    = 0;
my $compCount   = 0;
my $pipeCount   = 0;
my $relCount    = 0;
my $srcCount    = 0;
my $servCount   = 0;
my $catCount    = 0;
my $itemCount   = 0;
my $dashCount   = 0;
my $widgetCount = 0;
my $filterCount = 0;
my $reportCount = 0;

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
        "$path/projects/$fileProjectName/applications/$fileAppName/application",
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

      printf("  Saving Release: %s\n", $relName);
      my $fileRelName=safeFilename($relName);
      mkpath("$path/projects/$fileProjectName/releases/$fileRelName");
      chmod(0777, "$path/projects/$fileProjectName/releases/$fileRelName");

      my ($success, $res, $errMsg, $errCode) =
        backupObject($format,
          "$path/projects/$fileProjectName/releases/$fileRelName/release",
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

      if (compareVersion($version, "9.0") < 0) {
        printf("WARNING: Version 9.0 or greater is required to save DOIS sources");
      } else {
        mkpath("$path/projects/$fileProjectName/releases/$fileRelName/devOpsInsightDataSources");
        chmod(0777, "$path/projects/$fileProjectName/releases/$fileRelName/devOpsInsightDataSources");
        my ($suc2, $xPath2) = InvokeCommander("SuppressLog", "getDevOpsInsightDataSources", $pName, $relName);
        foreach my $src ($xPath2->findnodes('//devOpsInsightDataSource')) {
          my $srcName=$src->{'devOpsInsightDataSourceName'};
          printf("    Saving devOpsInsightDataSource: %s\n", $srcName);
          my $fileSrcName=safeFilename($srcName);
          mkpath("$path/projects/$fileProjectName/releases/$fileRelName/devOpsInsightDataSources/$fileSrcName");
          chmod(0777, "$path/projects/$fileProjectName/releases/$fileRelName/devOpsInsightDataSources/$fileSrcName");
          ($success, $res, $errMsg, $errCode) =
            backupObject($format,
              "$path/projects/$fileProjectName/releases/$fileRelName/devOpsInsightDataSources/$fileSrcName/devOpsInsightDataSource",
              "/projects[$pName]releases[$relName]devOpsInsightDataSources[$srcName]",
              $relocatable, $includeACLs, $includeNotifiers);

          if (! $success) {
            printf("    Error exporting devOpsInsightDataSource %s", $srcName);
            printf("    %s: %s\n", $errCode, $errMsg);
            $errorCount++;
          }
          else {
            $srcCount++;
          }
        }
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
      mkpath("$path/projects/$fileProjectName/services/$fileServName");
      chmod(0777, "$path/projects/$fileProjectName/services/$fileServName");

      my ($success, $res, $errMsg, $errCode) =
        backupObject($format,
          "$path/projects/$fileProjectName/services/$fileServName/service",
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
      mkpath("$path/projects/$fileProjectName/catalogs/$fileCatName/catalogItems");
      chmod(0777, "$path/projects/$fileProjectName/catalogs/$fileCatName/catalogItems");
      my ($ok, $json) = InvokeCommander("SuppressLog", "getCatalogItems", $pName, $catName);
      foreach my $item ($json->findnodes("//catalogItem")) {
        my $itemName=$item->{'catalogItemName'};
        my $fileItemName=safeFilename($itemName);
        printf("    Saving Catalog Item: %s\n", $itemName);
        mkpath("$path/projects/$fileProjectName/catalogs/$fileCatName/catalogItems/$fileItemName");
        chmod(0777, "$path/projects/$fileProjectName/catalogs/$fileCatName/catalogItems/$fileItemName");

        my ($success, $res, $errMsg, $errCode) =
          backupObject($format,
            "$path/projects/$fileProjectName/catalogs/$fileCatName/catalogItems/$fileItemName/catalogItem",
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

    my ($success, $xPath) = InvokeCommander("SuppressLog", "getDashboards", {projectName => $pName});
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
        $dashCount++;
      }

      # backup widget
      my ($ok, $json) = InvokeCommander("SuppressLog", "getWidgets", $pName, $dashName);
      mkpath("$path/projects/$fileProjectName/dashboards/$fileDashName/widgets");
      chmod(0777, "$path/projects/$fileProjectName/dashboards/$fileDashName/widgets");
      foreach my $widget ($json->findnodes("//widget")) {
        my $widgetName=$widget->{'widgetName'};
        my $fileWidgetName=safeFilename($widgetName);
        printf("    Saving Widget: %s\n", $widgetName);
        mkpath("$path/projects/$fileProjectName/dashboards/$fileDashName/widgets/$fileWidgetName");
        chmod(0777, "$path/projects/$fileProjectName/dashboards/$fileDashName/widgets/$fileWidgetName");

        my ($success, $res, $errMsg, $errCode) =
          backupObject($format,
            "$path/projects/$fileProjectName/dashboards/$fileDashName/widgets/$fileWidgetName/widget",
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

      }       # widget Loop

      # backup reportingFilters
      mkpath("$path/projects/$fileProjectName/dashboards/$fileDashName/reportingFilters");
      chmod(0777, "$path/projects/$fileProjectName/dashboards/$fileDashName/reportingFilters");
      my ($ok, $json) = InvokeCommander("SuppressLog", "getReportingFilters", $pName, $dashName);
      foreach my $filter ($json->findnodes("//reportingFilter")) {
        my $filterName=$filter->{'reportingFilterName'};
        my $fileFilterName=safeFilename($filterName);
        printf("    Saving ReportingFilter: %s\n", $filterName);
        mkpath("$path/projects/$fileProjectName/dashboards/$fileDashName/reportingFilters/$fileFilterName");
        chmod(0777, "$path/projects/$fileProjectName/dashboards/$fileDashName/reportingFilters/$fileFilterName");

        my ($success, $res, $errMsg, $errCode) =
          backupObject($format,
            "$path/projects/$fileProjectName/dashboards/$fileDashName/reportingFilters/$fileFilterName/reportingFilter",
            "/projects[$pName]dashboards[$dashName]reportingFilters[$filterName]",
            $relocatable, $includeACLs, $includeNotifiers);

        if (! $success) {
          printf("  Error exporting filter %s in dashboard", $filterName, $dashName);
          printf("  %s: %s\n", $errCode, $errMsg);
          $errorCount++;
        }
        else {
          $filterCount++;
        }

      }       # Filter Loop

    }         # dashboard loop

    # Save reports
    #
    mkpath("$path/projects/$fileProjectName/reports");
    chmod(0777, "$path/projects/$fileProjectName/reports");
    my ($success, $xPath) = InvokeCommander("SuppressLog", "getReports", {projectName => $pName});
    foreach my $report ($xPath->findnodes('//report')) {
      my $reportName=$report->{'reportName'};

      # skip reports that don't fit the pattern
      next if (($pName  eq "Default") && ($reportName !~ /$pattern/$[caseSensitive] ));  # / just for the color

      my $fileReportName=safeFilename($reportName);
      printf("  Saving Report: %s\n", $reportName);
      mkpath("$path/projects/$fileProjectName/reports/$fileReportName");
      chmod(0777, "$path/projects/$fileProjectName/reports/$fileReportName");

       my ($success, $res, $errMsg, $errCode) =
         backupObject($format,
          "$path/projects/$fileProjectName/reports/$fileReportName/report",
          "/projects[$pName]reports[$reportName]",
          $relocatable, $includeACLs, $includeNotifiers);

      if (! $success) {
        printf("  Error exporting report %s", $reportName);
        printf("  %s: %s\n", $errCode, $errMsg);
        $errorCount++;
      }
      else {
        $reportCount++;
      }
    }         # report loop
  }           # Version greater than 7.3

}             # project loop

my $str="";
$str .= createExportString($appCount, "application")         if ($appCount);
$str .= createExportString($envCount, "environment")         if ($envCount);
$str .= createExportString($compCount, "component")          if ($compCount);
$str .= createExportString($pipeCount, "pipeline")           if ($pipeCount);
$str .= createExportString($relCount, "release")             if ($relCount);
$str .= createExportString($srcCount, "source")              if ($srcCount);
$str .= createExportString($servCount, "service")            if ($servCount);
$str .= createExportString($catCount, "catalog")             if ($catCount);
$str .= createExportString($itemCount, "catalog item")       if ($itemCount);
$str .= createExportString($reportCount, "report")           if ($reportCount);
$str .= createExportString($dashCount, "dashboard")          if ($dashCount);
$str .= createExportString($widgetCount, "widget")           if ($widgetCount);
$str .= createExportString($filterCount, "reporting filter") if ($filterCount);

$ec->setProperty("preSummary", $str);

$ec->setProperty("/myJob/papplicationExported",    $appCount);
$ec->setProperty("/myJob/environmentExported",     $envCount);
$ec->setProperty("/myJob/componentExported",       $compCount);
$ec->setProperty("/myJob/pipelineExported",        $pipeCount);
$ec->setProperty("/myJob/releaseExported",         $relCount);
$ec->setProperty("/myJob/sourceExported",          $srcCount);
$ec->setProperty("/myJob/serviceExported",         $servCount);
$ec->setProperty("/myJob/catalogExported",         $catCount);
$ec->setProperty("/myJob/catalogItemExported",     $itemCount);
$ec->setProperty("/myJob/dashboardExported",       $dashCount);
$ec->setProperty("/myJob/widgetExported",          $widgetCount);
$ec->setProperty("/myJob/reportingFilterExported", $filterCount);
$ec->setProperty("/myJob/reportExported",          $reportCount);
exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
