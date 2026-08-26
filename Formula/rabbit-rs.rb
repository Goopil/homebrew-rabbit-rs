class RabbitRs < Formula
  desc "High-performance RabbitMQ transport for PHP, powered by Rust"
  homepage "https://github.com/Goopil/rabbit-rs"
  license "MIT"
  version "0.0.6"

  # Class-level URL is the PHP 8.4 macOS arm64 NTS binary.
  # PHP 8.5 is handled via a resource block below.
  # In install, we detect the PHP version and stage the correct artifact.
  url "https://github.com/Goopil/rabbit-rs/releases/download/v0.0.6/php_rabbit_rs-v0.0.6_php8.4-arm64-darwin-nts.zip"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  depends_on "php"

  # PHP 8.5 macOS arm64 NTS binary.
  resource "php85" do
    url "https://github.com/Goopil/rabbit-rs/releases/download/v0.0.6/php_rabbit_rs-v0.0.6_php8.5-arm64-darwin-nts.zip"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  def install
    php_version = Utils.safe_popen_read(Formula["php"].opt_bin/"php-config", "--version").strip
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
      # The class-level URL (PHP 8.4) is already staged by Homebrew.
      cp "rabbit_rs.so", libexec/"rabbit_rs.so"
    else
      # PHP 8.5 uses the resource block.
      resource("php85").stage do
        cp "rabbit_rs.so", libexec/"rabbit_rs.so"
      end
    end
  end

  def post_install
    ext_dir = Utils.safe_popen_read(Formula["php"].opt_bin/"php-config", "--extension-dir").strip

    ini_path = etc/"php/conf.d/ext-rabbit_rs.ini"

    ext_so = Pathname.new(ext_dir)/"rabbit_rs.so"
    ohai "Installing rabbit_rs.so into #{ext_dir}"
    ln_sf libexec/"rabbit_rs.so", ext_so

    ohai "Creating INI file at #{ini_path}"
    ini_path.dirname.mkpath
    File.write(ini_path, "extension=rabbit_rs.so\n")
  end

  def uninstall
    ini_path = etc/"php/conf.d/ext-rabbit_rs.ini"
    ini_path.unlink if ini_path.exist?

    ext_dir = Utils.safe_popen_read(Formula["php"].opt_bin/"php-config", "--extension-dir").strip
    ext_so = Pathname.new(ext_dir)/"rabbit_rs.so"
    ext_so.unlink if ext_so.symlink? && ext_so.exist?
  end

  test do
    assert_match "rabbit_rs", shell_output("#{Formula["php"].opt_bin/"php"} -m")
  end
end
