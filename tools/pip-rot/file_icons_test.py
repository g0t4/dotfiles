"""Icon matching, rendering, caching, and filesystem-model integration."""
import tempfile
from pathlib import Path
from unittest.mock import patch

from PySide6.QtCore import Qt, QEventLoop, QTimer
from PySide6.QtGui import QPalette
from PySide6.QtWidgets import QApplication, QFileSystemModel

from file_icons import FileIcons
from media import DurationCache, MediaModel

app = QApplication([])
icons = FileIcons()
assert icons.specification('example.py')['name'] == 'Py'
assert icons.specification('Dockerfile')['name'] == 'Dockerfile'
assert icons.specification('movie.MKV') == icons.specification('movie.mkv')
assert icons.specification('unknown.unrecognized')['icon'] == '\uf0f6'
assert icons.specification('folder.py', True)['icon'] == '\uf07b'
for light in (True, False):
    palette = app.palette()
    palette.setColor(QPalette.ColorRole.Base, Qt.GlobalColor.white if light else Qt.GlobalColor.black)
    app.setPalette(palette)
    expected = icons.mappings['light' if light else 'default']['extensions']['py']
    assert icons.specification('file.py') == expected
if icons.font:
    icon = icons.icon('file.py')
    assert icon is not None and not icon.isNull()
    assert icons.icon('other.py') is icon
    image = icon.pixmap(20, 20).toImage()
    assert any(image.pixelColor(x, y).alpha() for x in range(image.width()) for y in range(image.height()))
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'file.py'
    path.touch()
    cache = DurationCache()
    model = MediaModel(cache)
    model.setRootPath(directory)
    loop = QEventLoop()
    QTimer.singleShot(150, loop.quit)
    loop.exec()
    index = model.index(str(path))
    assert index.isValid()
    assert not model.data(index, Qt.ItemDataRole.DecorationRole).isNull()
    assert model.data(index) == 'file.py'
    with patch.object(model.icons, 'font', None):
        assert model.icons.icon('file.py') is None
        # Offscreen Qt may have no native theme icon; preserve whatever Qt provides.
        native = QFileSystemModel.data(model, index, Qt.ItemDataRole.DecorationRole)
        assert model.data(index, Qt.ItemDataRole.DecorationRole).cacheKey() == native.cacheKey()
print('PASS: filename/extension precedence, folder/default icons, light/dark palettes, rendering/cache, model decoration, native fallback')
