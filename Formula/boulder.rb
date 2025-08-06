class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git",
    tag:      "v0.20250805.0",
    revision: "181617284ddce4e555ebae505f782cb0ab4b1a93"
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
      # Use short commit for BUILD_ID and commit timestamp (UTC, RFC 3339) for BUILD_TIME when building from HEAD
      build_id = Utils.git_short_head(length: 8) || "head"
      build_time = Utils.git_time(commit: "HEAD").utc.iso8601
    else
      # Always use the pinned revision for both BUILD_ID and BUILD_TIME to ensure reproducibility
      rev = stable.specs[:revision]
      build_id = stable.specs[:tag].delete_prefix("v")
      build_time = Utils.git_time(commit: rev).utc.iso8601
    end

    system "make", "BUILD_ID=#{build_id}", "BUILD_TIME=#{build_time}", "BUILD_HOST=#{build_host}"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match "Versions:", shell_output("#{bin}/boulder --version")
  end
end
