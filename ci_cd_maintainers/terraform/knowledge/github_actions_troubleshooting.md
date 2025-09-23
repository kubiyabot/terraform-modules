# GitHub Actions Troubleshooting Guide

## Overview
This guide provides comprehensive troubleshooting strategies for common GitHub Actions workflow failures, organized by error categories and solution approaches.

## Common Failure Categories

### 1. Authentication and Permissions

#### GitHub Token Issues
**Error Patterns:**
- `Error: Resource not accessible by integration`
- `HTTP 403: Forbidden`
- `Bad credentials`

**Troubleshooting Steps:**
1. Verify token permissions and scopes
2. Check if token has expired
3. Ensure token has access to the repository
4. For organization repositories, verify SSO requirements
5. Check if GitHub App permissions are sufficient

**Solutions:**
```yaml
# Use appropriate token with correct permissions
- name: Checkout code
  uses: actions/checkout@v4
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    
# For cross-repo access, use PAT
- name: Access private repo
  uses: actions/checkout@v4
  with:
    repository: org/private-repo
    token: ${{ secrets.PAT_TOKEN }}
```

#### OIDC Authentication Issues
**Error Patterns:**
- `Error: Could not assume role`
- `OIDC token validation failed`

**Solutions:**
```yaml
permissions:
  id-token: write
  contents: read

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
    aws-region: us-east-1
```

### 2. Dependency and Package Management

#### Node.js/npm Issues
**Error Patterns:**
- `npm ERR! peer dep missing`
- `Error: Cannot resolve dependency`
- `EACCES: permission denied`

**Solutions:**
```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'
    cache: 'npm'
    
- name: Install dependencies
  run: |
    npm ci --prefer-offline --no-audit
    
# For permission issues
- name: Fix npm permissions
  run: |
    sudo chown -R $USER:$(id -gn $USER) ~/.npm
    npm install
```

#### Python/pip Issues
**Error Patterns:**
- `ERROR: Could not find a version that satisfies the requirement`
- `ModuleNotFoundError`
- `pip: command not found`

**Solutions:**
```yaml
- name: Setup Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.9'
    cache: 'pip'
    
- name: Install dependencies
  run: |
    python -m pip install --upgrade pip
    pip install -r requirements.txt
```

### 3. Build and Compilation Errors

#### Docker Build Failures
**Error Patterns:**
- `failed to solve with frontend dockerfile.v0`
- `Error response from daemon`
- `COPY failed: no such file or directory`

**Solutions:**
```yaml
- name: Build Docker image
  run: |
    docker build --no-cache -t app:latest .
    
# For multi-platform builds
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: .
    platforms: linux/amd64,linux/arm64
    push: true
    tags: user/app:latest
```

#### Maven/Gradle Build Issues
**Error Patterns:**
- `Could not resolve dependencies`
- `Compilation failure`
- `OutOfMemoryError`

**Solutions:**
```yaml
- name: Setup Java
  uses: actions/setup-java@v4
  with:
    java-version: '11'
    distribution: 'temurin'
    cache: 'maven'
    
- name: Build with Maven
  run: |
    mvn clean compile -B -V
    
# For memory issues
- name: Build with increased memory
  run: |
    export MAVEN_OPTS="-Xmx2048m"
    mvn clean package
```

### 4. Test Failures

#### Flaky Tests
**Identification:**
- Tests pass locally but fail in CI
- Intermittent failures
- Race conditions

**Solutions:**
```yaml
- name: Run tests with retry
  uses: nick-invision/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: npm test

# Parallel test execution
- name: Run tests in parallel
  run: |
    npm test -- --maxWorkers=2
```

#### Test Environment Issues
**Error Patterns:**
- `Connection refused`
- `Service unavailable`
- `Database connection failed`

**Solutions:**
```yaml
services:
  postgres:
    image: postgres:13
    env:
      POSTGRES_PASSWORD: postgres
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5

- name: Wait for services
  run: |
    sleep 10
    curl --retry 10 --retry-delay 5 http://localhost:3000/health
```

### 5. Resource and Performance Issues

#### Runner Resource Constraints
**Error Patterns:**
- `No space left on device`
- `killed` (OOM killer)
- `timeout exceeded`

**Solutions:**
```yaml
- name: Free disk space
  run: |
    sudo rm -rf /usr/share/dotnet
    sudo rm -rf /opt/ghc
    sudo rm -rf /usr/local/share/boost
    df -h
    
- name: Configure job timeout
  timeout-minutes: 30
  
- name: Use larger runner
  runs-on: ubuntu-latest-8-cores
```

