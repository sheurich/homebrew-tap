class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git",
    tag:      "v0.20250908.0",
    revision: "3250145c2e51580da910ce45ed5f69386331bb0f"
  license "MPL-2.0"

  head "https://github.com/letsencrypt/boulder.git",
    branch: "main"

  livecheck do
    url :stable
    strategy :github_tags
    # Boulder tags are strictly v0.YYYYMMDD.N (e.g., v0.20250728.0); capture the full numeric version
    regex(/^v?(0\.\d{8}\.\d+)$/i)
  end

  depends_on "go" => :build

  def install
    # Derive Go target platform from current build environment
    # Homebrew handles cross-compilation separately, so we use the current platform
    build_os = Utils.safe_popen_read("go", "env", "GOOS").strip
    build_arch = Utils.safe_popen_read("go", "env", "GOARCH").strip
    build_host = "#{build_os}/#{build_arch}"

    if build.head?
      # For HEAD builds: use short commit for BUILD_ID and actual commit timestamp
      build_id = Utils.git_short_head(length: 8) || "head"
      commit_ref = "HEAD"
    else
      # For stable builds: use tag without 'v' prefix for BUILD_ID and pinned revision
      build_id = stable.specs[:tag].delete_prefix("v")
      commit_ref = stable.specs[:revision]
    end

    # Extract commit timestamp using Git, ensuring we get the actual commit time
    # This provides reproducible builds for stable releases
    raw_time =
      Utils.safe_popen_read(
        Utils::Git.git,
        "show",
        "-s",
        "--format=%cI",
        commit_ref,
        chdir: buildpath,
      ).to_s.strip
    odie "Failed to determine commit time for #{commit_ref}" if raw_time.empty?

    # Normalize timestamp to UTC ISO 8601 format for consistency
    # Parse the timestamp (which may include timezone) and convert to UTC
    build_time = Time.iso8601(raw_time).utc.iso8601

    # Build with Boulder's expected variables
    system "make", "BUILD_ID=#{build_id}", "BUILD_TIME=#{build_time}", "BUILD_HOST=#{build_host}"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/boulder --version")
  end
end
