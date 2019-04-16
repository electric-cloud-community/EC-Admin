package com.electriccloud.plugin.spec
import spock.lang.*
import org.apache.tools.ant.BuildLogger

class backup extends PluginTestHelper {
  static String pName     = 'EC-Admin'
  static String backupDir = '/tmp/BACKUP'
  static String group57   = "AC/DC"
  static String gate58    = "GW58"
  static String res58     = "gw_resource_58"
  static String zone59    = "zone59"
  static String project63 = "456GHTVF123"
  static String project74 = "ISSUE74"
  static String project77 = "Issue/77"
  static String project83 = " ISSUE83 "
  static String project87 = "issue87"
  static String res88     = "res_SA/issue88"
  static String res89     = "res<issue89>end"
  static String project90 = "_issue90"
  static String project127 = "issue127/win"

  def doSetupSpec() {
    dslFile 'dsl/EC-Admin_Test.groovy'
    new AntBuilder().delete(dir:"$backupDir" )
  }

  def doCleanupSpec() {
    conditionallyDeleteDirectory(backupDir)
    dsl """
      deleteGroup(groupName: "$group57")
      deleteGateway(gatewayName: "$gate58")
      deleteResource(resourceName: "$res58")
      deleteZone(zoneName: "$zone59")
      deleteResource(resourceName: "$res88")
      deleteResource(resourceName: "$res89")
    """
    conditionallyDeleteProject(project63)
    conditionallyDeleteProject(project74)
    conditionallyDeleteProject(project77)
    conditionallyDeleteProject(project83)
    conditionallyDeleteProject(project87)
    conditionallyDeleteProject(project90)
    conditionallyDeleteProject(project127)
}

