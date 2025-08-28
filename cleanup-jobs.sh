#!/bin/bash

# Cleanup old Jenkins jobs that were removed from jobs.groovy
# This script uses the Jenkins Script Console API

JENKINS_URL="http://localhost:8080"
JENKINS_USER="dbjwhs"
JENKINS_PASS="jenkins"

echo "Cleaning up old Jenkins jobs..."
echo "This will remove: test-repositories folder and python-hello-world job"
echo ""

# Groovy script to execute
SCRIPT='import jenkins.model.Jenkins

def jenkins = Jenkins.instance

// List of jobs/folders to remove
def jobsToRemove = [
    "test-repositories",  // This will remove the folder and all jobs inside
    "python-hello-world"   // Individual job if it exists
]

println "Starting cleanup of old jobs..."

jobsToRemove.each { jobName ->
    def item = jenkins.getItem(jobName)
    if (item) {
        println "Deleting: ${jobName}"
        item.delete()
        println "✓ Deleted ${jobName}"
    } else {
        println "✗ Not found: ${jobName}"
    }
}

println "Cleanup complete!"

// Return remaining items
println ""
println "Remaining top-level items:"
jenkins.items.each { item ->
    println "  - ${item.name}"
}
'

# Execute via Script Console API
echo "Executing cleanup script..."
RESULT=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
  -d "script=$(echo "$SCRIPT" | jq -sRr @uri)" \
  "${JENKINS_URL}/scriptText")

echo ""
echo "Result from Jenkins:"
echo "$RESULT"
echo ""
echo "Cleanup complete! Refresh your Jenkins UI to see the changes."
