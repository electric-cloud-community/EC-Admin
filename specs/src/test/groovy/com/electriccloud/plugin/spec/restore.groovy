package com.electriccloud.plugin.spec
import spock.lang.*

class restore extends PluginTestHelper {
  static String zone="zone64"
  static String pName='EC-Admin'
  @Shared String pVersion
  @Shared String plugDir

  def doSetupSpec() {
    dsl """deleteZone(zoneName: "$zone")"""
    plugDir = getP("/server/settings/pluginsDirectory")
    pVersion = getP("/plugins/$pName/pluginVersion")
 }

  def doCleanupSpec() {
     dsl """deleteZone(zoneName: "$zone")"""
  }

  // Issue 64
  def "issue 64"() {
    given: "a XML fileset"
    when: "when restored"
      def result=runProcedureDsl """
        runProcedure(
          projectName: "/plugins/$pName/project",
          procedureName: "restoreObjects",
          actualParameter: [
            directory: "$plugDir/$pName-$pVersion/libs/data/restore/",
            force: "false",
            resource: "local"
          ]
        )"""
      def z=dsl """
        getZone(zoneName: "$zone")
      """
    then: "the zone exists"
      assert result.jobId
      assert result?.outcome == 'success'
      assert z.zone.zoneName == zone
  }
}
