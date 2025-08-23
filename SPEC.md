# System Specification: Homebrew Tap Automation

**Document Version**: 1.0  
**Date**: 2025-08-20  
**Repository**: `sheurich/homebrew-tap`  
**System**: Automated Homebrew Formula Management Pipeline  

## 1. System Overview

### 1.1 Purpose
The Homebrew Tap Automation System is designed to automatically maintain up-to-date Homebrew formulae by detecting upstream releases, creating validation pull requests, and merging approved changes without manual intervention.

### 1.2 Scope
This specification covers the complete automated workflow pipeline including:
- Scheduled version detection and bump PR creation
- Comprehensive formula validation and testing
- Automated merging of validated changes
- Development tools and infrastructure

### 1.3 System Goals
- **Reliability**: 99%+ success rate for routine formula updates
- **Performance**: Complete validation cycle in under 5 minutes
- **Security**: Comprehensive validation before any changes reach main branch
- **Maintainability**: Clear documentation and debugging capabilities
- **Scalability**: Support for additional formulae without workflow changes

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Schedulers    │    │   Version Check  │    │  Validation Engine  │
│   (GitHub       │───▶│   & PR Creation  │───▶│  (Build/Test/Audit) │
│   Actions Cron) │    │   (update-tap)   │    │  (auto-merge-bump)  │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                                          │
                                                          ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Developers    │    │   Development    │    │    Main Branch      │
│   (Manual       │◀───│   Tools &        │◀───│   (Updated         │
│   Testing)      │    │   Documentation  │    │   Formulae)         │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

### 2.2 Component Overview

| Component | Type | Responsibility | Frequency |
|-----------|------|----------------|------------|
| `update-tap.yml` | Workflow | Version detection & PR creation | Every 12 hours |
| `auto-merge-bump-pr.yml` | Workflow | Validation & auto-merge | On PR events |
| `dev-test.sh` | Script | Local development testing | On-demand |
| Formula Files | Data | Package definitions | Updated via PRs |
| Documentation | Static | Developer guidance | Updated as needed |

## 3. Detailed Component Specifications

### 3.1 Update-Tap Workflow (`update-tap.yml`)

#### 3.1.1 Purpose
Detects new upstream releases and creates bump pull requests for outdated formulae.

#### 3.1.2 Trigger Conditions
- **Schedule**: Runs at 00:00 and 12:00 UTC daily
- **Manual**: Can be triggered via `workflow_dispatch`
- **Branch**: Executes on `main` branch context

#### 3.1.3 Execution Flow
```
1. Configure Git identity (github-actions[bot])
2. Cleanup existing bump PRs and branches
3. Run Homebrew livecheck for formula updates
4. Create bump PRs for outdated formulae
5. Generate execution summary
```

#### 3.1.4 Key Features
- **Aggressive Cleanup**: Closes existing bump PRs and deletes stale branches
- **API Consistency Handling**: Retry logic for GitHub API race conditions
- **Error Resilience**: Continues execution despite individual formula failures
- **Comprehensive Logging**: Detailed status reporting and debugging information

#### 3.1.5 Environment Variables
```yaml
HOMEBREW_GITHUB_API_TOKEN: ${{ secrets.HOMEBREW_GITHUB_API_TOKEN }}
GH_TOKEN: ${{ github.token }}
```

#### 3.1.6 Outputs
- Bump PRs for formulae with available updates
- Workflow summary with execution status
- Timing metrics and performance data

### 3.2 Auto-Merge Bump PR Workflow (`auto-merge-bump-pr.yml`)

#### 3.2.1 Purpose
Validates bump pull requests through comprehensive testing and automatically merges successful validations.

#### 3.2.2 Trigger Conditions
```yaml
trigger: pull_request
events: [opened, synchronize, reopened, ready_for_review]
if: startsWith(github.head_ref, 'bump-')
```

#### 3.2.3 Security Constraints
Only processes PRs that meet ALL criteria:
- Branch name starts with `bump-`
- Created by automation (specific actor verification)
- Contains automation signature in title or metadata

