package com.electriccloud.plugin.spec
import spock.lang.*
import org.apache.tools.ant.BuildLogger

class backup extends PluginTestHelper {
  static String pName='EC-Admin'
  static String backupDir='/tmp/BACKUP'
  // Issue 57
  static String group57="AC/DC"
  // Issue 58
  static String gate58="GW58"
  static String res58="gw_resource_58"
  static String zone59="zone59"
  def doSetupSpec() {
    dslFile 'dsl/EC-Admin_Test.groovy'
    new AntBuilder().delete(dir:"$backupDir" )
  }

  def doCleanupSpec() {
   // new AntBuilder().delete(dir:"$backupDir" )
   dsl """
      deleteGroup(groupName: "$group57")
      deleteGateway(gatewayName: "$gate58")
      deleteResource(resourceName: "$res58")
    """
  }

  def runSaveAllObjects(String jobName, def additionnalParams) {
    println "##LR Running runSaveAllObjects"
    def params=[
        pathname: "\"$backupDir\"",
        pattern: "\"\"",
        exportDeploy: "\"false\"",
        exportGateways: "\"false\"",
        exportZones: "\"false\"",
        exportGroups: "\"false\"",
        exportResourcePools: "\"false\"",
        exportResources: "\"false\"",
        exportSteps: "\"false\"",
        exportUsers: "\"false\"",
        exportWorkspaces: "\"false\"",
        format: "\"XML\"",
        pool: "\"default\""
    ]
    assert jobName

    additionnalParams.each {k, v ->
      params[k]="\"$v\""
    }
    def res=runProcedureDslAndRename(
      jobName,
      """runProcedure(
            projectName: "/plugins/$pName/project",
            procedureName: "saveAllObjects",
            actualParameter: $params
         )
      """
    )
    return res
  }

  // Check procedures exist
  def "checkProcedures for backup feature"() {
    given: "a plugin"
    when: "promoted"
      def res1=dsl """
        getProcedure(
          projectName: "/plugins/$pName/project",
          procedureName: "saveAllObjects"
        ) """
      def res2=dsl """
        getProcedure(
          projectName: "/plugins/$pName/project",
          procedureName: "saveProjects"
        ) """

    then: "procedures should be present"
      assert res1?.procedure.procedureName == 'saveAllObjects'
      assert res2?.procedure.procedureName == 'saveProjects'
 }

  // Issue 56: question mark
  def "issue 56 - question mark"() {
    given: "a project with a question mark"
    when: "save objects in XML format"
      def result=runSaveAllObjects("Issue56", [pattern: "EC-Admin_Test"])
    then: "slash replaced by _"
      assert result.jobId
      assert result?.outcome == 'success'
      assert fileExist("$backupDir/projects/EC-Admin_Test/procedures/questionMark/steps/rerun_.xml")
  }

  // Issue 57: group name with "/"
  def "issue 57 - group with slash"() {
    given: "a group with slash in the name"
         dsl """ group "$group57" """
    when: "save objects in XML format"
      def result=runSaveAllObjects("Issue57", [pattern: "AC", exportGroups: "true"])
    then: "question mark replaced by _"
      assert result.jobId
      assert result?.outcome == 'success'
      assert fileExist("$backupDir/groups/AC_DC.xml")
  }

  // Issue 58: backup gateway
  def "issue 58 - backup gateway"() {
    given: "a gateway and a resource"
   dsl """
      resource "$res58",
        hostname: "localhost"

      gateway "$gate58",
        gatewayDisabled: 0,
        description: "for backup testing",
        resourceName1: "local",
        resourceName2: "$res58"
    """
    when: "save objects in XML format"
      def result=runSaveAllObjects("Issue58", [pattern: "$gate58", exportGateways: "true"])
    then: "gateway is saved"
      assert result.jobId
      assert result?.outcome == 'success'
      assert fileExist("$backupDir/gateways/${gate58}.xml")
  }

  // Issue 59: backup zone
  def "issue 59 - backup zone"() {
    given: "a zone"
      dsl """
        zone "$zone59",
          description: "for backup testing"
      """
    when: "save objects in XML format"
      def result=runSaveAllObjects("Issue59", [pattern: "$zone59", exportZones: "true"])
    then: "zone is saved"
      assert result.jobId
      assert result?.outcome == 'success'
      assert fileExist("$backupDir/zones/${zone59}.xml")
  }

}