 def runSaveAllObjects(String jobName, def additionnalParams) {
    println "##LR Running runSaveAllObjects"
    def params=[
        pathname: "\"$backupDir\"",
        pool: "\"default\"",
        caseSensitive: "\"\"",
        pattern: "\"\"",
        exportDeploy: "\"false\"",
        exportGateways: "\"false\"",
        exportZones: "\"false\"",
        exportGroups: "\"false\"",
        exportPersonas: "\"false\"",
        exportResourcePools: "\"false\"",
        exportResources: "\"false\"",
        exportServerProperties: "\"false\"",
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
    given:  "a list of procedure"
      def list= ['saveAllObjects', 'saveProjects']
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
      assert fileExist("$backupDir/groups/AC_DC/group.xml")
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
      assert fileExist("$backupDir/gateways/${gate58}/gateway.xml")
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
      assert fileExist("$backupDir/zones/${zone59}/zone.xml")
  }

  // Issue 63: filter pattern
  def "issue 63 - pattern"() {
    given: "a project"
      dsl """
        project "$project63",
          description: "for backup testing"
      """
    when: "save objects in XML format"
      def result=runSaveAllObjects("Issue63", [pattern: "GHTVF"])
    then: "project is saved"
      assert result.jobId
      assert result?.outcome == 'success'
      assert getJobProperty("projectExported", result.jobId) == "1"
  }

  // save user
  def "save user"() {
    given: "admin user"
    when: "save objects in XML format"
      def result=runSaveAllObjects("saveUser", [exportUsers: "true", pattern: "admin"])
    then: "admin user is saved"
      assert result.jobId
      assert result?.outcome == 'success'
      assert getJobProperty("userExported", result.jobId) == "1"
      assert fileExist("$backupDir/users/admin/user.xml")
  }

  // Issue 74: case insensitive
  def "issue 74 case insensitive option"() {
    given: "a project with all capital name"
      dsl """project "$project74" """
    when: "save objects in XML format"
      def result=runSaveAllObjects(
        "Issue74_case_insensitive",
        [pattern: "issue74", caseSensitive: "i"])
    then: "project is saved with case insensitive option"
      assert result.jobId
      assert result?.outcome == 'success'
      assert getJobProperty("projectExported", result.jobId) == "1"
  }

  // save project with /
  def "issue 77 procedure with slash"() {
    given: "a projet with slash in the name"
      dsl """
        project "$project77",
          description: "for backup testing", {
            procedure "$project77", {
              step 'echo',
                command: "echo HelloWorld"
            }
          }
      """
    when: "save objects in XML format"
      def result=runSaveAllObjects("Issue77", [pattern: "77"])
    then: "project is saved and slash replaced"
      assert result.jobId
      assert result?.outcome == 'success'
      assert getJobProperty("projectExported", result.jobId) == "1"
      assert fileExist("$backupDir/projects/Issue_77")
      assert fileExist("$backupDir/projects/Issue_77/project.xml\n$backupDir/projects/Issue_77/procedures/Issue_77/procedure.xml")
  }

  // Issue 83: heading and trailing spaces
  def "issue 83 trailing spaces"() {
    given: "a projet with trailing space in the name"
      dsl """project "$project83" """
    when: "save objects in XML format"
      def result=runSaveAllObjects("Issue83_space", [pattern: "ISSUE83"])
    then: "project is saved and spaces removed"
      assert result.jobId
      assert result?.outcome == 'success'
      assert getJobProperty("projectExported", result.jobId) == "1"
      assert fileExist("$backupDir/projects/ISSUE83/project.xml")
   }

 // Issue 87: empty pattern
 def "issue 87 empty pattern"() {
   given: "a projet and no pattern used"
     dsl """project "$project87" """
   when: "save objects in XML format"
     def result=runSaveAllObjects("Issue87_emptyPattern",
      [exportUsers: "true", exportZones: "true"])
   then: "project is saved "
     assert result.jobId
     assert result?.outcome == 'success'
     assert fileExist("$backupDir/projects/issue87/project.xml")

   when: "Counting project number"
     def count=dsl """
import com.electriccloud.query.Filter
import com.electriccloud.query.CompositeFilter
import com.electriccloud.query.PropertyFilter
import com.electriccloud.query.Operator
import com.electriccloud.query.SelectSpec
import com.electriccloud.util.SortOrder
import com.electriccloud.util.SortSpec

  def constructFilters(def filters) {
      filters.collect {
          def op = Operator.valueOf(it.operator)
          if (op.isBoolean()) {
              assert it.filters
              new CompositeFilter(op, constructFilters(it.filters) as Filter[])
          } else {
              new PropertyFilter(it.propertyName, op, it.operand1, it.operand2)
          }
      }
  }

      def filters = [[propertyName: "pluginName", operator: "isNull"]]
      return count=countObjects(
        objectType: 'project', filter: constructFilters(filters)
      )"""
    then: "all projects exported"
      assert getJobProperty("projectExported", result.jobId) == count.count

   when: "Counting user number"
     def uCount=dsl """countObjects(objectType: 'user')"""
   then: "all users exported"
     assert getJobProperty("userExported", result.jobId) == uCount.count

   when: "Counting Zone number"
     def zCount=dsl """countObjects(objectType: 'zone')"""
   then: "all zones exported"
     assert getJobProperty("zoneExported", result.jobId) == zCount.count

  }

   // Issue 88: heading and trailing spaces
  def "issue 88 slash in resource"() {
    given: "a resource with a slash in the name"
      dsl """resource "$res88" """
    when: "save objects in XML format"
      def result=runSaveAllObjects("Issue88", [pattern: "issue88", exportResources: "true"])
    then: "project is saved and slash replaced"
      assert result.jobId
      assert result?.outcome == 'success'
      assert fileExist("$backupDir/resources/res_SA_issue88/resource.xml")
  }
  // Issue 89: heading and trailing spaces
  def "issue 89 < and > in filenames"() {
    given: "a resource with < and > in the name"
      dsl """resource "$res89" """
  when: "save objects in XML format"
    def result=runSaveAllObjects("Issue89", [pattern: "issue89", exportResources: "true"])
  then: "resource is saved and slash replaced"
    assert result.jobId
    assert result?.outcome == 'success'
    assert fileExist("$backupDir/resources/res_issue89_end/resource.xml")
  }

  // issue 90 project starting with _
  def "issue 90 project starting with _"() {
    given: "a project whose name starts with _"
      dsl """project "$project90" """
  when: "save objects in XML format"
    def result=runSaveAllObjects("Issue90", [pattern: "issue90"])
  then: "resource is saved and slash replaced"
    assert result.jobId
    assert result?.outcome == 'success'
    assert fileExist("$backupDir/projects/_issue90/project.xml")
  }

  // issue 127 slash in project name
  def "issue 127 slash in project name"() {
    given: "a project whose name contains /"
      dsl """project "$project127", { procedure 'foo/bar' } """
  when: "save objects in XML format"
    def result=runSaveAllObjects("Issue127", [pattern: "issue127"])
  then: "resource is saved and slash replaced"
    assert result.jobId
    assert result?.outcome == 'success'
    assert fileExist("$backupDir/projects/issue127_win/project.xml")
    assert fileExist("$backupDir/projects/issue127_win/procedures/foo_bar/procedure.xml")
  }

}
