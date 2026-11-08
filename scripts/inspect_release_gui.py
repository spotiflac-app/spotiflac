#!/usr/bin/env python3
"""Inspect a release UI with an isolated, synthetic loopback provider fixture."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import math
import os
from pathlib import Path
import struct
import subprocess
import threading
import time
import wave

out = Path('/evidence'); out.mkdir(exist_ok=True)
profile = Path('/tmp/spotiflac-gui-profile')
data = profile / 'data'; cache = profile / 'cache'
support = data / 'com.spotiflac.app'
extension_id = 'spotiflac.qa.fixture'
source = support / 'extensions' / extension_id
private = support / 'extension_data' / extension_id
downloads = out / 'downloads'
for path in (source, private, cache, downloads): path.mkdir(parents=True, exist_ok=True)
with wave.open(str(out / 'tone.wav'), 'wb') as stream:
    stream.setnchannels(1); stream.setsampwidth(2); stream.setframerate(44100)
    stream.writeframes(b''.join(struct.pack('<h', int(900 * math.sin(2 * math.pi * 440 * n / 44100))) for n in range(88200)))
ffmpeg = '/usr/lib/spotiflac/lib/ffmpeg/ffmpeg'
subprocess.run([ffmpeg, '-v', 'error', '-y', '-i', str(out / 'tone.wav'), '-c:a', 'flac', str(out / 'tone.flac')], check=True)
audio = (out / 'tone.flac').read_bytes()
routes = []
track = {'id': 'synthetic-tone', 'name': 'SpotiFLAC QA Tone', 'artists': 'Synthetic Fixture', 'album_name': 'Local QA', 'duration_ms': 2000}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *unused): pass
    def do_GET(self):
        routes.append(self.path)
        if self.path == '/catalog': payload = json.dumps({'tracks': [track]}).encode(); content = 'application/json'
        elif self.path == '/tone.flac': payload = audio; content = 'audio/flac'
        else: self.send_error(404); return
        self.send_response(200); self.send_header('Content-Type', content)
        self.send_header('Content-Length', str(len(payload))); self.end_headers(); self.wfile.write(payload)


server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}'
manifest = {'name': extension_id, 'displayName': 'SpotiFLAC Isolated QA', 'version': '1.0.0',
            'description': 'Synthetic loopback-only release UI fixture',
            'type': ['metadata_provider', 'download_provider'],
            'permissions': {'network': ['127.0.0.1'], 'allowHttp': True, 'file': True},
            'searchBehavior': {'enabled': True}, 'skipMetadataEnrichment': True}
(source / 'manifest.json').write_text(json.dumps(manifest))
(source / 'index.js').write_text('''const base = BASE;
registerExtension({
 searchTracks(query) { const response = http.get(base + '/catalog'); if (!response.ok) throw new Error('catalog failed'); return JSON.parse(response.body); },
 checkAvailability() { return {available: true, track_id: 'synthetic-tone'}; },
 download(trackId, quality, outputPath) {
   const response = fetch(base + '/tone.flac');
   if (!response.ok) return {success:false,error_message:'fixture HTTP failed'};
   const result = file.writeBytes(outputPath,new Uint8Array(response.arrayBuffer()));
   if (!result.success) return {success:false,error_message:JSON.stringify(result)};
   return {success:true,file_path:outputPath,actual_extension:'.flac'};
 }
});
'''.replace('BASE', json.dumps(base)))
# Exercise the supported plaintext-settings migration using synthetic data.
(private / 'settings.json').write_text(json.dumps({'_enabled': True}))
settings = {'isFirstLaunch': False, 'hasCompletedTutorial': True,
            'downloadDirectory': str(downloads), 'storageMode': 'app',
            'searchProvider': extension_id, 'defaultService': extension_id,
            'allowLocalNetwork': True, 'enableLogging': True,
            'embedMetadata': False, 'embedLyrics': False, 'autoFallback': False,
            'checkForUpdates': False, 'language': 'en'}
(support / 'shared_preferences.json').write_text(json.dumps({'flutter.app_settings': json.dumps(settings)}))
env = {**os.environ, 'XDG_DATA_HOME': str(data), 'XDG_CACHE_HOME': str(cache),
       'GTK_MODULES': 'gail:atk-bridge', 'NO_AT_BRIDGE': '0'}
# Only an ephemeral hosted-runner keyring is initialized; no owner secrets exist.
subprocess.run(['gnome-keyring-daemon', '--unlock', '--components=secrets'], input=b'synthetic-qa-only', check=True, env=env)
subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface', 'toolkit-accessibility', 'true'], env=env, check=False)
subprocess.run(['dbus-send', '--session', '--dest=org.a11y.Bus', '/org/a11y/status',
                'org.freedesktop.DBus.Properties.Set', 'string:org.a11y.Status',
                'string:ScreenReaderEnabled', 'variant:boolean:true'], env=env, check=False)
process = None
try:
    with (out / 'startup.log').open('wb') as log:
        process = subprocess.Popen(['/usr/lib/spotiflac/spotiflac'], env=env, stdout=log, stderr=subprocess.STDOUT)
        time.sleep(25)
        assert process.poll() is None, 'Release exited during fixture startup'
        subprocess.run(['import', '-window', 'root', str(out / 'initial.png')], check=True)
        import pyatspi
        nodes = []
        objects = []
        def walk(item, path=(), depth=0):
            if depth > 30 or len(nodes) > 5000: return
            try:
                actions = []
                try:
                    action = item.queryAction()
                    actions = [action.getName(i) for i in range(action.nActions)]
                except Exception: pass
                nodes.append({'path': path, 'role': item.getRoleName(), 'name': item.name, 'actions': actions})
                objects.append(item)
                for index in range(item.childCount):
                    child = item.getChildAtIndex(index)
                    if child is not None: walk(child, path + (index,), depth + 1)
            except Exception: pass
        walk(pyatspi.Registry.getDesktop(0))
        (out / 'accessibility.json').write_text(json.dumps(nodes, indent=2))
        # This first phase records the real UI before input targets are chosen.
        (out / 'inspection.json').write_text(json.dumps({'startup': True, 'nodes': len(nodes), 'requests': routes, 'profile_files': [str(p.relative_to(profile)) for p in profile.rglob('shared_preferences.json')]}, indent=2))
        candidates = [item for node, item in zip(nodes, objects) if node['name'] == 'Search with SpotiFLAC Isolated QA...']
        assert len(candidates) == 1, 'Expected one fixture search field'
        action = candidates[0].queryAction()
        index = next(i for i in range(action.nActions) if action.getName(i) == 'Tap')
        assert action.doAction(index)
        time.sleep(1)
        subprocess.run(['xdotool', 'type', '--clearmodifiers', 'QA tone'], check=True)
        subprocess.run(['xdotool', 'key', 'Return'], check=True)
        for _ in range(30):
            if '/catalog' in routes: break
            time.sleep(0.5)
        time.sleep(2)
        nodes.clear(); objects.clear(); walk(pyatspi.Registry.getDesktop(0))
        (out / 'search-accessibility.json').write_text(json.dumps(nodes, indent=2))
        subprocess.run(['import', '-window', 'root', str(out / 'search.png')], check=True)
        (out / 'search.json').write_text(json.dumps({'catalog_requested': '/catalog' in routes, 'requests': routes}, indent=2))
        assert '/catalog' in routes, 'GUI search did not reach the synthetic provider'
finally:
    if process is not None and process.poll() is None:
        process.terminate(); process.wait(timeout=15)
    server.shutdown(); server.server_close()
    for path in (support / 'logs').glob('*.log'):
        (out / ('app-' + path.name)).write_bytes(path.read_bytes())
