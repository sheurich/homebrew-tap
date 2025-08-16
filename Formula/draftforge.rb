class Draftforge < Formula
  desc "Fully featured editor to write, review, refine and submit Internet-Drafts"
  homepage "https://github.com/ietf-tools/editor"
  url "https://github.com/ietf-tools/editor/archive/refs/tags/v0.47.0.tar.gz"
  sha256 "d5558cd419c8d46bdc958064cb97f963d1ea793866414c025906ec15033512ed"
  license "BSD-3-Clause"

  depends_on "node@20"

  # Skip Homebrew's automatic dylib path fixing for Electron apps
  # Electron frameworks have pre-compiled libraries that can't be modified
  skip_clean :install_linkage

  livecheck do
    url "https://github.com/ietf-tools/editor"
    strategy :github_tags
    # Only match proper semver tags like X.Y.Z and capture the version
    regex(/^v?(\d+\.\d+\.\d+)$/i)
  end

  def install
    # Set up Node.js environment
    ENV.prepend_path "PATH", Formula["node@20"].opt_bin
    
    # Install NPM dependencies
    system "npm", "install"
    
    # Build the application
    system "npm", "run", "build"
    
    if OS.mac?
      # On macOS, the build creates a .app bundle in dist/electron/Packaged
      app_name = "DraftForge.app"
      built_app = "dist/electron/Packaged/#{app_name}"
      
      if File.directory?(built_app)
        prefix.install built_app
      else
        odie "Could not find built application at #{built_app}"
      end
    else
      # On Linux, find the built executable in dist/electron/Packaged
      packaged_dir = "dist/electron/Packaged"
      executable_name = "draftforge"
      
      if File.directory?(packaged_dir)
        # Install the main executable
        bin.install "#{packaged_dir}/#{executable_name}"
        
        # Install runtime libraries and resources in libexec to avoid conflicts
        libexec.install Dir["#{packaged_dir}/*"]
        
        # Create a wrapper script that sets up the environment
        (bin/executable_name).unlink
        (bin/executable_name).write <<~EOS
          #!/bin/bash
          exec "#{libexec}/#{executable_name}" "$@"
        EOS
        (bin/executable_name).chmod 0755
      else
        odie "Could not find built application in #{packaged_dir}"
      end
    end
  end

  test do
    if OS.mac?
      # Test that the app bundle exists and has the expected structure
      assert_predicate prefix/"DraftForge.app", :exist?
      assert_predicate prefix/"DraftForge.app/Contents/MacOS/DraftForge", :exist?
      assert_predicate prefix/"DraftForge.app/Contents/Info.plist", :exist?
    else
      # Test that the executable exists and is executable
      assert_predicate bin/"draftforge", :exist?
      assert_predicate bin/"draftforge", :executable?
      
      # Test that libexec contains the actual application files
      assert_predicate libexec/"draftforge", :exist?
    end
  end
end