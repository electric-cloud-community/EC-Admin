#############################################################################
#
#  restartAgent -- Script to possibly restart an agent.
#  Copyright 2016 Electric-Cloud Inc.
#
#############################################################################

if ($osIsWindows) {
  $ec->setProperty("summary", "Rebooting the agent");
  system("shutdown /r /c \"CloudBees Flow: modification of the Java Heap memory settings\" /t 15")
}
