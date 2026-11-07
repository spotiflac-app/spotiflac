#!/usr/bin/env python3
"""Stage verified build assets and matching source in a downloads draft.

This command never publishes a release and never changes repository visibility.
Authentication stays in the environment or the local Git credential manager.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

def checksum(path):
    value = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(chunk)
    return value.hexdigest()

def parse_manifest(text, version):
    result = {}
    for line in text.splitlines():
        if not line.strip():
            continue
        match = re.fullmatch(r'([0-9a-fA-F]{64}) [ *](SpotiFLAC-[A-Za-z0-9_.+()-]+)', line)
        if not match:
            raise ValueError('Invalid release checksum manifest')
        digest, name = match.groups()
        if not name.startswith(f'SpotiFLAC-{version}-') or name.casefold() in {item.casefold() for item in result}:
            raise ValueError('Mixed version or duplicate release asset')
        result[name] = digest.lower()
    if not result:
        raise ValueError('Empty release checksum manifest')
    return result

def credentials(owner):
    token = os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_TOKEN')
    if token:
        return token
    result = subprocess.run(
        ['git', '-c', 'credential.interactive=never', 'credential', 'fill'],
        input=f'protocol=https\nhost=github.com\nusername={owner}\n\n',
        capture_output=True, text=True, check=True,
    )
    values = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
    return values['password']

class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, new_url):
        redirected = super().redirect_request(request, fp, code, message, headers, new_url)
        redirected.remove_header('Authorization')
        return redirected

class GitHub:
    def __init__(self, token):
        self.token = token
        self.opener = urllib.request.build_opener(SafeRedirect())

    def request(self, method, url, data=None, content_type='application/json'):
        if not url.startswith(('https://api.github.com/', 'https://uploads.github.com/')):
            raise ValueError('Unexpected GitHub API host')
        if isinstance(data, dict):
            data = json.dumps(data).encode()
        return urllib.request.Request(url, data=data, method=method, headers={
            'Authorization': f'Bearer {self.token}',
            'Accept': 'application/vnd.github+json',
            'Content-Type': content_type,
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'SpotiFLAC-release-publisher',
        })

    def api(self, method, path, data=None):
        if method == 'GET':
            path += ('&' if '?' in path else '?') + 'fresh=' + str(time.time_ns())
        with self.opener.open(self.request(method, 'https://api.github.com' + path, data), timeout=90) as response:
            body = response.read()
            return json.loads(body) if body else None

    def download(self, path, target, accept):
        path += ('&' if '?' in path else '?') + 'fresh=' + str(time.time_ns())
        request = self.request('GET', 'https://api.github.com' + path)
        request.headers['Accept'] = accept
        temporary = target.with_name(target.name + '.partial')
        with self.opener.open(request, timeout=180) as response, temporary.open('wb') as stream:
            for chunk in iter(lambda: response.read(1024 * 1024), b''):
                stream.write(chunk)
        temporary.replace(target)

    def upload(self, release, path):
        existing = next((asset for asset in release['assets'] if asset['name'] == path.name), None)
        digest = checksum(path)
        if existing:
            if existing.get('digest') != 'sha256:' + digest:
                raise ValueError(f'Refusing to replace a different existing asset: {path.name}')
            return
        url = release['upload_url'].split('{', 1)[0] + '?name=' + urllib.parse.quote(path.name)
        with path.open('rb') as payload:
            request = self.request('POST', url, payload, 'application/octet-stream')
            request.add_header('Content-Length', str(path.stat().st_size))
            with self.opener.open(request, timeout=300) as response:
                uploaded = json.load(response)
        if uploaded.get('digest') != 'sha256:' + digest:
            raise ValueError(f'Uploaded asset digest mismatch: {path.name}')

def resolve_source_commit(github, repository, source, tag):
    try:
        ref = github.api('GET', f'/repos/{repository}/git/ref/tags/{tag}')['object']
    except urllib.error.HTTPError as error:
        # GitHub may defer creating a draft release's tag until publication.
        # Only an immutable full commit SHA can stand in for that missing tag.
        if error.code != 404 or not source['draft'] or not re.fullmatch(r'[0-9a-f]{40}', source['target_commitish']):
            raise
        commit = github.api('GET', f'/repos/{repository}/git/commits/{source["target_commitish"]}')
        if commit['sha'] != source['target_commitish']:
            raise ValueError('Draft source commit mismatch')
        ref = {'type': 'commit', 'sha': commit['sha']}
    for _ in range(8):
        if ref['type'] == 'commit':
            break
        ref = github.api('GET', f'/repos/{repository}/git/tags/{ref["sha"]}')['object']
    if ref['type'] != 'commit':
        raise ValueError('Release tag did not resolve to a source commit')
    return ref["sha"]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', default='spotiflac-app/spotiflac')
    parser.add_argument('--downloads-repository', default='spotiflac-app/spotiflac-releases')
    parser.add_argument('--tag', required=True)
    parser.add_argument('--directory', type=Path, required=True)
    args = parser.parse_args()
    for repository in (args.repository, args.downloads_repository):
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+', repository):
            parser.error('Invalid GitHub repository')
    if args.repository.split('/')[0] != args.downloads_repository.split('/')[0] or args.repository == args.downloads_repository:
        parser.error('Source and downloads repositories must be separate and have the same owner')
    if not re.fullmatch(r'v\d+\.\d+\.\d+(?:[.-][A-Za-z0-9.-]+)?', args.tag):
        parser.error('Invalid version tag')
    github = GitHub(credentials(args.repository.split('/')[0]))
    source_repository = github.api('GET', f'/repos/{args.repository}')
    assert source_repository['owner']['login'].lower() == args.repository.split('/')[0].lower()
    destination = github.api('GET', f'/repos/{args.downloads_repository}')
    assert not destination['private'], 'Downloads metadata host must be public; draft assets remain restricted'
    assert destination['owner']['login'].lower() == args.repository.split('/')[0].lower()
    source = next(release for release in github.api('GET', f'/repos/{args.repository}/releases?per_page=100') if release['tag_name'] == args.tag)
    args.directory.mkdir(parents=True, exist_ok=True)
    assets = {asset['name']: asset for asset in source['assets']}
    manifest = args.directory / 'SHA256SUMS.txt'
    github.download(f'/repos/{args.repository}/releases/assets/{assets[manifest.name]["id"]}', manifest, 'application/octet-stream')
    expected = parse_manifest(manifest.read_text(encoding='utf-8'), args.tag)
    if {'apps.json', f'SpotiFLAC-{args.tag}-source.zip'} & set(expected):
        raise ValueError('Build manifest conflicts with reserved distribution metadata')
    if set(assets) != set(expected) | {'SHA256SUMS.txt'}:
        raise ValueError('Release assets do not exactly match their checksum manifest')
    for name, digest in expected.items():
        path = args.directory / name
        if not path.exists() or checksum(path) != digest:
            github.download(f'/repos/{args.repository}/releases/assets/{assets[name]["id"]}', path, 'application/octet-stream')
        if checksum(path) != digest:
            raise ValueError(f'Build checksum mismatch: {name}')
    source_commit = resolve_source_commit(github, args.repository, source, args.tag)
    source_zip = args.directory / f'SpotiFLAC-{args.tag}-source.zip'
    github.download(f'/repos/{args.repository}/zipball/{source_commit}', source_zip, 'application/vnd.github+json')
    with zipfile.ZipFile(source_zip) as archive:
        relative = {name.split('/', 1)[1] for name in archive.namelist() if '/' in name}
        if not {'LICENSE', 'COPYING', 'NOTICE'} <= relative:
            raise ValueError('Matching source archive is missing required license notices')
        if any(name.endswith(('.p12', '.pfx', '.jks', '.keystore', 'signing-secrets.json')) for name in relative):
            raise ValueError('Private signing material must not be distributed')
    expected[source_zip.name] = checksum(source_zip)
    manifest.write_text(''.join(f'{digest}  {name}\n' for name, digest in sorted(expected.items())), encoding='utf-8')
    ipa = next((args.directory / name for name in expected if name.endswith('.ipa')), None)
    if ipa is not None:
        from update_ios_feed import update
        feed = args.directory / 'apps.json'
        feed.write_text('{"apps": []}\n', encoding='utf-8')
        update(feed, ipa, args.tag, args.downloads_repository)
        feed_data = json.loads(feed.read_text(encoding='utf-8'))
        feed_data['apps'][0]['versionDate'] = source['created_at'].split('T')[0]
        feed.write_text(json.dumps(feed_data, indent=2) + '\n', encoding='utf-8')
        expected[feed.name] = checksum(feed)
        manifest.write_text(''.join(f'{digest}  {name}\n' for name, digest in sorted(expected.items())), encoding='utf-8')
    body = (source['body'] or '').replace(f'https://github.com/{args.repository}', f'https://github.com/{args.downloads_repository}')
    body += f'\n\nMatching source: `{source_zip.name}`\nSource commit: `{source_commit}`\n\nThis is a validation draft. Publishing is a separate explicit step.\n'
    draft = next((release for release in github.api('GET', f'/repos/{args.downloads_repository}/releases?per_page=100') if release['tag_name'] == args.tag), None)
    if draft:
        if not draft['draft']:
            raise ValueError('Published releases are immutable; use a new version')
        draft = github.api('PATCH', f'/repos/{args.downloads_repository}/releases/{draft["id"]}', {'body': body, 'draft': True})
    else:
        draft = github.api('POST', f'/repos/{args.downloads_repository}/releases', {'tag_name': args.tag, 'target_commitish': destination['default_branch'], 'name': f'SpotiFLAC {args.tag}', 'body': body, 'draft': True, 'prerelease': source['prerelease']})
    paths = [args.directory / name for name in sorted(expected)] + [manifest]
    def upload(path):
        # Separate HTTP clients avoid shared redirect-handler state.
        GitHub(github.token).upload(draft, path)
        print('Verified upload: ' + path.name, flush=True)
    with ThreadPoolExecutor(max_workers=6) as uploads:
        list(uploads.map(upload, paths))
    verified = github.api('GET', f'/repos/{args.downloads_repository}/releases/{draft["id"]}')
    assert verified['draft'] and {asset['name'] for asset in verified['assets']} == set(expected) | {'SHA256SUMS.txt'}
    assert github.api('GET', f'/repos/{args.repository}')['private'] == source_repository['private'], 'Repository visibility changed during staging'
    print(json.dumps({'draft_url': verified['html_url'], 'source_commit': source_commit, 'verified_assets': len(verified['assets']), 'published': False}))

if __name__ == '__main__':
    main()
