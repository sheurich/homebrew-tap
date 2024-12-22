class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git",
    tag:      "release-2024-12-17",
    revision: "11d543bd9878f0624b3929a691ae6aa4838d451b"
  license "MPL-2.0"

  head "https://github.com/letsencrypt/boulder.git",
    branch: "main"

  livecheck do
    url :stable
    regex(/^release-?(\d+(-\d+)+)$/i)
  end

  depends_on "go" => :build

  def install
    system "make"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match "Versions:", shell_output("#{bin}/boulder -version")
  end
end
