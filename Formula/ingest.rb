class Ingest < Formula
  desc "Parse directories of plain text files into markdown for AI/LLMs"
  homepage "https://github.com/sammcj/ingest"
  url "https://github.com/sammcj/ingest.git",
    tag:      "v0.15.1",
    revision: "50b94f6d95eff18ed263f79eb35edfed01b7cf44"
  license "MIT"

  head "https://github.com/sammcj/ingest.git",
    branch: "main"

  livecheck do
    url :stable
    strategy :github_tags
    # Only match proper semver tags like vX.Y.Z and capture the version
    regex(/^v?(\d+\.\d+\.\d+)$/i)
  end

  depends_on "go" => :build

  def install
    # Determine version and build information based on build type
    if head?
      # For HEAD builds: use "HEAD" as version tag and current commit hash
      version_tag = "HEAD"
      build_time = "+#{Utils.safe_popen_read("git", "rev-parse", "--short=8", "HEAD").strip}"
    else
      # For stable builds: use the actual version tag and pinned revision hash
      version_tag = stable.specs[:tag]
      build_time = "+#{stable.specs[:revision][0, 8]}"
    end
    
    # Build using upstream's Makefile with expected variables
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