#### Network and Connectivity Issues
**Error Patterns:**
- `Connection timed out`
- `Network unreachable`
- `SSL certificate problem`

**Solutions:**
```yaml
- name: Retry network operations
  run: |
    for i in {1..5}; do
      if curl -f https://api.example.com/health; then
        break
      fi
      echo "Attempt $i failed, retrying..."
      sleep 5
    done
```

### 6. Matrix Job Issues

#### Matrix Job Failures
**Error Patterns:**
- Specific combinations failing
- Inconsistent results across matrix

**Solutions:**
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    node-version: [16, 18, 20]
    include:
      - os: windows-latest
        node-version: 16
        npm-config: --legacy-peer-deps
  fail-fast: false

- name: Install dependencies
  run: |
    npm install ${{ matrix.npm-config }}
```

## Advanced Debugging Techniques

### 1. Enable Debug Logging
```yaml
- name: Enable debug logging
  run: echo "::debug::This is a debug message"
  
# Enable runner debug logging
env:
  ACTIONS_RUNNER_DEBUG: true
  ACTIONS_STEP_DEBUG: true
```

### 2. SSH Access for Debugging
```yaml
- name: Setup SSH for debugging
  if: failure()
  uses: mxschmitt/action-tmate@v3
  with:
    limit-access-to-actor: true
```

### 3. Artifact Collection
```yaml
- name: Upload logs on failure
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: failure-logs
    path: |
      logs/
      *.log
      test-results/
```

## Performance Optimization

### 1. Caching Strategies
```yaml
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      ~/.cache/pip
      ${{ github.workspace }}/.gradle/caches
    key: ${{ runner.os }}-deps-${{ hashFiles('**/package-lock.json', '**/requirements.txt', '**/*.gradle') }}
    restore-keys: |
      ${{ runner.os }}-deps-
```

### 2. Conditional Steps
```yaml
- name: Run only on specific changes
  if: contains(github.event.head_commit.message, '[run-tests]')
  run: npm test

- name: Skip on documentation changes
  if: "!contains(github.event.head_commit.modified, '*.md')"
  run: npm run build
```

### 3. Parallel Job Execution
```yaml
jobs:
  test:
    strategy:
      matrix:
        chunk: [1, 2, 3, 4]
    steps:
      - name: Run test chunk
        run: |
          npm test -- --testNamePattern="chunk-${{ matrix.chunk }}"
```

## Error Pattern Recognition

### 1. Environment-Specific Issues
- **Windows runners**: Path separator issues, case sensitivity
- **macOS runners**: Different package versions, security restrictions  
- **Ubuntu runners**: Package availability, permission issues

### 2. Timing-Related Issues
- **Race conditions**: Service startup delays
- **Network timeouts**: External service dependencies
- **Resource contention**: Shared runner resources

### 3. Version Compatibility Issues
- **Action versions**: Pin to specific versions for stability
- **Tool versions**: Use compatible tool combinations
- **Language versions**: Test across supported versions

## Proactive Monitoring

### 1. Workflow Health Checks
```yaml
- name: Validate workflow syntax
  run: |
    find .github/workflows -name '*.yml' -o -name '*.yaml' | \
    xargs -I {} yamllint {}
```

### 2. Dependency Vulnerability Scanning
```yaml
- name: Run security audit
  run: |
    npm audit --audit-level moderate
    pip-audit
```

### 3. Performance Monitoring
```yaml
- name: Monitor build time
  run: |
    echo "::notice title=Build Duration::Build took ${{ steps.build.outputs.duration }} seconds"
```

## Recovery Strategies

### 1. Automatic Retry Logic
```yaml
- name: Deploy with retry
  uses: nick-invision/retry@v2
  with:
    timeout_minutes: 5
    max_attempts: 3
    retry_on: error
    command: |
      kubectl apply -f deployment.yaml
      kubectl rollout status deployment/app
```

### 2. Fallback Mechanisms
```yaml
- name: Try primary registry
  id: primary
  continue-on-error: true
  run: docker pull registry1.com/image:tag
  
- name: Try backup registry
  if: steps.primary.outcome == 'failure'
  run: docker pull registry2.com/image:tag
```

### 3. Rollback Procedures
```yaml
- name: Rollback on failure
  if: failure()
  run: |
    kubectl rollout undo deployment/app
    kubectl rollout status deployment/app
```

This troubleshooting guide should be used as a reference for quickly identifying and resolving common GitHub Actions workflow issues.