#### 3.2.4 Validation Pipeline
```
1. Debug Information Collection
2. PR Content Validation
3. Formula Name Extraction & File Verification
4. Style Check (RuboCop)
5. Audit Check (Homebrew standards)
6. Build Test (install from source)
7. Functional Test (brew test)
8. Cleanup (uninstall)
9. Auto-merge (squash & delete branch)
```

#### 3.2.5 Performance Requirements
- **Total execution time**: < 5 minutes target
- **Build timeout**: 10 minutes maximum
- **Individual step timeout**: 2 minutes maximum
- **Cache utilization**: Ruby gems cached between runs

#### 3.2.6 Validation Criteria
```yaml
Style Check: "no offenses detected"
Audit Check: No errors or warnings
Build Test: Successful installation from source
Functional Test: All formula tests pass
Cleanup Test: Successful uninstallation
```

#### 3.2.7 Failure Handling
- **Graceful degradation**: Cleanup on any validation failure
- **User notification**: Comment on PR with failure details
- **Detailed logging**: Error context and troubleshooting guidance
- **No auto-merge**: Manual intervention required for failures

### 3.3 Development Testing Script (`dev-test.sh`)

#### 3.3.1 Purpose
Provides local development testing capabilities for formula validation and workflow debugging.

#### 3.3.2 Usage Patterns
```bash
# Test all formulae
./dev-test.sh

# Test specific formula
./dev-test.sh boulder
./dev-test.sh ingest
```

#### 3.3.3 Test Coverage
- **Style validation**: `brew style --formula`
- **Audit checks**: `brew audit --strict --online`
- **Livecheck testing**: Version update detection
- **Information display**: Formula metadata
- **Workflow validation**: actionlint integration

#### 3.3.4 Output Format
- Color-coded status indicators
- Detailed error reporting
- Performance timing information
- Command reference for manual testing

## 4. Data Specifications

### 4.1 Formula Specifications

#### 4.1.1 Boulder Formula
```ruby
class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git"
  license "MPL-2.0"
end
```

**Version Pattern**: `v0.YYYYMMDD.N` (e.g., `v0.20250819.0`)  
**Livecheck Strategy**: GitHub tags with regex `(/^v?(0\d{8}\.\d+)$/i)`  
**Build Method**: Go compilation with custom BUILD_ID, BUILD_TIME, BUILD_HOST  
**Dependencies**: `go` (build-time only)  
**Test Method**: Version output validation  

#### 4.1.2 Ingest Formula
```ruby
class Ingest < Formula
  desc "Parse directories of plain text files into markdown for AI/LLMs"
  homepage "https://github.com/sammcj/ingest"
  url "https://github.com/sammcj/ingest.git"
  license "MIT"
end
```

**Version Pattern**: `vX.Y.Z` (semantic versioning)  
**Livecheck Strategy**: GitHub tags with regex `(/^v?(\d+\.\d+\.\d+)$/i)`  
**Build Method**: Make with VERSION and BUILD_TIME variables  
**Dependencies**: `go` (build-time only)  
**Test Method**: Version output + functional file processing test  

### 4.2 Configuration Data

#### 4.2.1 Workflow Configuration
```yaml
# Scheduling
cron_schedule: ["0 0 * * *", "0 12 * * *"]
timeout_minutes: 30 (update-tap), 45 (auto-merge)
concurrency: cancel-in-progress

# Permissions
contents: write
pull-requests: write
```

#### 4.2.2 Environment Configuration
```bash
# Performance
HOMEBREW_NO_INSTALL_CLEANUP=1
HOMEBREW_NO_ENV_HINTS=1

# Git Configuration
init.defaultBranch=main
advice.defaultBranchName=false
```

## 5. Interface Specifications

### 5.1 GitHub API Integration

#### 5.1.1 Required Permissions
- **Contents**: Write (for branch operations)
- **Pull Requests**: Write (for PR management)
- **Metadata**: Read (for repository information)

