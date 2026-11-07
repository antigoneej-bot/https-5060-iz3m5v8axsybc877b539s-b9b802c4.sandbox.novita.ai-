"""Read-only release/privacy regressions. No credentials or network needed."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
class QualityConfiguration(unittest.TestCase):
    def test_diagnostics_native_collection_is_off_by_default(self):
        root = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml').getroot()
        ns = '{http://schemas.android.com/apk/res/android}'
        settings = {item.attrib.get(ns+'name'): item.attrib.get(ns+'value')
                    for item in root.findall('./application/meta-data')}
        self.assertEqual(settings['firebase_crashlytics_collection_enabled'], 'false')
        self.assertEqual(settings['firebase_analytics_collection_enabled'], 'false')
    def test_script_line_endings_stay_portable(self):
        for path in (ROOT/'tool').glob('*.sh'):
            self.assertNotIn(b'\r\n', path.read_bytes(), str(path))
    def test_release_retains_non_test_entitlements(self):
        text = (ROOT/'tool/build_store_bundle.sh').read_text(encoding='utf-8')
        self.assertIn('--dart-define=UNLOCK_ALL_PREMIUM=false', text)
        self.assertIn('--dart-define=APP_CHECK_DEBUG_PROVIDER=false', text)
        self.assertIn('--dart-define=RELEASE_ENV=production', text)
if __name__ == '__main__': unittest.main()
