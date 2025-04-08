class Boulder < Formula
  desc "ACME-based certificate authority, written in Go"
  homepage "https://github.com/letsencrypt/boulder"
  url "https://github.com/letsencrypt/boulder.git",
    tag:      "release-2025-04-07",
    revision: "098cf91e99d09d24e23b28e8e452d80e5dfce1c1"
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
    system "make"
    bin.install Dir["bin/*"]
  end

  test do
    assert_match "Versions:", shell_output("#{bin}/boulder -version")
  end
end
