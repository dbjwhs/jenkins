#!/usr/bin/env groovy

// Script to remove old jobs that were deleted from jobs.groovy
// 
// HOW TO USE:
// 1. Go to Jenkins UI
// 2. Navigate to: Manage Jenkins > Script Console
// 3. Paste this entire script into the console
// 4. Click "Run"
// 
// Successfully tested and used via Jenkins Script Console

import jenkins.model.Jenkins

def jenkins = Jenkins.instance

// List of jobs/folders to remove
def jobsToRemove = [
    'test-repositories',  // This will remove the folder and all jobs inside
    'python-hello-world'   // Individual job if it exists
]

println "Starting cleanup of old jobs..."
println "=" * 50

jobsToRemove.each { jobName ->
    def item = jenkins.getItem(jobName)
    if (item) {
        println "Found: ${jobName} (${item.class.simpleName})"
        println "  Full name: ${item.fullName}"
        println "  Deleting..."
        item.delete()
        println "  ✓ Successfully deleted ${jobName}"
    } else {
        println "✗ Not found: ${jobName} (already deleted or doesn't exist)"
    }
}

println "=" * 50
println "Cleanup complete!"
println ""
println "Remaining top-level items:"
jenkins.items.each { item ->
    println "  - ${item.name} (${item.class.simpleName})"
}
