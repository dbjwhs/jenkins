#!/bin/bash

# Auto-approve pending Jenkins scripts
# This script connects to your local Jenkins and approves all pending scripts/signatures

JENKINS_URL="http://localhost:8080"
JENKINS_USER="dbjwhs"
JENKINS_PASS="jenkins"

echo "Auto-approving pending Jenkins scripts..."

# Method 1: Using docker exec to run the groovy script directly in Jenkins container
docker exec jenkins bash -c "cat > /tmp/approve.groovy << 'EOF'
import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval

def scriptApproval = ScriptApproval.get()

// Approve all pending scripts
scriptApproval.getPendingScripts().each { script ->
    scriptApproval.approveScript(script.getHash())
}

// Approve all pending signatures  
scriptApproval.getPendingSignatures().each { signature ->
    scriptApproval.approveSignature(signature.signature)
}

println 'All pending scripts and signatures approved!'
EOF
"

# Execute the script in Jenkins script console
docker exec jenkins bash -c "echo 'jenkins.model.Jenkins.instance.doEval(new File(\"/tmp/approve.groovy\").text)' | java -jar /opt/jenkins-cli.jar -s http://localhost:8080 -auth ${JENKINS_USER}:${JENKINS_PASS} groovy ="

echo "Script approval complete!"
