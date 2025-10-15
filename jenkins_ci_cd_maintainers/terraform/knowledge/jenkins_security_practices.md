# Jenkins Security Best Practices

## Authentication and Authorization

### 1. User Management
**Strong Authentication:**
- Enable LDAP/Active Directory integration
- Implement two-factor authentication (2FA)
- Use strong password policies
- Regular user access reviews

**Role-Based Access Control (RBAC):**
```groovy
// Example role configuration
role('developer') {
    permissions {
        builds('read')
        jobs('read', 'build')
        views('read')
    }
}

role('admin') {
    permissions {
        builds('read', 'create', 'update', 'delete')
        jobs('read', 'create', 'update', 'delete')
        views('read', 'create', 'update', 'delete')
        credentials('read', 'create', 'update', 'delete')
    }
}
```

### 2. Project-Based Security
**Fine-grained Permissions:**
- Implement project-based security
- Use matrix-based security for granular control
- Separate permissions for different project types
- Regular permission audits

## Credential Management

### 1. Secure Credential Storage
**Jenkins Credentials Store:**
```groovy
pipeline {
    agent any
    environment {
        DB_PASSWORD = credentials('database-password')
        API_KEY = credentials('api-key')
    }
    stages {
        stage('Deploy') {
            steps {
                sh 'echo "Deploying with secure credentials"'
                // Credentials are automatically masked in logs
            }
        }
    }
}
```

**Best Practices:**
- Never hardcode secrets in pipeline code
- Use appropriate credential types (username/password, secret text, SSH keys)
- Rotate credentials regularly
- Use least privilege principle
- Encrypt credentials at rest

### 2. External Secret Management
**Integration with HashiCorp Vault:**
```groovy
stage('Get Secrets') {
    steps {
        script {
            def secrets = vault([
                path: 'secret/myapp',
                secretValues: [
                    [envVar: 'DB_PASSWORD', vaultKey: 'password'],
                    [envVar: 'API_KEY', vaultKey: 'api_key']
                ]
            ])
        }
    }
}
```

## Pipeline Security

### 1. Script Security
**Sandboxed Execution:**
```groovy
pipeline {
    agent any
    options {
        // Enable script security
        skipDefaultCheckout()
    }
    stages {
        stage('Secure Build') {
            steps {
                // Use approved methods only
                sh 'mvn clean package'
                archiveArtifacts artifacts: 'target/*.jar'
            }
        }
    }
}
```

**Groovy Sandbox:**
- Enable Groovy sandbox for scripted pipelines
- Use approved methods and classes only
- Regular security script reviews
- Disable dangerous methods

### 2. Input Validation
**Sanitize User Inputs:**
```groovy
stage('User Input') {
    steps {
        script {
            def userInput = input(
                id: 'userInput',
                message: 'Enter deployment environment:',
                parameters: [
                    choice(
                        name: 'ENVIRONMENT',
                        choices: ['dev', 'staging', 'prod'],
                        description: 'Select environment'
                    )
                ]
            )
            
            // Validate input
            if (!['dev', 'staging', 'prod'].contains(userInput)) {
                error "Invalid environment: ${userInput}"
            }
        }
    }
}
```

## Network Security

### 1. HTTPS Configuration
**SSL/TLS Setup:**
- Use HTTPS for all Jenkins communications
- Implement proper SSL certificates
- Enable HSTS headers
- Regular certificate renewal

**Reverse Proxy Configuration:**
```nginx
server {
    listen 443 ssl;
    server_name jenkins.company.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 2. Firewall Configuration
**Network Segmentation:**
- Restrict Jenkins access to authorized networks
- Use VPN for remote access
- Implement network monitoring
- Regular firewall rule reviews

## Plugin Security

### 1. Plugin Management
**Security Considerations:**
- Only install plugins from trusted sources
- Keep plugins updated regularly
- Remove unused plugins
- Review plugin permissions

**Plugin Security Checklist:**
- Check plugin security advisories
- Verify plugin signatures
- Test plugins in staging environment
- Document plugin usage and purpose

### 2. Approved Plugins List
**Essential Security Plugins:**
- Role-based Authorization Strategy
- Credentials Binding
- Build Timeout
- Timestamper
- Workspace Cleanup

## Build Security

### 1. Secure Build Environment
**Isolated Build Agents:**
```groovy
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            args '-u root:root'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
    }
    post {
        always {
            sh 'rm -rf ~/.m2/repository'
        }
    }
}
```

**Container Security:**
- Use minimal base images
- Run containers as non-root user
- Implement resource limits
- Regular image vulnerability scanning

### 2. Artifact Security
**Secure Artifact Handling:**
```groovy
stage('Publish Artifacts') {
    steps {
        script {
            // Sign artifacts
            sh 'gpg --sign --armor target/myapp.jar'
            
            // Upload to secure repository
            nexusArtifactUploader(
                nexusVersion: 'nexus3',
                protocol: 'https',
                nexusUrl: 'https://nexus.company.com',
                groupId: 'com.company',
                version: "${env.BUILD_NUMBER}",
                repository: 'releases',
                credentialsId: 'nexus-credentials',
                artifacts: [
                    [artifactId: 'myapp',
                     classifier: '',
                     file: 'target/myapp.jar',
                     type: 'jar']
                ]
            )
        }
    }
}
```

## Monitoring and Auditing

### 1. Security Monitoring
**Audit Logging:**
- Enable comprehensive audit logging
- Monitor failed login attempts
- Track credential usage
- Log all administrative actions

**Security Alerts:**
```groovy
stage('Security Scan') {
    steps {
        script {
            // Run security scans
            sh 'mvn org.owasp:dependency-check-maven:check'
            sh 'mvn com.github.spotbugs:spotbugs-maven-plugin:check'
            
            // Publish security reports
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'target',
                reportFiles: 'dependency-check-report.html',
                reportName: 'Security Report'
            ])
        }
    }
}
```

### 2. Compliance and Reporting
**Security Compliance:**
- Regular security assessments
- Compliance reporting
- Vulnerability management
- Incident response procedures

## Incident Response

### 1. Security Incident Handling
**Response Procedures:**
- Immediate containment of security incidents
- Evidence collection and preservation
- Communication with stakeholders
- Post-incident analysis and improvements

### 2. Backup and Recovery
**Secure Backup Strategy:**
- Regular encrypted backups
- Offsite backup storage
- Tested recovery procedures
- Backup integrity verification

## Security Checklist

### 1. Initial Setup
- [ ] Enable HTTPS
- [ ] Configure strong authentication
- [ ] Set up RBAC
- [ ] Enable audit logging
- [ ] Configure firewall rules

### 2. Ongoing Maintenance
- [ ] Regular security updates
- [ ] Plugin security reviews
- [ ] User access reviews
- [ ] Security monitoring
- [ ] Backup verification

### 3. Pipeline Security
- [ ] Secure credential management
- [ ] Input validation
- [ ] Sandboxed execution
- [ ] Artifact signing
- [ ] Security scanning integration
