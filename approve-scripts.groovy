#!/usr/bin/env groovy

// Jenkins script console script to auto-approve all pending scripts
// Usage: Run this in Jenkins Script Console (Manage Jenkins > Script Console)
// Or via CLI: java -jar jenkins-cli.jar -s http://localhost:8080 groovy approve-scripts.groovy

import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval

def scriptApproval = ScriptApproval.get()

// Approve all pending scripts
def pendingScripts = scriptApproval.getPendingScripts()
pendingScripts.each { script ->
    println "Approving script: ${script.script.substring(0, Math.min(100, script.script.length()))}..."
    scriptApproval.approveScript(script.getHash())
}

// Approve all pending signatures
def pendingSignatures = scriptApproval.getPendingSignatures()
pendingSignatures.each { signature ->
    println "Approving signature: ${signature.signature}"
    scriptApproval.approveSignature(signature.signature)
}

// Approve all pending classpath entries
def pendingClasspaths = scriptApproval.getPendingClasspathEntries()
pendingClasspaths.each { classpath ->
    println "Approving classpath: ${classpath.getHash()}"
    scriptApproval.approveClasspathEntry(classpath.getHash())
}

println "\nApproval complete!"
println "Approved ${pendingScripts.size()} scripts"
println "Approved ${pendingSignatures.size()} signatures"
println "Approved ${pendingClasspaths.size()} classpath entries"
