class Draftforge < Formula
  desc "Fully featured editor to write, review, refine and submit Internet-Drafts"
  homepage "https://github.com/ietf-tools/editor"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ietf-tools/editor/releases/download/0.47.0/ietf-draftforge-mac-arm64-0.47.0.zip"
      sha256 "5fa98106bad2c65b59325ca902c1107b3d1f4a29c8911a876669b6a2131c3ba3"
    else
      url "https://github.com/ietf-tools/editor/releases/download/0.47.0/ietf-draftforge-mac-x64-0.47.0.zip"
      sha256 "d2d9e3e630cb6a92fd9e54031b690f565a04cb55ad6681c39592d4329c754365"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/ietf-tools/editor/releases/download/0.47.0/ietf-draftforge-linux-arm64-0.47.0.tar.gz"
      sha256 "004dd2eedacbbfebe51320c510700195baf3141a5fbb440fef9eef0403b036be"
    else
      url "https://github.com/ietf-tools/editor/releases/download/0.47.0/ietf-draftforge-linux-x64-0.47.0.tar.gz"
      sha256 "c1d0acdb569764a0b6317fea8ccce5f2681729da80fb428acace866ccef43f9b"
    end
  end

  license "BSD-3-Clause"

  livecheck do
    url "https://github.com/ietf-tools/editor"
    strategy :github_tags
    # Only match proper semver tags like X.Y.Z and capture the version
    regex(/^v?(\d+\.\d+\.\d+)$/i)
  end

  def install
    if OS.mac?
      prefix.install "DraftForge.app"
    else
      # For Linux, the tarball extracts to a versioned directory
      extracted_dir = "ietf-draftforge-linux-#{Hardware::CPU.arm? ? "arm64" : "x64"}-#{version}"
      
      # Install the main executable
      bin.install "#{extracted_dir}/draftforge"
      
      # Install runtime libraries and resources in libexec to avoid conflicts
      libexec.install Dir["#{extracted_dir}/*"]
      
      # Create a wrapper script that sets up the environment
      (bin/"draftforge").unlink
      (bin/"draftforge").write <<~EOS
        #!/bin/bash
        exec "#{libexec}/draftforge" "$@"
      EOS
      (bin/"draftforge").chmod 0755
    end
  end

  test do
    if OS.mac?
      # Test that the app bundle exists
      assert_predicate prefix/"DraftForge.app", :exist?
      assert_predicate prefix/"DraftForge.app/Contents/MacOS/DraftForge", :exist?
    else
      # Test that the executable exists and is executable
      assert_predicate bin/"draftforge", :exist?
      assert_predicate bin/"draftforge", :executable?
      
      # Test that libexec contains the actual application files
      assert_predicate libexec/"draftforge", :exist?
      assert_predicate libexec/"resources.pak", :exist?
    end
  end
end