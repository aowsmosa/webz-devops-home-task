# Junior DevOps Engineer Home Task

Highly available Apache on three Ubuntu 18.04 Docker containers (Pacemaker + Corosync, floating IP 172.20.0.100), plus a Jenkins container (webz-004) that checks the floating IP every 5 minutes and appends the result to a log file.

| Container | IP | Role |
|---|---|---|
| webz-001 | 172.20.0.11 | cluster node, preferred active (score 300) |
| webz-002 | 172.20.0.12 | cluster node, second (score 200) |
| webz-003 | 172.20.0.13 | cluster node, third (score 100) |
| webz-004 | 172.20.0.14 | Jenkins, outside the cluster |

Failover is automatic (Pacemaker): about 5 seconds after a hard crash. Tested for one and for two consecutive failures.

## Contents
- `docs/webz-task-documentation.docx` - full documentation: steps and commands, test results, problems and fixes, improvement suggestions
- `base/Dockerfile` - base image (Ubuntu 18.04 with systemd)
- `setup-apache.sh` - Apache virtual host, run on each cluster node
- `setup-jenkins.sh` - Jenkins admin user and the `webz-healthcheck` job, run in webz-004
- `tests/double-failure.sh` - kills two nodes in a row, then restores them
- `evidence/healthcheck.sample.log` - sample of the Jenkins log

No passwords are stored in this repository: choose your own when running the commands (see the documentation).
