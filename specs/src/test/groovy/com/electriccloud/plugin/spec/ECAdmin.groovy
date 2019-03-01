package com.electriccloud.plugin.spec
import spock.lang.*
//import com.electriccloud.spec.PluginSpockTestSupport

class ECAdmin extends PluginTestHelper {

  def doSetupSpec() {
    dsl """resource 'ecadmin-lin', hostName: 'localhost' """
    dslFile 'dsl/EC-Admin_Test.groovy'
    //dsl "pingResource(resourceName: 'ecadmin-lin')"
  }

  def doCleanupSpec() {
    conditionallyDeleteProject('EC-Admin_Test')
    dsl """deleteResource(resourceName: 'ecadmin-lin')"""
  }

  // Check promotion
  def "plugin promotion"() {
    given:
      def pName='EC-Admin'
    when: 'the plugin is promoted'
      def result = dsl """promotePlugin(pluginName: "$pName")"""
      def version = dsl """getProperty("/plugins/$pName/pluginVersion")"""
      def prop = dsl """getProperty("/plugins/$pName/project/ec_visibility")"""
    then:
      assert result.plugin.pluginVersion == version.property.value
      assert prop.property.value == 'pickListOnly'
    }

  // Check properties /plugins/EC-Admin/projects/scripts work properly
  def "scripts_perlCommonLib"() {
    given:
    when:
      def result=runProcedureDsl """runProcedure(projectName: "EC-Admin_Test", procedureName: "scriptsPropertiesTest") """
    then:
      assert result.outcome == 'success'
      assert getStepProperty(result.jobId, "humanSize", "result") == "3.00 MB"
      assert getStepProperty(result.jobId, "humanSize", "exitCode") == "0"
  }

  def "getPS"() {
    given:
    when:
      def result=runProcedureDsl """runProcedure(projectName: "EC-Admin_Test", procedureName: "getPS") """
    then:
      assert result.outcome == 'success'
      assert getStepProperty(result.jobId, "getPSJSON", "exitCode") == "0"
      assert getStepProperty(result.jobId, "getPSXML", "exitCode") == "0"
  }

}