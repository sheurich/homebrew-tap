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
    strategy :git
  end

  depends_on "go" => :build

  def install
    build_os = Utils.safe_popen_read("go", "env", "GOOS").strip
    build_arch = Utils.safe_popen_read("go", "env", "GOARCH").strip
    build_host = "#{build_os}/#{build_arch}"

    if build.head?
      # Use short commit for BUILD_ID and current UTC time for BUILD_TIME when building from HEAD
      build_id = Utils.git_short_head(length: 8) || "head"
      build_time = Time.now.utc.iso8601
    else
      # Use the tag (v0.YYYYMMDD.N) for BUILD_ID and derive BUILD_TIME from the date segment
      tag = stable.specs[:tag]
      build_id = tag.delete_prefix("v")
      # Expect build_id like "0.20250805.0"
      if (m = build_id.match(/^\d+\.(\d{8})(?:\.\d+)*$/))
        ymd = m[1]
        build_time = "#{ymd[0,4]}-#{ymd[4,2]}-#{ymd[6,2]}T00:00:00Z"
      else
        build_time = Time.now.utc.iso8601
      end
    end

    system "make", "BUILD_ID=#{build_id}", "BUILD_TIME=#{build_time}", "BUILD_HOST=#{build_host}"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match "Versions:", shell_output("#{bin}/boulder --version")
  end
end
