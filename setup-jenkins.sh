#!/bin/bash
# Usage: docker exec -i -e JENKINS_ADMIN_PW="<choose-a-password>" webz-004 bash -s < setup-jenkins.sh
set -e
PW="${JENKINS_ADMIN_PW:?set JENKINS_ADMIN_PW before running}"
JH=/var/lib/jenkins

# 1. skip the setup wizard, create the admin user at every start
grep -q runSetupWizard /etc/systemd/system/jenkins.service || \
  sed -i 's#-Djava.awt.headless=true #-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false #' /etc/systemd/system/jenkins.service
mkdir -p $JH/init.groovy.d
cat > $JH/init.groovy.d/security.groovy <<GROOVY
import jenkins.model.*
import hudson.security.*
import hudson.model.User
import jenkins.install.InstallState

def j = Jenkins.get()
def realm = new HudsonPrivateSecurityRealm(false)
if (User.getById("jadmin", false) == null) {
  realm.createAccount("jadmin", "$PW")
}
j.setSecurityRealm(realm)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
j.setAuthorizationStrategy(strategy)
j.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
j.save()
GROOVY

# 2. the job
mkdir -p $JH/jobs/webz-healthcheck
cat > $JH/jobs/webz-healthcheck/config.xml <<'JOBXML'
<?xml version='1.1' encoding='UTF-8'?>
<project>
  <description>Every 5 minutes: curl the floating IP and append the result to /var/log/webz/healthcheck.log</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <jenkins.model.BuildDiscarderProperty>
      <strategy class="hudson.tasks.LogRotator">
        <daysToKeep>-1</daysToKeep>
        <numToKeep>50</numToKeep>
        <artifactDaysToKeep>-1</artifactDaysToKeep>
        <artifactNumToKeep>-1</artifactNumToKeep>
      </strategy>
    </jenkins.model.BuildDiscarderProperty>
  </properties>
  <scm class="hudson.scm.NullSCM"/>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers>
    <hudson.triggers.TimerTrigger>
      <spec>H/5 * * * *</spec>
    </hudson.triggers.TimerTrigger>
  </triggers>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <hudson.tasks.Shell>
      <command><![CDATA[#!/bin/bash
URL="http://172.20.0.100:80/"
LOG="/var/log/webz/healthcheck.log"
TS=$(date -Iseconds)
HDR=$(mktemp); BODY=$(mktemp)
STATS=$(curl -sS -m 10 -D "$HDR" -o "$BODY" -w 'http_code=%{http_code} time_total=%{time_total}s' "$URL" 2>&1) || STATS="CURL_FAILED: $STATS"
SERVER=$(grep -i '^X-Served-By:' "$HDR" | tr -d '\r' | awk '{print $2}')
echo "[$TS] url=$URL served_by=${SERVER:-UNKNOWN} $STATS output=$(tr -d '\n' < "$BODY")" >> "$LOG"
rm -f "$HDR" "$BODY"
tail -n 1 "$LOG"
]]></command>
    </hudson.tasks.Shell>
  </builders>
  <publishers/>
  <buildWrappers/>
</project>
JOBXML
chown -R jenkins:jenkins $JH

systemctl daemon-reload
systemctl restart jenkins
