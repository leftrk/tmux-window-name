class TmuxWindowName < Formula
  desc "Smart tmux window names like IDE tablines"
  homepage "https://github.com/leftrk/tmux-window-name"
  url "https://github.com/leftrk/tmux-window-name/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "ed4af28c39ab6823b8affb299e15a9e4605dd75e656ae2b8ec38b6a046712e1a"
  license "MIT"
  head "https://github.com/leftrk/tmux-window-name.git", branch: "master"

  depends_on "tmux"
  depends_on "python@3.11"

  resource "libtmux" do
    url "https://files.pythonhosted.org/packages/12/2e/819d7414b96f19ec4cafda95555246bdb9766dd7c0519b5b1bf4495789f7/libtmux-0.55.1-py3-none-any.whl"
    sha256 "4382667d508610bdf71a7cc07d7a561d402fa2d5621cce299e7ae97b0cdcb93b"
  end

  def install
    # Create virtualenv
    system "python3.11", "-m", "venv", libexec
    
    # Install libtmux dependency
    libtmux_wheel = resource("libtmux")
    libtmux_wheel.stage do
      system libexec/"bin/pip", "install", "--no-deps", Dir["*.whl"].first
    end
    
    # Install the main package from buildpath
    system libexec/"bin/pip", "install", "--no-deps", buildpath
    
    # Install entry script
    libexec.install buildpath/"tmux_window_name.tmux"
  end

  def caveats
    <<~EOS
      To enable this plugin, add to your ~/.tmux.conf:

        With TPM (recommended):
          set -g @plugin 'leftrk/tmux-window-name'

        Without TPM:
          run-shell #{libexec}/tmux_window_name.tmux

      Note: If using tmux-resurrect, load this plugin BEFORE it.
    EOS
  end

  test do
    assert_predicate libexec/"tmux_window_name.tmux", :exist?
    assert_predicate libexec/"bin/tmux-window-name", :exist?
  end
end
