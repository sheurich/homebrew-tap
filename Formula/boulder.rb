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
    # https://github.com/letsencrypt/boulder/blob/main/docs/release.md
    # Regex matches tags like:
    # - v0.20250728.0
    regex(/^v\d\.(\d{8}(?:\.\d+)*)$/i)
  end

  depends_on "go" => :build

  def install
    build_os = Utils.safe_popen_read("go", "env", "GOOS").strip
    build_arch = Utils.safe_popen_read("go", "env", "GOARCH").strip
    build_host = "#{build_os}/#{build_arch}"
    build_id = stable.specs[:tag].delete_prefix("v")
    build_time = stable.specs[:revision][0, 8]
    system "make", "BUILD_ID=#{build_id}", "BUILD_TIME=#{build_time}",
           "BUILD_HOST=#{build_host}"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match "Versions:", shell_output("#{bin}/boulder --version")
  end
end
