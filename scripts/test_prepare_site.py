"""Check publication boundaries with source links to corrections."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location('prepare_site', Path(__file__).with_name('prepare-site.py'))
prepare_site = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare_site)


class CorrectionLinksTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.sources = self.root / 'sources'
        self.sources.mkdir()
        for kind in ('markdown', 'tp'):
            prepare_site.write(self.root / f'assets/resource-icons/{kind}.svg', '<svg />')
        prepare_site.write(self.root / 'quartz.config.yaml', '')
        prepare_site.write(self.sources / 'cours.md', '# Cours\n')
        prepare_site.write(self.sources / 'tp.md', '# TP\n\n[Ouvrir la correction](correction.md)\n')
        self.site = {'title': 'Formation', 'baseUrl': 'https://example.test/formation',
                     'tracks': [{'id': 'formation', 'title': 'Formation', 'chapters': [
                         {'slug': '01-cours', 'course': 'cours.md', 'tp': 'tp.md',
                          'correction': 'correction.md'}]}]}
        prepare_site.write(self.root / 'site.json', json.dumps(self.site))

    def build(self, frontmatter):
        prepare_site.write(self.sources / 'correction.md', frontmatter + '# Correction\n\nREPONSE_PRIVEE\n')
        with patch.object(prepare_site, 'ROOT', self.root), patch.object(prepare_site, 'make_pdf', return_value=b'PDF'):
            prepare_site.prepare()

    def assert_private(self):
        content = self.root / 'content'
        manifest = json.loads((content / 'assets/publication-manifest.json').read_text())
        self.assertFalse(manifest['exercises'][0]['correction'])
        for path in content.rglob('*.md'):
            text = path.read_text(encoding='utf-8')
            self.assertNotIn('REPONSE_PRIVEE', text)
            self.assertNotIn('Ouvrir la correction', text)
            self.assertNotIn('Afficher les corrections', text)
        with zipfile.ZipFile(content / 'formation-obsidian.zip') as archive:
            self.assertFalse(any('corrige' in name for name in archive.namelist()))
            self.assertNotIn('Ouvrir la correction', archive.read('tp/01-cours.md').decode())

    def test_private_without_frontmatter(self):
        self.build('')
        self.assert_private()

    def test_publish_then_unpublish(self):
        self.build('---\npublier: true\n---\n')
        content = self.root / 'content'
        page = (content / 'formation/01-cours/tp.md').read_text(encoding='utf-8')
        self.assertIn('Afficher les corrections', page)
        self.assertIn('https://example.test/formation/formation/01-cours/tp-corrigev2', page)
        with zipfile.ZipFile(content / 'formation-obsidian.zip') as archive:
            self.assertIn('tp/01-cours-corrigev2.md', archive.namelist())
            self.assertIn('(01-cours-corrigev2.md)', archive.read('tp/01-cours.md').decode())
        self.build('---\npublier: false\n---\n')
        self.assert_private()

    def test_undeclared_link_still_fails(self):
        prepare_site.write(self.sources / 'tp.md', '# TP\n\n[Inconnu](inconnu.md)\n')
        with self.assertRaisesRegex(ValueError, 'Lien hors ligne non déclaré'):
            self.build('')


if __name__ == '__main__':
    unittest.main()
