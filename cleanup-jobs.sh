#!/bin/bash

# Cleanup old Jenkins jobs that were removed from jobs.groovy
# This script runs the cleanup groovy script in Jenkins Script Console

JENKINS_URL="http://localhost:8080"
JENKINS_USER="dbjwhs"
JENKINS_PASS="jenkins"

echo "Cleaning up old Jenkins jobs..."
echo "This will remove: test-repositories folder and python-hello-world job"
echo ""

# Execute the cleanup script via docker exec
docker exec jenkins bash -c "cat > /tmp/cleanup.groovy << 'EOF'
import jenkins.model.Jenkins

def jenkins = Jenkins.instance

// List of jobs/folders to remove
def jobsToRemove = [
    'test-repositories',  // This will remove the folder and all jobs inside
    'python-hello-world'   // Individual job if it exists
]

println 'Starting cleanup of old jobs...'

jobsToRemove.each { jobName ->
    def item = jenkins.getItem(jobName)
    if (item) {
        println \"Deleting: \${jobName}\"
        item.delete()
        println \"✓ Deleted \${jobName}\"
    } else {
        println \"✗ Not found: \${jobName}\"
    }
}

println 'Cleanup complete!'
EOF
"

# Run the script in Jenkins
docker exec jenkins bash -c "echo 'jenkins.model.Jenkins.instance.doEval(new File(\"/tmp/cleanup.groovy\").text)' | java -jar /opt/jenkins-cli.jar -s http://localhost:8080 -auth ${JENKINS_USER}:${JENKINS_PASS} groovy ="

echo ""
echo "Cleanup complete! The old jobs should now be removed."
echo "Refresh your Jenkins UI to see the changes."
