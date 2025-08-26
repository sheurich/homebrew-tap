class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git",
    tag:      "v0.20250825.0",
    revision: "6a10da0c745e1fa9ec1859fe8fd3bb2aaefbff07"
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
    # Derive Go TARGET platform from 'go env' (Homebrew does not cross-compile here).
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

    # Use Homebrew's Utils::Git and safe_popen_read to get the commit timestamp without raw shell-outs.
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

    # Normalize to UTC Zulu: parse ISO 8601 (with tz), convert to UTC, and emit ISO 8601 with trailing 'Z'.
    build_time = Time.iso8601(raw_time).utc.iso8601

    system "make", "BUILD_ID=#{build_id}", "BUILD_TIME=#{build_time}", "BUILD_HOST=#{build_host}"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/boulder --version")
  end
end
