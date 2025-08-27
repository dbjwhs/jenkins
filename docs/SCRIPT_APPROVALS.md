# Jenkins Script Approvals Documentation

This document explains the pre-approved script signatures in our Jenkins Configuration as Code (JCasC) setup.

## Overview

Jenkins Script Security prevents pipeline scripts from executing potentially dangerous operations. Instead of manually approving scripts each time, we pre-approve common signatures that our pipelines need.

## Pre-approved Signatures

### Basic Groovy/Java Methods
```groovy
// String manipulation
"method java.lang.String toLowerCase"           // text.toLowerCase()
"method java.lang.String join java.lang.CharSequence"  // list.join(' ')
"method java.util.List add java.lang.Object"   // list.add(item)
"staticMethod java.lang.System getenv java.lang.String"  // System.getenv('PATH')
```

### Jenkins Pipeline DSL Methods
```groovy
// Environment and Jenkins instance access
"method hudson.model.Run getEnvironment hudson.model.TaskListener"
"method jenkins.model.Jenkins getItemByFullName java.lang.String"
```

### File Operations
```groovy
// File system operations (commonly needed in pipelines)
"new java.io.File java.lang.String"           // new File('/path')
"method java.io.File exists"                  // file.exists()
"method java.io.File isFile"                  // file.isFile()
"method java.io.File isDirectory"             // file.isDirectory()
"method java.io.File getName"                 // file.getName()
"method java.io.File getPath"                 // file.getPath()
"method java.io.File getAbsolutePath"         // file.getAbsolutePath()
```

### String Operations
```groovy
// String manipulation methods
"method java.lang.String contains java.lang.CharSequence"     // str.contains("text")
"method java.lang.String startsWith java.lang.String"         // str.startsWith("prefix")
"method java.lang.String endsWith java.lang.String"           // str.endsWith("suffix")
"method java.lang.String replace java.lang.CharSequence java.lang.CharSequence"  // str.replace("old", "new")
"method java.lang.String split java.lang.String"              // str.split(",")
"method java.lang.String trim"                                // str.trim()
"method java.lang.String substring int"                       // str.substring(5)
"method java.lang.String substring int int"                   // str.substring(1, 5)
```

### Collection Operations
```groovy
// Working with lists and maps
"method java.util.Collection size"            // list.size()
"method java.util.Collection isEmpty"         // list.isEmpty()
"method java.util.List get int"               // list.get(0)
"method java.util.Map get java.lang.Object"   // map.get("key")
"method java.util.Map put java.lang.Object java.lang.Object"  // map.put("key", "value")
"method java.util.Map containsKey java.lang.Object"           // map.containsKey("key")
```

### Groovy Runtime Methods
```groovy
// Groovy collection methods
"staticMethod org.codehaus.groovy.runtime.DefaultGroovyMethods any java.lang.Object groovy.lang.Closure"     // list.any { }
"staticMethod org.codehaus.groovy.runtime.DefaultGroovyMethods collect java.lang.Object groovy.lang.Closure"  // list.collect { }
"staticMethod org.codehaus.groovy.runtime.DefaultGroovyMethods each java.lang.Object groovy.lang.Closure"     // list.each { }
"staticMethod org.codehaus.groovy.runtime.DefaultGroovyMethods findAll java.lang.Object groovy.lang.Closure"  // list.findAll { }
```

## Our Pipeline Usage

These signatures enable our pipelines to:

1. **Check file existence**: `fileExists('package.json')` in auto-detection
2. **Read file contents**: `readFile('CMakeLists.txt')` for project validation  
3. **String manipulation**: `buildType.toLowerCase()` for directory names
4. **Dynamic configuration**: `cmakeArgs.join(' ')` for command building
5. **Environment access**: `env.DETECTED_TYPE` assignments
6. **Parameter handling**: `params.BUILD_TYPE` evaluations

## Security Considerations

✅ **Safe Operations**: These signatures only allow:
- Reading files and checking existence
- String manipulation and formatting
- Basic collection operations
- Environment variable access

❌ **Blocked Operations**: Dangerous operations remain blocked:
- File system modifications (except through `sh` steps)
- Network operations
- Process execution (except through `sh` steps)
- System property modifications

## Adding New Signatures

If you need additional signatures:

1. **Try the pipeline** - Jenkins will show the required signature in the error
2. **Add to jenkins.yaml** in the `security.scriptApproval.approvedSignatures` list
3. **Document here** with explanation of usage
4. **Test in development** before promoting to production

## Example Error and Fix

**Error:**
```
UnapprovedUsageException: script not yet approved for use
Scripts not permitted to use method java.lang.String replaceAll java.lang.String java.lang.String
```

**Fix:**
```yaml
# Add to jenkins.yaml
security:
  scriptApproval:
    approvedSignatures:
      - "method java.lang.String replaceAll java.lang.String java.lang.String"
```

## Enterprise Best Practices

1. **Minimal Permissions**: Only approve signatures actually needed
2. **Regular Review**: Audit approved signatures quarterly
3. **Documentation**: Document all signatures and their purposes
4. **Testing**: Test new signatures in development first
5. **Shared Libraries**: Prefer shared libraries over inline scripts for complex operations
