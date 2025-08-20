# Homebrew Tap TODO

This document tracks improvements and enhancements for the sheurich/tap Homebrew repository.

## 🚀 High Priority Formula Improvements

### Boulder Formula

#### Enhanced Testing
- [ ] **Comprehensive binary testing**: Test multiple Boulder binaries (`boulder-ca`, `boulder-ra`, `boulder-sa`, `boulder-va`, `boulder-wfe`)
- [ ] **Version validation**: Ensure version string appears in `--version` output
- [ ] **Help functionality**: Verify `--help` works for all binaries
- [ ] **Configuration validation**: Test config file parsing if available

```ruby
test do
  assert_match version.to_s, shell_output("#{bin}/boulder --version")
  
  # Test that key binaries exist and are functional
  %w[boulder-ca boulder-ra boulder-sa boulder-va boulder-wfe].each do |binary|
    next unless (bin/binary).exist?
    assert_match(/Usage|Commands|Options/i, shell_output("#{bin}/#{binary} --help", 1))
  end
end
```

#### Service Definition
- [ ] **Add service block**: Define how Boulder should run as a system service
- [ ] **Log file management**: Proper log rotation and location
- [ ] **Configuration file paths**: Reference correct config locations

```ruby
service do
  run [opt_bin/"boulder-ca", etc/"boulder/ca.json"]
  keep_alive true
  log_path var/"log/boulder-ca.log"
  error_log_path var/"log/boulder-ca-error.log"
end
```

### Ingest Formula

#### Build Process Improvements
- [ ] **Use Go ldflags**: Properly embed version, commit, and build time
- [ ] **Reproducible builds**: Set SOURCE_DATE_EPOCH
- [ ] **Standard Go build**: Use `std_go_args` for consistency

```ruby
def install
  ldflags = %W[
    -s -w
    -X main.version=#{version}
    -X main.commit=#{stable.specs[:revision][0, 8]}
    -X main.buildTime=#{time.iso8601}
  ]
  
  system "go", "build", *std_go_args(ldflags: ldflags), "."
end
```

#### Enhanced Testing
- [ ] **Directory processing**: Test recursive directory parsing
- [ ] **Multiple formats**: Test JSON and other output formats if supported
- [ ] **Error handling**: Test with invalid inputs
- [ ] **Edge cases**: Empty files, binary files, large files

```ruby
test do
  # Test directory processing
  (testpath/"subdir").mkpath
  (testpath/"subdir/nested.md").write("# Nested content")
  output = shell_output("#{bin}/ingest --recursive --no-clipboard #{testpath}")
  assert_match "Nested content", output
  
  # Test different output formats
  assert_match(/\[.*\]/, shell_output("#{bin}/ingest --format json --no-clipboard #{testpath}"))
end
```

## 🔧 Medium Priority Improvements

### Shell Completions
- [ ] **Ingest completions**: Add bash/zsh/fish completion support
- [ ] **Boulder completions**: If CLI supports completion generation

```ruby
# In install method
generate_completions_from_executable(bin/"ingest", "completion")
```

### Configuration and Documentation
- [ ] **Boulder config installation**: Install sample configuration files
- [ ] **Man pages**: Install documentation if available
- [ ] **Caveats sections**: Add helpful post-install information

```ruby
# Configuration resources
resource "config" do
  url "https://github.com/letsencrypt/boulder/archive/v#{version}.tar.gz"
  sha256 "..."
end

# In install method
resource("config").stage do
  etc.install "test/config" => "boulder"
end
```

### Bottle Support
- [ ] **Add bottle blocks**: Enable binary distribution for faster installation
- [ ] **CI bottle generation**: Set up automated bottle building
- [ ] **Multi-platform support**: ARM64 and x86_64 bottles

```ruby
bottle do
  sha256 cellar: :any_skip_relocation, arm64_sequoia: "..."
  sha256 cellar: :any_skip_relocation, arm64_sonoma:  "..."
  sha256 cellar: :any_skip_relocation, ventura:       "..."
  sha256 cellar: :any_skip_relocation, x86_64_linux:  "..."
end
```

## 🏗️ Workflow and Automation Improvements

### Performance Optimizations
- [x] **Add timing measurements**: Track install/test step performance (completed)
- [x] **Suppress cosmetic warnings**: Clean up Git branch and Homebrew hints (completed) 
- [ ] **Build caching improvements**: Cache Go modules and dependencies between runs
- [ ] **Parallel validation**: Run style/audit checks concurrently with installs
- [ ] **Resource optimization**: Right-size runner instances for workload

### Testing Infrastructure
- [x] **Formula testing CI**: Auto-merge workflow validates all PRs (completed)
- [ ] **Multi-platform testing**: Test on macOS and Linux
- [ ] **Installation testing**: Test from bottles and from source
- [ ] **Upgrade testing**: Test formula upgrades
- [ ] **Regression testing**: Test against previous versions
- [ ] **Load testing**: Validate under concurrent update scenarios

