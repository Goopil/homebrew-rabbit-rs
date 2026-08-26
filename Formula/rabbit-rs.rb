class RabbitRs < Formula
  desc "High-performance RabbitMQ transport for PHP, powered by Rust"
  homepage "https://github.com/Goopil/rabbit-rs"
  url "https://github.com/Goopil/rabbit-rs/releases/download/v0.0.6/php_rabbit_rs-v0.0.6_php8.4-arm64-darwin-nts.zip"
  version "0.0.6"
    sha256 "1fc7d5a53ccaf7dfefb57fb3dce3eafb706d5ed73e2a4d0955e77a0fbbda7e27"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "php"

  # PHP 8.5 macOS arm64 NTS binary.
  resource "php85" do
    url "https://github.com/Goopil/rabbit-rs/releases/download/v0.0.6/php_rabbit_rs-v0.0.6_php8.5-arm64-darwin-nts.zip"
  sha256 "aba6c8e1c8ebd80f80e47332e5ee03443abb639339969a20fbb22dc0353c5b5d"
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
    ext_dir = Utils.safe_popen_read(formula_opt_bin("php")/"php-config", "--extension-dir").strip

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

    ext_dir = Utils.safe_popen_read(formula_opt_bin("php")/"php-config", "--extension-dir").strip
    ext_so = Pathname.new(ext_dir)/"rabbit_rs.so"
    ext_so.unlink if ext_so.symlink? && ext_so.exist?
  end

  test do
    assert_match "rabbit_rs", shell_output("#{formula_opt_bin("php")}/php -m")
  end
end
