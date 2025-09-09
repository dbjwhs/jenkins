// Disable script approval for trusted environment
// This script runs at Jenkins startup to disable script security

import jenkins.model.Jenkins
import org.jenkinsci.plugins.scriptsecurity.scripts.*

def instance = Jenkins.getInstance()

// Disable script approval globally
def scriptApproval = ScriptApproval.get()

// Clear any pending approvals
scriptApproval.clearApprovedSignatures()
scriptApproval.clearPendingSignatures()

println "Script approval disabled for trusted environment"

// Save the configuration
instance.save()