### Monitoring and Observability  
- [x] **Enhanced success logging**: Formula and version details in output (completed)
- [ ] **Performance metrics**: Track build times, test duration, success rates
- [ ] **Workflow health dashboard**: Visual monitoring of automation health
- [ ] **Alert thresholds**: Define SLAs for build times and failure rates
- [ ] **Trend analysis**: Identify performance degradation over time

### Notifications and Alerts
- [ ] **Slack notifications**: Set up failure alerts for maintainers
- [ ] **Email notifications**: Alternative notification channel  
- [ ] **Success summaries**: Daily/weekly automation health reports
- [ ] **Upstream monitoring**: Monitor upstream source health
- [ ] **Dependency alerts**: Notify when dependencies have security updates

### Development Tools
- [ ] **Pre-commit hooks**: Run formula validation before commits
- [ ] **Local testing script**: Enhanced `dev-test.sh` with timing and metrics
- [ ] **Formula linting**: Additional style and best practice checks
- [ ] **Documentation generation**: Auto-generate formula docs
- [ ] **Workflow testing**: Local workflow validation tools

### Error Handling and Resilience
- [x] **Graceful duplicate PR handling**: Aggressive cleanup strategy (completed)
- [ ] **Retry mechanisms**: Automatic retry for transient failures
- [ ] **Circuit breakers**: Pause automation if multiple consecutive failures
- [ ] **Rollback capabilities**: Automatic revert for critical failures
- [ ] **Upstream health checks**: Validate upstream availability before updates
- [ ] **Rate limiting**: Respect GitHub API and upstream service limits

## 📊 Low Priority Nice-to-Have

### User Experience
- [ ] **Caveats for both formulas**: Post-install guidance
- [ ] **Examples directory**: Usage examples and sample configs
- [ ] **Integration tests**: Real-world usage scenarios

### Security and Compliance
- [ ] **Version pinning**: More precise dependency version requirements
- [ ] **Security scanning**: Automated vulnerability checks
- [ ] **License compliance**: Verify all dependencies are properly licensed
- [ ] **Reproducible builds**: Ensure builds are deterministic

### Advanced Features
- [ ] **Head formula improvements**: Better development version support
- [ ] **Options support**: Configurable build options if needed
- [ ] **Dependency optimization**: Minimize required dependencies
- [ ] **Cross-compilation**: Support for multiple architectures

## 🔄 Continuous Improvement

### Regular Maintenance
- [ ] **Monthly dependency updates**: Keep Go and other deps current
- [ ] **Quarterly formula review**: Check for upstream changes
- [ ] **Annual workflow audit**: Review and update automation
- [ ] **Performance monitoring**: Track build and test times

### Community
- [ ] **Contributing guidelines**: Clear instructions for contributors
- [ ] **Issue templates**: Standardized bug reports and feature requests
- [ ] **Release notes**: Document changes and improvements
- [ ] **User feedback**: Collect and act on user suggestions

---

## Implementation Priority

### Phase 1: Core Formula Improvements (Week 1-2)
1. **Week 1**: Enhanced testing for both formulae
2. **Week 2**: Ingest build improvements with ldflags

### Phase 2: User Experience (Week 3-4) 
3. **Week 3**: Shell completions and documentation
4. **Week 4**: Bottle support and CI improvements

### Phase 3: Advanced Workflow Features (Month 2)
5. **Week 5**: Performance monitoring and metrics collection
6. **Week 6**: Notification system (Slack/email) setup
7. **Week 7**: Build caching and parallel processing
8. **Week 8**: Multi-platform testing infrastructure

### Phase 4: Production Hardening (Month 3)
9. **Week 9**: Retry mechanisms and error resilience 
10. **Week 10**: Monitoring dashboard and alerting
11. **Week 11**: Load testing and performance optimization
12. **Week 12**: Security review and dependency scanning

## Recent Workflow Improvements ✅

Based on analysis of successful auto-merge workflow run (PR #63):

### Completed Optimizations
- ✅ **Timing measurements**: Added performance tracking for install (57s) and test (2s) steps
- ✅ **Clean output**: Suppressed Git branch warnings and Homebrew hints
- ✅ **Enhanced logging**: Success messages now include formula name and version details  
- ✅ **CI optimization**: Disabled cleanup during testing for faster execution
- ✅ **Git configuration**: Set 'main' as default branch to avoid warnings

### Workflow Performance Metrics (PR #63)
- **Total validation time**: ~3 minutes (excellent)
- **Boulder build time**: 57 seconds (from source)
- **Test execution**: 2 seconds (fast)
- **Cache efficiency**: 13.4MB cached Ruby gems
- **Success rate**: 100% for properly formatted bump PRs

### Next Performance Targets
- **Build time**: Target <45s for Boulder (current: 57s)
- **Total validation**: Target <2.5min (current: ~3min) 
- **Cache hit rate**: Track and optimize dependency caching
- **Parallel execution**: Run audit/style checks concurrently

## Notes

- All improvements should maintain backward compatibility
- Test thoroughly before implementing in automation
- Consider upstream changes and roadmaps
- Follow Homebrew Formula Cookbook guidelines
- Document all changes in commit messages and release notes
- Monitor workflow performance metrics after each change
- Validate improvements don't break existing security measures
