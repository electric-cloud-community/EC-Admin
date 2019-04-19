package com.electriccloud.plugin.spec
import spock.lang.*
import org.apache.tools.ant.BuildLogger

class cleanup extends PluginTestHelper {
  static String pName='EC-Admin'

  def doSetupSpec() {
    dsl """
      project "pipe5"
      project "CleanupTest",
        description: "For testing EC-Admin cleanup",
      {
        procedure 'saveAllObjects'
      }
    """
  }

  def doCleanupSpec() {
    conditionallyDeleteProject("pipe5")
    conditionallyDeleteProject("CleanupTest")
  }

  def callJobsCleanup(String jobName, def additionnalParams) {
    println "LR## Running callJobsCleanup"
    def params =[
      computeUsage: "\"0\"",
      executeDeletion: "\"true\"",
      jobLevel: "\"All\"",
      jobPatternMatching: "\"\"",
      jobProperty: "\"doNotDelete\"",
      olderThan: "\"365\""
    ]
    assert jobName

    additionnalParams.each {k, v ->
      params[k]="\"$v\""
    }
    def res=runProcedureDslAndRename(
      jobName,
      """runProcedure(
            projectName: "/plugins/$pName/project",
            procedureName: "jobsCleanup",
            actualParameter: $params
         )
      """
    )
    return res
  }

  // Check procedures exist
  def "checkProcedures for cleanup"() {
    given: "a list of procedure"
      def list= ["jobsCleanup", "pipelinesCleanup", "artifactsCleanup",
        "artifactsCleanup_byQuantity", "cleanupCacheDirectory", "cleanupRepository",
        "deleteWorkspaceOrphans", "jobCleanup_byResult", "subJC_deleteWorkspace"]
      def res=[:]
    when: "check for existence"
      list.each { proc ->
        res[proc]= dsl """
          getProcedure(
            projectName: "/plugins/$pName/project",
            procedureName: "$proc"
          ) """
      }
    then: "they exist"
      list.each  {proc ->
        println "Checking $proc"
        assert res[proc].procedure.procedureName == proc
      }
  }

  // Issue 5
/*  def "issue5 - delete Completed pipeline"() {
    given: "an old completed pipeline"
      // dslFile "dsl/cleanup/pipe5_completed_1.groovy"
      importXML("data/cleanup/pipe5_completed_1.xml")
    when:
      def res=runProcedureDsl("""
        runProcedure(
          projectName: "/plugins/$pName/project",
          procedureName: "pipelinesCleanup",
          actualParameter: [
            olderThan: "360",
            completed: "true",
            pipelineProperty: "",
            patternMatching: "",
            chunkSize: "5",
            executeDeletion: "1"
          ]
        )"""
      )
    then: " 1 pipeline was deleted"
      assert getJobProperty("nbFlowRuntimes", red.jobId) == "1"
  }
*/

  // Issue #18: jobsCleanup fails with property error
  def "Issue 18 humanSize"() {
    given:
    when: "running subJC_deleteWorkspace"
      def res=runProcedureDsl """
        runProcedure(
          projectName: "/plugins/$pName/project",
          procedureName: "subJC_deleteWorkspace",
        	actualParameter: [
        	  computeUsage: "1",
        	  executeDeletion: "0",
        	  linDir: "/tmp",
        	  winDir: "",
        	  resName: "local"
        	]
        )"""

    then: "job succeeded"
      assert res?.outcome == 'success'
  }

  def "jobscleanup"() {
    given: "old jobs loaded from XML"
      importXML("data/cleanup/success.xml")
      importXML("data/cleanup/error.xml")
      importXML("data/cleanup/warning.xml")
      importXML("data/cleanup/aborted.xml")
   when: "invoking cleaning job in report mode"
      def result=callJobsCleanup("jobsCleanup", [executeDeletion: "false"])
    then: "it's OK"
      assert result?.outcome == 'success'
      assert getJobProperty("numberOfJobs", result.jobId) == "4"
 }

}
