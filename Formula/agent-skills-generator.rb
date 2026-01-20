class AgentSkillsGenerator < Formula
  desc "Crawl docs and transform to Markdown for LLM context"
  homepage "https://github.com/rodydavis/agent-skills-generator"
  license "Apache-2.0"

  head "https://github.com/rodydavis/agent-skills-generator.git",
    branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "crawl", shell_output("#{bin}/agent-skills-generator --help")
  end
end
