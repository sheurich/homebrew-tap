class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git",
    tag:      "release-2022-12-12",
    revision: "fe2cf7d13695b9f3de2a2b47aa735fa50a0e2100"
  version "release-2022-12-12"
  license "MPL-2.0"

  head "https://github.com/letsencrypt/boulder.git",
    branch: "main"

  depends_on "go" => :build
  def install
    system "make"
    bin.install Dir["bin/*"]
  end
  test do
    assert_match version.to_s, shell_output("#{bin}/boulder -version")
  end
end