#### 5.1.2 API Endpoints Used
```
GET /repos/{owner}/{repo}/pulls
POST /repos/{owner}/{repo}/pulls/{number}/comments
PATCH /repos/{owner}/{repo}/pulls/{number}
DELETE /repos/{owner}/{repo}/git/refs/heads/{branch}
```

#### 5.1.3 Rate Limiting Considerations
- **Primary token**: HOMEBREW_GITHUB_API_TOKEN (5000 req/hour)
- **Fallback token**: GITHUB_TOKEN (1000 req/hour)
- **Retry strategy**: 3 attempts with exponential backoff
- **Consistency delays**: 5-second initial delay for API consistency

### 5.2 Homebrew Integration

#### 5.2.1 Commands Used
```bash
brew tap sheurich/tap
brew livecheck --formula --newer-only --json
brew bump-formula-pr --no-audit --no-browse
brew style --formula
brew audit --online --strict
brew install --build-from-source
brew test
brew uninstall
```

#### 5.2.2 Action Dependencies
```yaml
actions/checkout@v4
dawidd6/action-homebrew-bump-formula@v4
actions/github-script@v7
Homebrew/actions/setup-homebrew@master
actions/cache@v4
```

## 6. Performance Specifications

### 6.1 Performance Requirements

| Metric | Target | Maximum | Current |
|--------|--------|---------|----------|
| Total validation time | 3 minutes | 5 minutes | ~3 minutes |
| Boulder build time | 45 seconds | 90 seconds | 57 seconds |
| Test execution time | 5 seconds | 15 seconds | 2 seconds |
| Workflow startup time | 30 seconds | 60 seconds | ~30 seconds |
| Cache hit rate | 90% | N/A | ~95% |

### 6.2 Resource Utilization

#### 6.2.1 Runner Resources
- **Platform**: `ubuntu-latest` (Ubuntu 24.04.2 LTS)
- **CPU**: 2 cores (x86_64)
- **Memory**: 7 GB RAM
- **Disk**: 14 GB SSD
- **Network**: Unlimited bandwidth

#### 6.2.2 Cache Utilization
```yaml
Homebrew Ruby Gems: ~13.4MB (cached)
Homebrew Dependencies: Variable (cached)
Go Modules: Not currently cached
Docker Images: Not applicable
```

### 6.3 Scalability Considerations

#### 6.3.1 Horizontal Scaling
- **Concurrent workflows**: Limited by runner availability
- **Formula parallelization**: Currently sequential, could be parallelized
- **Multiple repositories**: Each repository isolated

#### 6.3.2 Growth Projections
- **Current**: 2 formulae
- **Near-term**: 5-10 formulae (no architectural changes needed)
- **Long-term**: 20+ formulae (may require workflow optimization)

## 7. Security Specifications

### 7.1 Authentication & Authorization

#### 7.1.1 Token Management
```yaml
HOMEBREW_GITHUB_API_TOKEN: 
  type: Personal Access Token
  scope: Full repository access
  rotation: Manual
  storage: GitHub Secrets
  
GITHUB_TOKEN:
  type: Automatic Token
  scope: Repository-specific
  rotation: Automatic
  storage: GitHub-managed
```

#### 7.1.2 Actor Verification
```yaml
Allowed Actors:
  - github-actions[bot]
  - dependabot[bot] 
  - sheurich (with automation signature)
  
Verification Methods:
  - Branch name pattern (bump-*)
  - PR title content validation
  - Actor identity checking
```

### 7.2 Input Validation

#### 7.2.1 Branch Name Validation
```regex
Pattern: ^bump-[a-zA-Z0-9_-]+-[0-9]+\.[0-9]+\.[0-9]+$
Example: bump-boulder-0.20250819.0
Validation: Extracted formula name must match existing formula file
```

#### 7.2.2 Formula File Validation
```bash
File Existence: Formula/{name}.rb must exist
Syntax Check: RuboCop validation
Content Audit: Homebrew audit validation
Build Test: Actual compilation/installation
```

