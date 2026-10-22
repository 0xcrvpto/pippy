"""Export the master artwork at every macOS icon size and package with iconutil."""
from pathlib import Path
import subprocess
root = Path(__file__).resolve().parent.parent
iconset = root / '.build/Pippy.iconset'
iconset.mkdir(parents=True, exist_ok=True)
for size in (16, 32, 128, 256, 512):
    for scale in (1, 2):
        name = f'icon_{size}x{size}' + ('@2x' if scale == 2 else '') + '.png'
        subprocess.run(['sips', '-z', str(size*scale), str(size*scale),
                        str(root/'Assets/AppIcon.png'), '--out', str(iconset/name)],
                       check=True, stdout=subprocess.DEVNULL)
subprocess.run(['iconutil', '-c', 'icns', str(iconset), '-o',
                str(root/'dist/Pippy.app/Contents/Resources/Pippy.icns')], check=True)
