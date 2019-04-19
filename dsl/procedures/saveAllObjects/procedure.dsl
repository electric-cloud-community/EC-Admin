import java.io.File

/*
Copyright 2014-2018 Electric-Cloud Inc.

Author: L. Rochette

History:
------------------------------------------------------------------------------
2014-02-27 Kate McCormack  Adding setTimeout equal to 600 so the ec commands
                           won't time out
2015-10-08 lrochette    Add step export as well
2018-06-15 lrochette    Convert to PluginWizard DSL format
2018-09-05 lrochette    Issue #72: added artifact and artifact versions
*/

def procName= 'saveAllObjects'

procedure procName,
  description: 'export objects individually in a tree like structure for further CMS checkin',
  // Need full path or else scheduled jobs don't work
  jobNameTemplate: '$[/plugins/EC-Admin/project/scripts/jobTemplate]',
{
  emailNotifier 'failureNotification',
    description: 'Send email to Admin if it fails',
    condition: '''$[/javascript if(getProperty("outcome") == \'error\')
    true;
else
    false;]''',
    configName: 'default',
    destinations: '$[/users/admin/email]',
    eventType: 'onCompletion',
    formattingTemplate: '''Subject: Job  \'$[jobName]\'  from procedure  \'$[procedureName]\'  $[/myEvent/type]  - Commander notification

$[/server/ec_notifierTemplates/Html_JobTempl/body]'''

  step 'grabResource',
    description: '''Capture the resource in case local is a pool.
All steps need to run on the same host''',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/grabResource.sh").text,
    errorHandling: 'abortProcedure',
    resourceName: "local"

  step 'saveProjectsProceduresWorkflows',
    description: 'A step to export each project and procedure individually',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveProjectsProceduresWorkflows.pl").text,
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveResources',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveResources.pl").text,
    condition: '$[exportResources]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveResourcePools',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveResourcePools.pl").text,
    condition: '$[exportResourcePools]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveGateways',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveGateways.pl").text,
    condition: '$[exportGateways]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveZones',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveZones.pl").text,
    condition: '$[exportZones]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveWorkspaces',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveWorkspaces.pl").text,
    condition: '$[exportWorkspaces]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveUsers',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveUsers.pl").text,
    condition: '$[exportUsers]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveGroups',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveGroups.pl").text,
    condition: '$[exportGroups]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveArtifacts',
      command: new File(pluginDir, "dsl/procedures/$procName/steps/saveArtifacts.pl").text,
      condition: '$[exportArtifacts]',
      resourceName: '$[/myJob/backupResource]',
      shell: 'ec-perl'

  step 'saveDeployObjects',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveDeployObjects.pl").text,
    condition: '$[exportDeploy]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'savePlugins',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/savePlugins.pl").text,
    condition: '$[exportPlugins]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveServerProperties',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveServerProperties.pl").text,
    condition: '$[exportServerProperties]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'saveTags',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveTags.pl").text,
    condition: '$[exportTags]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'

  step 'savePersonas',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/savePersonas.pl").text,
    condition: '$[exportPersonas]',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'
  step 'saveConfigurations',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/saveConfigurations.pl").text,
    description: "Save email and directory providers configurations",
    condition: '1',
    resourceName: '$[/myJob/backupResource]',
    shell: 'ec-perl'
}
