class RabbitRs < Formula
  desc "High-performance RabbitMQ transport for PHP, powered by Rust"
  homepage "https://github.com/Goopil/rabbit-rs"
  url "https://github.com/Goopil/rabbit-rs/releases/download/v0.1.6/php_rabbit_rs-v0.1.6_php8.4-arm64-darwin-nts.zip"
  sha256 "fd9a1d89c6bb5e7ffd5e3a8a1a331e0f3d3db23033469fb32a37c881970f83f6"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "php"

  # PHP 8.5 macOS arm64 NTS binary.
  resource "php85" do
    url "https://github.com/Goopil/rabbit-rs/releases/download/v0.1.6/php_rabbit_rs-v0.1.6_php8.5-arm64-darwin-nts.zip"
    sha256 "b825b5a9465eef63e87dc824ea10a324b3bead20d536aa8f5e086a613267ce8a"
  end

  def install
    php_version = Utils.safe_popen_read(formula_opt_bin("php")/"php-config", "--version").strip
    php_major_minor = php_version.split(".")[0, 2].join(".")

    supported = ["8.4", "8.5"]
    unless supported.include?(php_major_minor)
      odie "rabbit-rs requires PHP 8.4 or 8.5. Found #{php_version}. Use PIE for other versions."
    end

    if Hardware::CPU.arch != :arm64
      odie "rabbit-rs Homebrew formula supports Apple Silicon only. Use PIE on Intel Macs."
    end

    libexec.mkpath

    if php_major_minor == "8.4"
      cp "rabbit_rs.so", libexec/"rabbit_rs.so"
    else
      resource("php85").stage do
        cp "rabbit_rs.so", libexec/"rabbit_rs.so"
      end
    end
  end

  def post_install
    php_config = formula_opt_bin("php")/"php-config"
    ext_dir = Utils.safe_popen_read(php_config, "--extension-dir").strip
    php_version = Utils.safe_popen_read(php_config, "--version").strip
    php_major_minor = php_version.split(".")[0, 2].join(".")

    # Homebrew PHP scans #{etc}/php/{version}/conf.d/ not #{etc}/php/conf.d/
    ini_path = etc/"php"/php_major_minor/"conf.d"/"ext-rabbit_rs.ini"

    ext_so = Pathname.new(ext_dir)/"rabbit_rs.so"
    ohai "Installing rabbit_rs.so into #{ext_dir}"
    ln_sf libexec/"rabbit_rs.so", ext_so

    ohai "Creating INI file at #{ini_path}"
    ini_path.dirname.mkpath
    File.write(ini_path, "extension=rabbit_rs.so\n")
  end

  def uninstall
    php_config = formula_opt_bin("php")/"php-config"
    php_version = Utils.safe_popen_read(php_config, "--version").strip
    php_major_minor = php_version.split(".")[0, 2].join(".")

    ini_path = etc/"php"/php_major_minor/"conf.d"/"ext-rabbit_rs.ini"
    ini_path.unlink if ini_path.exist?

    ext_dir = Utils.safe_popen_read(php_config, "--extension-dir").strip
    ext_so = Pathname.new(ext_dir)/"rabbit_rs.so"
    ext_so.unlink if ext_so.symlink? && ext_so.exist?
  end

  test do
    assert_match "rabbit_rs", shell_output("#{formula_opt_bin("php")}/php -m")
  end
end
