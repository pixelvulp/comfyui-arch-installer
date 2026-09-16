# Maintainer: pixelvulp <https://github.com/pixelvulp>
pkgname=comfyui-arch-installer
pkgver=1.1.0
pkgrel=1
pkgdesc="GUI installer script for ComfyUI on Arch Linux (Fish Shell Edition)"
arch=('any')
url="https://github.com/pixelvulp/comfyui-arch-installer"
license=('MIT')
depends=('bash' 'zenity' 'git' 'python' 'fish')
optdepends=(
  'nvidia-utils: NVIDIA GPU support'
  'cuda: CUDA backend for PyTorch'
  'rocm-core: AMD ROCm GPU support'
)
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('SKIP')

package() {
  cd "${srcdir}/${pkgname}-${pkgver}"

  install -Dm755 install_comfyui.sh "${pkgdir}/usr/bin/comfyui-arch-installer"

  if [ -f README.md ]; then
    install -Dm644 README.md "${pkgdir}/usr/share/doc/${pkgname}/README.md"
  fi
}
