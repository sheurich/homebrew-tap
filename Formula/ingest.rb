class Ingest < Formula
  desc "Parse directories of plain text files into markdown for AI/LLMs"
  homepage "https://github.com/sammcj/ingest"
  url "https://github.com/sammcj/ingest.git",
    tag:      "v0.15.0",
    revision: "022a3b073642657744d96d79dff27224d08e65ed"
  license "MIT"

  head "https://github.com/sammcj/ingest.git",
    branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "go" => :build

  def install
    version_tag = stable.specs[:tag]
    build_time = "+#{stable.specs[:revision][0, 8]}"
    system "make", "VERSION=#{version_tag}", "BUILD_TIME=#{build_time}"
    bin.install "ingest"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ingest --version")

    # Test basic functionality
    (testpath/"test.txt").write("Hello, World!")
    output = shell_output("#{bin}/ingest --no-clipboard #{testpath}")
    assert_match "Hello, World!", output
  end
end
