# typed: false
# frozen_string_literal: true

class FlowCli < Formula
  desc "ZSH workflow tools designed for ADHD brains"
  homepage "https://data-wise.github.io/flow-cli/"
  url "https://github.com/Data-Wise/flow-cli/archive/refs/tags/v4.5.3.tar.gz"
  sha256 "79d2108d0bacd82341f8e5175e3102cb3f4afacab68effc01c802b7ca00d8672"
  license "MIT"
  head "https://github.com/Data-Wise/flow-cli.git", branch: "main"

  depends_on "zsh"
  depends_on "git"
  depends_on "fzf"

  def install
    # Install the plugin files
    prefix.install Dir["*"]

    # Create a loader script
    (prefix/"bin/flow-cli-init").write <<~EOS
      #!/bin/zsh
      # Source this file in your .zshrc to enable flow-cli
      # Add to .zshrc: eval "$(flow-cli-init)"

      echo "source #{prefix}/flow.plugin.zsh"
    EOS
    (prefix/"bin/flow-cli-init").chmod 0755
  end

  def caveats
    <<~EOS
      To activate flow-cli, add this to your ~/.zshrc:

        source #{prefix}/flow.plugin.zsh

      Or use the init script:

        eval "$(#{prefix}/bin/flow-cli-init)"

      Then restart your shell or run:
        source ~/.zshrc

      Quick start:
        work my-project    # Start session
        win "Fixed bug"    # Log accomplishment
        finish             # End session
    EOS
  end

  test do
    # Test that the plugin file exists
    assert_predicate prefix/"flow.plugin.zsh", :exist?

    # Test that flow command is defined in the plugin
    output = shell_output("grep -l 'flow()' #{prefix}/**/*.zsh", 0)
    assert_match "flow", output
  end
end
