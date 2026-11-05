#!/usr/bin/env python3
"""Exercise a shipped desktop backend with isolated synthetic provider data.

No installed app settings or music accounts are used. HTTP is bound to loopback
and permitted only inside this test process. This does not replace real provider,
GUI, physical-device, signing or version-upgrade validation.
"""
import argparse
import base64
import ctypes
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import math
import os
from pathlib import Path
import platform
import struct
import subprocess
import sys
import threading
import uuid
import wave


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


class NativeBackend:
    def __init__(self, library, config):
        self.directory = os.add_dll_directory(str(library.parent)) if os.name == 'nt' else None
        self.dll = ctypes.CDLL(str(library))
        self.condition = threading.Condition()
        self.responses = {}
        self.sequence = 0
        callback_type = ctypes.CFUNCTYPE(None, ctypes.c_uint64, ctypes.c_int32, ctypes.c_void_p, ctypes.c_size_t)
        self.dll.spotiflac_free.argtypes = [ctypes.c_void_p, ctypes.c_size_t]
        self.dll.spotiflac_free.restype = None

        def receive(call_id, kind, pointer, length):
            payload = ctypes.string_at(pointer, length) if pointer and length else b''
            self.dll.spotiflac_free(pointer, length)
            if call_id and kind in (0, 1, 2):
                with self.condition:
                    self.responses[call_id] = (kind, payload)
                    self.condition.notify_all()

        self.callback = callback_type(receive)
        self.dll.spotiflac_init.argtypes = [callback_type, ctypes.c_char_p, ctypes.c_size_t]
        self.dll.spotiflac_init.restype = None
        self.dll.spotiflac_call.argtypes = [ctypes.c_uint64, ctypes.c_char_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_size_t]
        self.dll.spotiflac_call.restype = None
        raw = json.dumps(config).encode()
        self.dll.spotiflac_init(self.callback, raw, len(raw))

    def call(self, method, arguments=None):
        self.sequence += 1
        call_id = self.sequence
        raw = json.dumps(arguments).encode()
        self.dll.spotiflac_call(call_id, method.encode(), raw, len(raw), None, 0)
        with self.condition:
            if not self.condition.wait_for(lambda: call_id in self.responses, timeout=45):
                raise TimeoutError(method)
            kind, payload = self.responses.pop(call_id)
        value = json.loads(payload) if payload else None
        if kind != 0:
            raise RuntimeError(f'{method}: {value}')
        # Several native bridge methods intentionally return JSON inside a string.
        if isinstance(value, str):
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                pass
        return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--library', type=Path, required=True)
    parser.add_argument('--ffmpeg', type=Path, required=True)
    parser.add_argument('--ffprobe', type=Path, required=True)
    parser.add_argument('--report-dir', type=Path, required=True)
    args = parser.parse_args()
    if sys.flags.optimize:
        parser.error('Run this verification without Python optimization so checks remain enabled')
    for path in (args.library, args.ffmpeg, args.ffprobe):
        if not path.is_file():
            parser.error(f'Missing test binary: {path}')
    args.report_dir.mkdir(parents=True, exist_ok=True)
    root = args.report_dir.resolve() / ('provider-' + uuid.uuid4().hex)
    root.mkdir()
    source = root / 'extensions' / 'spotiflac.qa.fixture'
    output = root / 'downloads'
    for directory in (source, output, root / 'data', root / 'support', root / 'temp'):
        directory.mkdir(parents=True, exist_ok=True)
    tone = root / 'tone.wav'
    with wave.open(str(tone), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(44100)
        stream.writeframes(b''.join(struct.pack('<h', int(900 * math.sin(2 * math.pi * 440 * n / 44100))) for n in range(88200)))
    flags = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    subprocess.run([str(args.ffmpeg.resolve()), '-v', 'error', '-i', str(tone), '-c:a', 'flac', str(root / 'tone.flac')], check=True, timeout=30, creationflags=flags)
    audio = (root / 'tone.flac').read_bytes()
    routes = []
    track = {'id': 'synthetic-tone', 'name': 'SpotiFLAC QA Tone', 'artists': 'Synthetic Fixture', 'album_name': 'Local QA', 'duration_ms': 2000}

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *unused):
            pass

        def do_GET(self):
            routes.append(self.path)
            if self.path == '/catalog':
                payload, content_type = json.dumps({'tracks': [track]}).encode(), 'application/json'
            elif self.path == '/tone.flac':
                payload, content_type = audio, 'audio/flac'
            else:
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    server.daemon_threads = True
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    url = f'http://127.0.0.1:{server.server_port}'
    manifest = {'name': 'spotiflac.qa.fixture', 'displayName': 'SpotiFLAC Isolated QA', 'version': '1.0.0', 'description': 'Synthetic loopback-only test fixture', 'type': ['metadata_provider', 'download_provider'], 'permissions': {'network': ['127.0.0.1'], 'allowHttp': True, 'file': True}, 'searchBehavior': {'enabled': True}, 'skipMetadataEnrichment': True}
    (source / 'manifest.json').write_text(json.dumps(manifest), encoding='utf-8')
    javascript = '''const base = BASE;
registerExtension({
    searchTracks(query) { const response = http.get(base + '/catalog'); if (!response.ok) throw new Error('catalog failed'); return JSON.parse(response.body); },
    checkAvailability() { return {available: true, track_id: 'synthetic-tone'}; },
    download(trackId, quality, outputPath) {
        const response = fetch(base + '/tone.flac');
        if (!response.ok) return {success: false, error_message: 'fixture HTTP failed'};
        const result = file.writeBytes(outputPath, new Uint8Array(response.arrayBuffer()));
        if (!result.success) return {success: false, error_message: JSON.stringify(result)};
        return {success: true, file_path: outputPath, actual_extension: '.flac'};
    }
});
'''.replace('BASE', json.dumps(url))
    (source / 'index.js').write_text(javascript, encoding='utf-8')
    backend = NativeBackend(args.library.resolve(), {'app_support_dir': str(root / 'support'), 'documents_dir': str(output), 'temp_dir': str(root / 'temp'), 'ffmpeg_path': str(args.ffmpeg.resolve()), 'ffprobe_path': str(args.ffprobe.resolve()), 'app_version': '1.0.0'})
    try:
        backend.call('setAllowPrivateNetwork', {'allowed': True})
        backend.call('initExtensionSystem', {'extensions_dir': str(source.parent), 'data_dir': str(root / 'data'), 'master_key': base64.b64encode(os.urandom(32)).decode(), 'allowed_directories': [str(output)]})
        backend.call('loadExtensionsFromDir', {'dir_path': str(source.parent)})
        backend.call('setExtensionEnabled', {'extension_id': manifest['name'], 'enabled': True})
        results = backend.call('searchTracksWithMetadataProvider', {'extension_id': manifest['name'], 'query': 'QA tone', 'limit': 5})
        assert isinstance(results, list) and len(results) == 1, results
        assert results[0]['id'] == track['id'] and results[0]['provider_id'] == manifest['name'], results
        request = {'service': manifest['name'], 'provider_track_id': track['id'], 'use_extensions': True, 'use_fallback': False, 'output_dir': str(output), 'track_name': track['name'], 'artist_name': track['artists'], 'album_name': track['album_name'], 'filename_format': '{title}', 'output_ext': '.flac', 'quality': 'LOSSLESS', 'embed_metadata': False, 'embed_lyrics': False}
        result = backend.call('downloadByStrategy', json.dumps(request))
        assert result.get('success') is True, result
        downloaded = Path(result['file_path']).resolve()
        assert downloaded.is_relative_to(output) and downloaded.read_bytes() == audio
        probe = subprocess.run([str(args.ffprobe.resolve()), '-v', 'error', '-show_entries', 'stream=codec_name,sample_rate:format=duration', '-of', 'json', str(downloaded)], capture_output=True, text=True, check=True, timeout=30, creationflags=flags)
        media = json.loads(probe.stdout)
        assert media['streams'][0]['codec_name'] == 'flac' and abs(float(media['format']['duration']) - 2) < 0.02, media
        subprocess.run([str(args.ffmpeg.resolve()), '-v', 'error', '-xerror', '-i', str(downloaded), '-f', 'null', '-'], capture_output=True, check=True, timeout=30, creationflags=flags)
        blocked = root / 'ungranted-output'
        blocked.mkdir()
        denied_request = {**request, 'output_dir': str(blocked)}
        try:
            denied = backend.call('downloadByStrategy', json.dumps(denied_request))
            assert not denied.get('success'), denied
            denial = json.dumps(denied).lower()
        except RuntimeError as error:
            denial = str(error).lower()
        assert any(word in denial for word in ('directory', 'allowed', 'permission', 'outside', 'granted')), denial
        assert not list(blocked.iterdir()), 'Download escaped the granted output directory'
        assert routes == ['/catalog', '/tone.flac'], routes
        report = {'passed': True, 'platform': platform.system(), 'machine': platform.machine(), 'backend_sha256': digest(args.library), 'search_provider': True, 'http_audio_download': True, 'download_bytes_match': True, 'flac_decode_probe': True, 'full_audio_decode': True, 'duration_seconds': 2, 'ungranted_output_rejected': True, 'requests': routes, 'limitations': 'Synthetic isolated provider through the shipped native ABI; not a commercial provider, GUI download, physical-device or version-upgrade test.'}
        (root / 'result.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        print(json.dumps({'report': str(root / 'result.json'), **report}), flush=True)
    finally:
        try:
            backend.call('cleanupExtensions')
            backend.call('setAllowPrivateNetwork', {'allowed': False})
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=5)


if __name__ == '__main__':
    main()
