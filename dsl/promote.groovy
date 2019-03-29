import groovy.transform.BaseScript
import com.electriccloud.commander.dsl.util.BasePlugin

//noinspection GroovyUnusedAssignment
@BaseScript BasePlugin baseScript

// Variables available for use in DSL code
def pluginName = args.pluginName
def upgradeAction = args.upgradeAction
def otherPluginName = args.otherPluginName

def pluginKey = getProject("/plugins/$pluginName/project").pluginKey
def pluginDir = getProperty("/projects/$pluginName/pluginDir").value

//List of procedure steps to which the plugin configuration credentials need to be attached
// ** steps with attached credentials
def stepsWithAttachedCredentials = [
		/*[
			procedureName: 'Procedure Name',
			stepName: 'step that needs the credentials to be attached'
		 ],*/
	]
// ** end steps with attached credentials

project pluginName, {

	loadPluginProperties(pluginDir, pluginName)
	loadProcedures(pluginDir, pluginKey, pluginName, stepsWithAttachedCredentials)
	//plugin configuration metadata
	property 'ec_config', {
		form = '$[' + "/projects/${pluginName}/procedures/CreateConfiguration/ec_parameterForm]"
		property 'fields', {
			property 'desc', {
				property 'label', value: 'Description'
				property 'order', value: '1'
			}
		}
	}
  property 'ec_reportData',
    propertyType: 'sheet'

	// Schedules
  println "Creating sample schedule 'CleanJobs'"
	schedule 'CleanJobs',
	  description: 'A Schedule to automatically delete jobs older than 30 days',
	  misfirePolicy: 'runOnce',
	  procedureName: 'jobsCleanup',
	  scheduleDisabled: '1',
	  startTime: '2:00',
	  weekDays: 'Tuesday Friday',
	  actualParameter : [
	    computeUsage: 'false',
	    executeDeletion: 'true',
	    jobLevel: 'All',
	    jobProperty: 'doNotDeleteThisJob',
	    olderThan: '30'
	  ]

  println "Creating sample schedule 'licenseLogger-reporter'"
	schedule 'licenseLogger-reporter',
	  description: 'Generates and (optionally) emails the periodic license report',
	  misfirePolicy: 'runOnce',
	  monthDays: '2',
	  procedureName: 'licenseLogger-report',
	  scheduleDisabled: '1',
	  startTime: '8:00',
	  actualParameter: [
	    sendEmail: 'true'
	  ]

  println "Creating sample schedule 'licenseLogger-snapshot'"
	schedule 'licenseLogger-snapshot',
	  description: 'Gathers a periodic snapshot of license usage',
	  interval: '5',
	  intervalUnits: 'minutes',
	  misfirePolicy: 'ignore',
	  procedureName: 'licenseLogger-snapshot',
	  scheduleDisabled: '1',
	  startTime: '0:02',
	  stopTime: '23:59'

  println "Creating sample schedule 'weeklySaveProjects'"
	schedule 'weeklySaveProjects',
	  description: 'Export weekly a bunch of objects for grnualrity',
	  misfirePolicy: 'runOnce',
	  procedureName: 'saveAllObjects',
	  scheduleDisabled: '1',
	  startTime: '4:30',
	  weekDays: 'Tuesday Thursday Saturday',
	  actualParameter: [
	    pathname: 					 '/tmp/BACKUP',
      pool:                'default',
      format:              'XML',
			caseSensitive:       '',
			relocatable: 				 'true',
			includeACLs: 				 'true',
			includeNotifiers: 	 'true',
			exportSteps: 				 'true',
	    exportResources: 		 'true',
	    exportResourcePools: 'true',
			exportGateways: 		 'true',
			exportZones: 				 'true',
	    exportWorkspaces: 	 'true',
	    exportUsers: 				 'true',
	    exportGroups:        'true',
			exportArtifacts: 		 'true',
	    exportDeploy: 			 'true',
      exportServerProperties: 'true',
      exportPlugins:       'false',
      exportPersonas:      'true'
	  ]
}

// Copy existing plugin configurations from the previous
// version to this version. At the same time, also attach
// the credentials to the required plugin procedure steps.
upgrade(upgradeAction, pluginName, otherPluginName, stepsWithAttachedCredentials)
