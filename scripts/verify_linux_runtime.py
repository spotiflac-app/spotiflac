#!/usr/bin/env python3
"""Reject bundled ELF files outside the supported Linux glibc baseline."""
import argparse
import json
from pathlib import Path
import re
import subprocess


def audit(bundle, maximum):
    records = []
    for path in sorted(bundle.rglob('*')):
        if path.is_symlink() or not path.is_file():
            continue
        with path.open('rb') as stream:
            if stream.read(4) != b'\x7fELF':
                continue
        info = subprocess.run(['readelf', '--version-info', str(path)],
                              check=True, capture_output=True, text=True).stdout
        versions = [tuple(map(int, v.split('.'))) for v in
                    re.findall(r'Name: GLIBC_(\d+(?:\.\d+)+)', info)]
        floor = max(versions, default=(0,))
        errors = []
        if 'GLIBC_PRIVATE' in info:
            errors.append('references GLIBC_PRIVATE; rebuild without static glibc components')
        if floor > maximum:
            errors.append('requires glibc newer than the supported baseline')
        records.append({'file': str(path.relative_to(bundle)),
                        'maximum_glibc': '.'.join(map(str, floor)), 'errors': errors})
    if not records:
        raise ValueError('No ELF files found in bundle')
    return records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    parser.add_argument('--max-glibc', default='2.35')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    records = audit(args.bundle, tuple(map(int, args.max_glibc.split('.'))))
    report = json.dumps(records, indent=2) + '\n'
    if args.report:
        args.report.write_text(report)
    failures = [r for r in records if r['errors']]
    for record in failures:
        print(f"{record['file']}: {'; '.join(record['errors'])} (GLIBC {record['maximum_glibc']})")
    print(f'Checked {len(records)} ELF files; {len(failures)} incompatible files.')
    return bool(failures)


if __name__ == '__main__':
    raise SystemExit(main())
