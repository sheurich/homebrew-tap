class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git",
    tag:      "release-2025-06-03",
    revision: "0d7ea60b2cb6fa3553920d4ad3d630dbea28e66e"
  license "MPL-2.0"

  head "https://github.com/letsencrypt/boulder.git",
    branch: "main"

  livecheck do
    url :stable
    # https://github.com/letsencrypt/boulder/blob/main/docs/release.md
    # Regex matches tags like:
    # - release-YYYY-MM-DD
    # - release-YYYY-MM-DDa
    regex(/^release-(\d{4}-\d{2}-\d{2})([a-z])?$/i)
  end

  depends_on "go" => :build

  def install
    build_os = Utils.safe_popen_read("go", "env", "GOHOSTOS").strip
    build_arch = Utils.safe_popen_read("go", "env", "GOHOSTARCH").strip
    build_host = "#{build_os}/#{build_arch}"
    build_id = stable.specs[:tag]
    build_time = "+#{stable.specs[:revision][0, 8]}"
    ENV["BUILD_HOST"] = build_host
    ENV["BUILD_ID"] = build_id
    ENV["BUILD_TIME"] = build_time
    system "make"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match "Versions:", shell_output("#{bin}/boulder --version")
  end
end
