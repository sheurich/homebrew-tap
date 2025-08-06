class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git",
    tag:      "v0.20250728.0",
    revision: "3b631bf7d84a9fdc5e34c2027807d096d4fe726d"
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
    build_os = Utils.safe_popen_read("go", "env", "GOOS").strip
    build_arch = Utils.safe_popen_read("go", "env", "GOARCH").strip
    build_host = "#{build_os}/#{build_arch}"

    if build.head?
      # Use short commit for BUILD_ID and commit timestamp (RFC 3339, UTC) for BUILD_TIME when building from HEAD
      build_id = Utils.git_short_head(length: 8) || "head"
      commit_ref = "HEAD"
    else
      # Use the pinned revision for reproducible BUILD_TIME on stable builds
      build_id = stable.specs[:tag].delete_prefix("v")
      commit_ref = stable.specs[:revision]
    end

    # Obtain commit time in ISO 8601 (%cI) from the staged git repo to ensure reproducibility.
    # Fail fast if we cannot determine it.
    build_time = nil
    Dir.chdir(buildpath) do
      build_time = Utils.safe_popen_read("git", "show", "-s", "--format=%cI", commit_ref).strip
    end
    odie "Failed to determine commit time for #{commit_ref}" if build_time.to_s.empty?

    system "make", "BUILD_ID=#{build_id}", "BUILD_TIME=#{build_time}", "BUILD_HOST=#{build_host}"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match "Versions:", shell_output("#{bin}/boulder --version")
  end
end
