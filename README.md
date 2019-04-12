# EC-Admin

EC-Admin is a collection of advanced management, optimization, and customization
tools for ElectricFlow. It includes tools for:

* Bulk resource health checks
* White labeling
* Log management
* Advanced backup
* License statistics
* Debug tools
* More

EC-Admin is used in many ElectricFlow field deployments.

In June 2018, the plugin was converted to the [Plugin Wizard DSL framework](https://github.com/electric-cloud/PluginWizard)
format so the whole plugin code is now managed on GitHub without the need
to extract the project first. In March 2019, the plugin was furthermore
converted to the new [plugin builder](https://github.com/electric-cloud/ec-plugin-tool)
to inprove promotion time

The official stable version can be found in the plugins catalog or in
our [plugins directory](https://electric-cloud.com/plugins/directory/p/ec-admin).
You can also follow development in our [Community GitHub repository](https://github.com/electric-cloud-community/EC-Admin).
For the latest code changes, check the [maintainer's fork](https://github.com/lrochette/EC-Admin)

Requirements:

* Electric Flow 6.0 minimum
* EC-PluginManager 1.4.0


## Installation

It is available as a plugin delivered in the form of a .jar file.

To install the plugin, use one the following methods:

* ElectricFlow Administration/Plugins UI - "Install from File/URL"
* CLI - `ectool installPlugin --force 1 EC-Admin.jar`
* Perl - `$ec->installPlugin()` API.

Don't forget to promote the plugin after installation.

To install on 4.0.x or or 4.1.x, import the EC_4.0.xml file. Be
aware that some features are not present as the original project
makes use of `createJobStep()` API which was introduced in 4.2.0:

```ectool import /path_to/EC-Admin_for_EC_4.0.xml --disableSchedules 1```



# Contact authors

* License Logger:
  * Mike Westerhof

* deleteObjects:
* testResources:
  * [Tanay Nagjee](https://github.com/tanaynagjee)

* Everything else:
  *  [Laurent Rochette](mailto:lrochette@electric-cloud.com)


# Thanks
Thanks to Mark Hall for providing the Dev and Prod logos for changeBannerColor.

Thanks to [David Hubbell](mailto:dhubbell@spkaa.com) for his constant flow of
fixes to my poor code.

# Legal Mumbo Jumbo

This plugin is free for use. Modify it however you see fit to better your
experience using ElectricFlow. Share
your [enhancements](https://github.com/electric-cloud-community/EC-DslDeploy/issues)
and [fixes](https://github.com/electric-cloud-community/EC-DslDeploy/pulls)

This module is not officially supported by Electric Cloud. It has undergone no
formal testing and you may run into issues that have not been uncovered in the
limited testing done so far.

[Electric Cloud](https://www.electric-cloud.com) should not be held liable for
any repercussions of using this plugin.