### 7.3 Execution Security

#### 7.3.1 Isolation
- **Container isolation**: Each workflow run in fresh container
- **Network isolation**: Limited to required external services
- **Filesystem isolation**: Temporary directories cleaned up
- **Process isolation**: No persistent processes between runs

#### 7.3.2 Code Execution
- **Homebrew sandbox**: All builds run in Homebrew's sandbox
- **No arbitrary code**: Only predefined workflow steps
- **Input sanitization**: All external inputs validated
- **Output restriction**: No sensitive data in logs

## 8. Monitoring and Observability

### 8.1 Logging Specifications

#### 8.1.1 Log Levels
```
INFO: Normal operation events
WARN: Non-critical issues (duplicate PRs, etc.)
ERROR: Validation failures, API errors
DEBUG: Detailed execution information
```

#### 8.1.2 Structured Logging
```yaml
Timing Metrics:
  - workflow_start_time
  - cleanup_duration  
  - build_duration
  - test_duration
  - total_duration
  
Status Indicators:
  - success/failure states
  - validation step results
  - performance measurements
```

### 8.2 Health Monitoring

#### 8.2.1 Success Metrics
- **Workflow success rate**: Target 99%
- **Average execution time**: Target <3 minutes
- **Cache hit rate**: Target 90%
- **API error rate**: Target <1%

#### 8.2.2 Alerting Conditions
```yaml
Critical:
  - Workflow failure rate >5%
  - Build time >10 minutes
  - API rate limit exceeded
  
Warning:
  - Build time >5 minutes
  - Cache miss rate >20%
  - Duplicate PR detection issues
```

## 9. Deployment and Operations

### 9.1 Deployment Process

#### 9.1.1 Workflow Updates
```
1. Changes committed to feature branch
2. Pull request created and reviewed
3. Actionlint validation passes
4. Manual testing completed
5. Merge to main branch
6. Workflows automatically updated
```

#### 9.1.2 Formula Updates
```
1. Upstream release detected
2. Bump PR created automatically
3. Validation pipeline executes
4. Auto-merge on successful validation
5. Users get updated formula
```

### 9.2 Backup and Recovery

#### 9.2.1 Data Backup
- **Repository**: Git history provides full backup
- **Workflow history**: GitHub retains 90 days
- **Cache**: Automatically regenerated as needed
- **Configuration**: Stored in version control

#### 9.2.2 Recovery Procedures
```
Workflow Failure:
  1. Check workflow logs
  2. Verify GitHub API status
  3. Re-run workflow if transient
  4. Manual intervention if systematic
  
Formula Corruption:
  1. Revert to previous commit
  2. Create manual fix PR
  3. Update automation if needed
```

## 10. Compliance and Documentation

### 10.1 Standards Compliance

#### 10.1.1 Homebrew Standards
- **Formula Cookbook**: All formulae follow official guidelines
- **Style Guidelines**: RuboCop validation enforced
- **Audit Standards**: Homebrew audit checks mandatory
- **Testing Requirements**: Functional tests required

#### 10.1.2 GitHub Actions Standards
- **Workflow syntax**: YAML specification compliance
- **Action versions**: Pinned to specific versions
- **Security practices**: No secrets in logs
- **Resource limits**: Timeout and concurrency controls

### 10.2 Documentation Requirements

#### 10.2.1 User Documentation
- **README.md**: Repository overview and basic usage
- **DEVELOPMENT.md**: Setup and development procedures
- **TODO.md**: Future improvements and roadmap
- **SPEC.md**: This system specification

#### 10.2.2 Code Documentation
- **Workflow comments**: Inline explanation of complex logic
- **Script documentation**: Help text and usage examples
- **Formula comments**: Non-obvious build steps explained
- **Commit messages**: Descriptive change documentation

---

**Document Status**: Final  
**Review Required**: Annual or on significant system changes  
**Maintained By**: Repository maintainers  
**Last Updated**: 2025-08-20
