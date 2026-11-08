#!/usr/bin/env python3
"""Generate release endpoints and optional account integration definitions."""
import argparse
import json
import os
from pathlib import Path
import re

def release_config(repository: str) -> dict[str, str]:
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9_.-]+', repository):
        raise ValueError('Distribution repository must be a GitHub owner/repository')
    if repository.split('/')[1] in ('.', '..'):
        raise ValueError('Invalid distribution repository name')
    return {
        'SPOTIFLAC_GITHUB_REPO': repository,
        'SPOTIFLAC_DESKTOP_GITHUB_REPO': repository,
        'SPOTIFLAC_CONFIG_URL': f'https://raw.githubusercontent.com/{repository}/main/config/app.json',
    }

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', default=os.environ.get('SPOTIFLAC_DISTRIBUTION_REPO', ''))
    parser.add_argument('--output', type=Path, default=Path('.release-defines.json'))
    args = parser.parse_args()
    try:
        config = release_config(args.repository)
    except ValueError as error:
        parser.error(str(error))
    lastfm_key = os.environ.get('LASTFM_API_KEY', '')
    lastfm_secret = os.environ.get('LASTFM_API_SECRET', '')
    if bool(lastfm_key) != bool(lastfm_secret):
        parser.error('Last.fm requires both LASTFM_API_KEY and LASTFM_API_SECRET')
    if lastfm_key:
        config.update(LASTFM_API_KEY=lastfm_key, LASTFM_API_SECRET=lastfm_secret)
    args.output.write_text(json.dumps(config, indent=2) + '\n', encoding='utf-8')
    print(f'Prepared public release endpoints for {args.repository}')

if __name__ == '__main__':
    main()
