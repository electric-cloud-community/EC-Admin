import java.io.File

def procName= 'subPM-deploymentSize'

procedure procName,
  description: '''a couple of steps to size your CloudBees Flow installation

Number per Implementation     Small	Medium	Large
---------------------------------------------------------
Agents	                     <50	   >50	  >1000
Projects	                   <10	   <100	  >100
Jobs Per Day	               <200	   >200	  >1000
jobSteps  	                <5000	 <20000	  >20000
Managed Resources            <100   <1000	  >1000''',
  jobNameTemplate: '$[/myProject/scripts/jobTemplate]',
{
  step 'agents',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/agents.pl").text,
    shell: 'ec-perl'

  step 'managedResources',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/managedResources.pl").text,
    shell: 'ec-perl'

  step 'projects',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/projects.pl").text,
    shell: 'ec-perl'

  step 'jobsPerDay',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/jobsPerDay.pl").text,
    shell: 'ec-perl'

  step 'jobStepsPerDay',
    command: new File(pluginDir, "dsl/procedures/$procName/steps/jobStepsPerDay.pl").text,
    shell: 'ec-perl'

  // Do not Display in the property picker
  property 'standardStepPicker', value: false
}
