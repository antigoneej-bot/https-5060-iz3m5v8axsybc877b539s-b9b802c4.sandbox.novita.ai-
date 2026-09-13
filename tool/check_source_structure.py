"""Dependency-free structural checks only; NOT a Dart/Kotlin compiler or analyzer."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def check_delimiters(path):
    text = path.read_text()
    size = len(text)
    def error(message, index):
        raise ValueError(f'{path.relative_to(ROOT)}:{text.count(chr(10), 0, index)+1}: {message}')
    def string(i, raw=False):
        quote = text[i]
        marker = quote * 3 if text.startswith(quote * 3, i) else quote
        i += len(marker)
        while i < size:
            if text.startswith(marker, i): return i + len(marker)
            if not raw and text[i] == '\\': i += 2; continue
            if not raw and text.startswith('${', i): i = code(i+2, '}'); continue
            i += 1
        error('unclosed string', i)
    def code(i, end=None):
        pairs = {'(':')', '[':']', '{':'}'}
        while i < size:
            c = text[i]
            if c == end: return i + 1
            if text.startswith('//', i):
                j = text.find('\n', i); i = size if j < 0 else j+1; continue
            if text.startswith('/*', i):
                depth = 1; i += 2
                while i < size and depth:
                    if text.startswith('/*', i): depth += 1; i += 2
                    elif text.startswith('*/', i): depth -= 1; i += 2
                    else: i += 1
                if depth: error('unclosed comment', i)
                continue
            if c in "\"'":
                raw = i > 0 and text[i-1] == 'r' and (i < 2 or not text[i-2].isalnum())
                i = string(i, raw); continue
            if c in pairs: i = code(i+1, pairs[c]); continue
            if c in ')]}': error('unexpected delimiter '+c, i)
            i += 1
        if end: error('unclosed delimiter, expected '+end, i)
        return i
    code(0)

checked = 0
for folder in ['lib', 'test', 'tool', 'android/app/src/main/kotlin']:
    for path in (ROOT/folder).rglob('*'):
        if path.suffix not in {'.dart', '.kt'}: continue
        check_delimiters(path); checked += 1
        if path.suffix != '.dart': continue
        for ref in re.findall(r"(?:import|export|part)\s+['\"]([^'\"]+)['\"]", path.read_text()):
            if ref.startswith('package:flutter_app/'):
                target = ROOT/'lib'/ref.split('package:flutter_app/')[1]
            elif ':' not in ref: target = path.parent/ref
            else: continue
            if not target.exists(): raise ValueError(f'Missing import: {path}: {ref}')
for path in (ROOT/'android/app/src').rglob('*.xml'): ET.parse(path)
for name in re.findall(r'^    - (assets/[^\n]+)', (ROOT/'pubspec.yaml').read_text(), re.M):
    if not (ROOT/name).exists(): raise ValueError(f'Missing asset path: {name}')
print(f'Structural checks passed for {checked} Dart/Kotlin files, local imports, Android XML and asset paths.')
print('These checks do not compile code, resolve packages, run Flutter tests, or exercise a device.')
