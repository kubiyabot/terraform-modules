# Workflow Optimization Strategies

## Overview
This guide provides comprehensive strategies for optimizing GitHub Actions workflows to reduce execution time, resource usage, and costs while maintaining reliability and effectiveness.

## Performance Optimization Fundamentals

### 1. Execution Time Optimization

#### Parallel Job Execution
```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [16, 18, 20]
    runs-on: ${{ matrix.os }}
    steps:
      - name: Build for ${{ matrix.os }} Node ${{ matrix.node-version }}
        run: npm run build
```

#### Job Dependencies
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build application
        run: npm run build
  
  test:
    needs: build
    runs-on: ubuntu-latest
    strategy:
      matrix:
        test-suite: [unit, integration, e2e]
    steps:
      - name: Run ${{ matrix.test-suite }} tests
        run: npm run test:${{ matrix.test-suite }}
  
  deploy:
    needs: [build, test]
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to staging
        run: npm run deploy
```

#### Conditional Job Execution
```yaml
jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      backend-changed: ${{ steps.changes.outputs.backend }}
      frontend-changed: ${{ steps.changes.outputs.frontend }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            backend:
              - 'backend/**'
            frontend:
              - 'frontend/**'
  
  build-backend:
    needs: detect-changes
    if: needs.detect-changes.outputs.backend-changed == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Build backend
        run: npm run build:backend
```

### 2. Caching Strategies

#### Multi-Level Caching
```yaml
- name: Cache node modules
  uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
      
- name: Cache build outputs
  uses: actions/cache@v4
  with:
    path: |
      dist/
      build/
    key: ${{ runner.os }}-build-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-build-
```

#### Docker Layer Caching
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  with:
    driver-opts: |
      cache-from=type=gha
      cache-to=type=gha,mode=max

- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
    push: true
    tags: myapp:latest
```

#### Custom Cache Implementation
```yaml
- name: Restore workspace cache
  id: cache-workspace
  uses: actions/cache@v4
  with:
    path: |
      node_modules
      .next/cache
      .eslintcache
    key: ${{ runner.os }}-workspace-${{ hashFiles('**/package-lock.json', '**/.eslintrc.js') }}
    
- name: Install dependencies
  if: steps.cache-workspace.outputs.cache-hit != 'true'
  run: npm ci --prefer-offline
```

### 3. Resource Optimization

#### Right-Sizing Runners
```yaml
jobs:
  light-tasks:
    runs-on: ubuntu-latest
    steps:
      - name: Lint code
        run: npm run lint
  
  heavy-tasks:
    runs-on: ubuntu-latest-8-cores
    steps:
      - name: Run comprehensive tests
        run: npm run test:full
      
  gpu-tasks:
    runs-on: [self-hosted, gpu]
    steps:
      - name: Train ML model
        run: python train_model.py
```

#### Memory and CPU Optimization
```yaml
- name: Optimize Java build
  run: |
    export MAVEN_OPTS="-Xmx4096m -XX:MaxPermSize=256m"
    mvn clean package -T 4C
    
- name: Optimize Node.js build  
  run: |
    export NODE_OPTIONS="--max-old-space-size=4096"
    npm run build -- --max_old_space_size=4096
```

## Advanced Optimization Techniques

### 1. Workflow Splitting
```yaml
# .github/workflows/pr-validation.yml
name: PR Validation
on:
  pull_request:
    branches: [main]

jobs:
  quick-checks:
    runs-on: ubuntu-latest
    steps:
      - name: Lint and type check
        run: |
          npm run lint
          npm run type-check
  
# .github/workflows/full-test-suite.yml  
name: Full Test Suite
on:
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'

jobs:
  comprehensive-tests:
    runs-on: ubuntu-latest
    steps:
      - name: Run all tests
        run: npm run test:all
```

### 2. Smart Test Execution
```yaml
- name: Run affected tests only
  run: |
    # Get list of changed files
    CHANGED_FILES=$(git diff --name-only HEAD~1)
    
    # Run tests only for changed modules
    if echo "$CHANGED_FILES" | grep -q "^backend/"; then
      npm run test:backend
    fi
    
    if echo "$CHANGED_FILES" | grep -q "^frontend/"; then
      npm run test:frontend
    fi
```

### 3. Incremental Builds
```yaml
- name: Incremental build with Nx
  run: |
    npx nx affected:build --base=origin/main --head=HEAD
    
- name: Incremental testing with Nx
  run: |
    npx nx affected:test --base=origin/main --head=HEAD --parallel=3
```

## Cost Optimization

### 1. Runner Cost Management
```yaml
# Use cheaper runners for non-critical tasks
jobs:
  lint:
    runs-on: ubuntu-latest  # $0.008/min
    
  build:
    runs-on: ubuntu-latest-4-cores  # $0.016/min
    
  deploy-prod:
    runs-on: ubuntu-latest-16-cores  # $0.064/min
    if: github.ref == 'refs/heads/main'
```

### 2. Conditional Expensive Operations
```yaml
- name: Run expensive security scan
  if: |
    github.event_name == 'schedule' || 
    contains(github.event.pull_request.labels.*.name, 'security-scan')
  run: |
    docker run --rm -v "$PWD:/app" security-scanner:latest
```

### 3. Artifact Management
```yaml
- name: Upload artifacts with retention
  uses: actions/upload-artifact@v4
  with:
    name: build-artifacts
    path: dist/
    retention-days: 7  # Reduce storage costs
    
- name: Clean up old artifacts
  uses: actions/github-script@v7
  with:
    script: |
      const artifacts = await github.rest.actions.listWorkflowRunArtifacts({
        owner: context.repo.owner,
        repo: context.repo.repo,
        run_id: context.runId
      });
      
      for (const artifact of artifacts.data.artifacts) {
        if (artifact.name.includes('temp-')) {
          await github.rest.actions.deleteArtifact({
            owner: context.repo.owner,
            repo: context.repo.repo,
            artifact_id: artifact.id
          });
        }
      }
```

## Performance Monitoring

### 1. Execution Time Tracking
```yaml
- name: Track execution time
  id: build-timer
  run: |
    START_TIME=$(date +%s)
    npm run build
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    echo "duration=$DURATION" >> $GITHUB_OUTPUT
    echo "::notice title=Build Duration::Build took $DURATION seconds"
    
- name: Alert on slow builds
  if: steps.build-timer.outputs.duration > 300
  run: |
    echo "::warning title=Slow Build::Build took ${{ steps.build-timer.outputs.duration }} seconds, investigate performance"
```

### 2. Resource Usage Monitoring
```yaml
- name: Monitor resource usage
  run: |
    echo "=== CPU Info ==="
    nproc
    lscpu | grep "CPU(s):"
    
    echo "=== Memory Info ==="
    free -h
    
    echo "=== Disk Info ==="
    df -h
    
    echo "=== Process Info ==="
    ps aux --sort=-%cpu | head -10
```

### 3. Performance Benchmarking
```yaml
- name: Benchmark performance
  run: |
    # Run performance tests and collect metrics
    npm run benchmark > benchmark-results.txt
    
    # Compare with baseline
    CURRENT_SCORE=$(grep "Overall Score" benchmark-results.txt | awk '{print $3}')
    BASELINE_SCORE=85
    
    if (( $(echo "$CURRENT_SCORE < $BASELINE_SCORE" | bc -l) )); then
      echo "::warning title=Performance Regression::Current score $CURRENT_SCORE is below baseline $BASELINE_SCORE"
    fi
```

## Optimization Best Practices

### 1. Dependency Management
```yaml
- name: Optimize dependency installation
  run: |
    # Use npm ci instead of npm install
    npm ci --prefer-offline --no-audit --no-fund
    
    # Clean cache after installation
    npm cache clean --force
```

### 2. Build Optimization
```yaml
- name: Optimize build process
  run: |
    # Use production mode
    NODE_ENV=production npm run build
    
    # Enable parallel compilation
    npm run build -- --parallel
    
    # Use build cache
    npm run build -- --cache
```

### 3. Test Optimization
```yaml
- name: Optimize test execution
  run: |
    # Run tests in parallel
    npm test -- --maxWorkers=4
    
    # Skip coverage for speed in PR builds
    if [ "${{ github.event_name }}" = "pull_request" ]; then
      npm test -- --coverage=false
    else
      npm test -- --coverage
    fi
    
    # Use test sharding
    npm test -- --shard=1/4
```

## Environment-Specific Optimizations

### 1. Development Environment
```yaml
- name: Fast feedback for development
  if: github.event_name == 'pull_request'
  run: |
    # Quick lint and type check only
    npm run lint:quick
    npm run type-check:incremental
```

### 2. Staging Environment
```yaml
- name: Comprehensive testing for staging
  if: github.ref == 'refs/heads/develop'
  run: |
    # Full test suite with coverage
    npm run test:full
    npm run e2e:staging
```

### 3. Production Environment
```yaml
- name: Production deployment with safety checks
  if: github.ref == 'refs/heads/main'
  run: |
    # Comprehensive checks before production
    npm run security:scan
    npm run performance:test
    npm run deploy:production --validate
```

## Troubleshooting Performance Issues

### 1. Identifying Bottlenecks
```yaml
- name: Profile workflow execution
  run: |
    # Enable timing for all commands
    set -x
    time npm install
    time npm run build
    time npm test
    set +x
```

### 2. Memory Usage Analysis
```yaml
- name: Monitor memory during build
  run: |
    # Start memory monitoring in background
    while true; do
      echo "$(date): $(free -h | grep Mem:)"
      sleep 10
    done &
    MONITOR_PID=$!
    
    # Run build
    npm run build
    
    # Stop monitoring
    kill $MONITOR_PID
```

### 3. Network Performance
```yaml
- name: Test network performance
  run: |
    # Test download speeds
    time curl -o /dev/null -s https://registry.npmjs.org/
    
    # Check DNS resolution
    time nslookup registry.npmjs.org
```

This optimization guide provides comprehensive strategies for improving GitHub Actions workflow performance while maintaining reliability and cost-effectiveness.