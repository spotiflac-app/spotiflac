#!/usr/bin/env python3
"""Reject release tags that disagree with the compiled product version."""
import argparse
import json
from pathlib import Path
import re


def validate(root, tag):
    specification = (root / 'pubspec.yaml').read_text(encoding='utf-8')
    match = re.search(r'^version:\s*(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)\+([1-9]\d*)\s*$', specification, re.MULTILINE)
    if not match:
        raise ValueError('pubspec.yaml must declare a product version and positive build number')
    version, build = match.groups()
    if tag.removeprefix('v') != version:
        raise ValueError(f'Release tag {tag} does not match product version {version}+{build}')
    constants = (root / 'lib/constants/app_info.dart').read_text(encoding='utf-8')
    displayed = re.search(r"static\s+const\s+String\s+version\s*=\s*['\"]([^'\"]+)['\"]", constants)
    if not displayed or displayed[1] != version:
        raise ValueError('AppInfo.version does not match pubspec.yaml')
    return {'tag': 'v' + version, 'version': version, 'build_number': int(build)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', required=True)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    try:
        print(json.dumps(validate(args.root, args.version)))
    except ValueError as error:
        parser.exit(1, str(error) + '\n')


if __name__ == '__main__':
    main()
