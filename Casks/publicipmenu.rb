cask "publicipmenu" do
  arch arm: "AppleSilicon", intel: "Universal"

  version "1.1.1"
  sha256 arm:   "cdd95331278782810a1fd0bf9d004441011af0d05ee511cdce077a8732900ed5",
         intel: "77257a43e3be46e28043616bf89620a26a02299361283928d085f0768e2f80ce"

  url "https://github.com/quyend-vn/publicipmenu/releases/download/v#{version}/Public-IP-#{version}-#{arch}.dmg"
  name "Public IP"
  desc "View and copy your public IP from the macOS menu bar"
  homepage "https://github.com/quyend-vn/publicipmenu"

  depends_on macos: :ventura

  app "Public IP.app"

  caveats <<~EOS
    This app is ad-hoc signed and not notarised. macOS may block first launch.
    Intel support is a cross-compiled preview; Intel runtime testing is pending.
    If Public IP is already installed manually, Homebrew may report an app conflict.
  EOS
end
