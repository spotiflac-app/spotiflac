#!/usr/bin/env python3
"""Exercise an installed release on a disposable Xvfb display."""
import json
from pathlib import Path
import platform
import subprocess
import time

out = Path('/evidence')
out.mkdir(exist_ok=True)
report = {'architecture': platform.machine(), 'passed': False,
          'limits': 'Virtual display startup only; no hardware audio or commercial-provider GUI coverage.'}
process = None
try:
    with (out / 'startup.log').open('wb') as log:
        process = subprocess.Popen(['/usr/lib/spotiflac/spotiflac'], stdout=log, stderr=subprocess.STDOUT)
        time.sleep(20)
        report['startup_exit_code'] = process.poll()
        assert process.poll() is None, 'App exited during startup'
        windows = subprocess.check_output(['xwininfo', '-root', '-tree'], text=True)
        (out / 'windows.txt').write_text(windows)
        assert 'SpotiFLAC' in windows, 'No rendered SpotiFLAC window'
        subprocess.run(['import', '-window', 'root', str(out / 'display.png')], check=True)
        report['native_startup_20_seconds'] = True
        report['window_present'] = True
        process.terminate()
        process.wait(timeout=15)
        report['passed'] = True
finally:
    if process is not None and process.poll() is None:
        process.kill()
        process.wait(timeout=10)
    (out / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report))
