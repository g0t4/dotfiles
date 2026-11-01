"""Exercise real TLS handshakes and OpenSSL decoding without public network access."""
import io
import socket
import ssl
import subprocess
import threading
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone

import pytest
import test_setup  # noqa: F401
from wes_certificates import inspect, main


@pytest.fixture(scope='module')
def certificates(tmp_path_factory):
    root = tmp_path_factory.mktemp('tls')

    def run(*args):
        subprocess.run(['openssl', *args], check=True, capture_output=True)

    run('req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '10',
        '-keyout', str(root / 'ca.key'), '-out', str(root / 'ca.crt'),
        '-subj', '/CN=Test CA', '-addext', 'basicConstraints=critical,CA:TRUE',
        '-addext', 'keyUsage=critical,keyCertSign,cRLSign')
    (root / 'index').touch()
    (root / 'serial').write_text('1000\n')
    (root / 'ca.cnf').write_text(f'''[ca]
default_ca = test
[test]
database = {root}/index
serial = {root}/serial
new_certs_dir = {root}
certificate = {root}/ca.crt
private_key = {root}/ca.key
default_md = sha256
policy = names
unique_subject = no
[names]
commonName = supplied
''')
    (root / 'ext').write_text('subjectAltName=DNS:localhost\nbasicConstraints=CA:FALSE\nextendedKeyUsage=serverAuth\n')
    now = datetime.now(timezone.utc)
    for name, start, end in [('valid', -1, 5), ('expired', -5, -1), ('future', 1, 5)]:
        run('req', '-new', '-newkey', 'rsa:2048', '-nodes',
            '-keyout', str(root / f'{name}.key'), '-out', str(root / f'{name}.csr'),
            '-subj', '/CN=localhost')
        run('ca', '-batch', '-notext', '-config', str(root / 'ca.cnf'),
            '-in', str(root / f'{name}.csr'), '-out', str(root / f'{name}.crt'),
            '-extfile', str(root / 'ext'),
            '-startdate', (now + timedelta(days=start)).strftime('%Y%m%d%H%M%SZ'),
            '-enddate', (now + timedelta(days=end)).strftime('%Y%m%d%H%M%SZ'))
    return root


@contextmanager
def server(root, name):
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(root / f'{name}.crt', root / f'{name}.key')
    listener = socket.socket()
    listener.bind(('127.0.0.1', 0))
    listener.listen()
    listener.settimeout(0.1)
    stop = threading.Event()

    def serve():
        while not stop.is_set():
            try:
                conn, _ = listener.accept()
            except socket.timeout:
                continue
            with conn:
                conn.settimeout(2)
                try:
                    with ctx.wrap_socket(conn, server_side=True):
                        pass
                except ssl.SSLError:
                    pass  # Expected when the client rejects the certificate.

    worker = threading.Thread(target=serve)
    worker.start()
    try:
        yield listener.getsockname()[1]
    finally:
        stop.set()
        worker.join(timeout=4)
        listener.close()
        assert not worker.is_alive()


@pytest.mark.parametrize('name,host,trusted,expected,status', [
    ('valid', 'localhost', True, 'Validation  \x1b[32mOK', 0),
    ('expired', 'localhost', True, 'EXPIRED', 1),
    ('future', 'localhost', True, 'NOT YET VALID', 1),
    ('valid', 'wrong.example', True, 'MISMATCH', 1),
    ('valid', 'localhost', False, 'Validation', 1),
])
def test_real_tls(certificates, name, host, trusted, expected, status):
    output = io.StringIO()
    with server(certificates, name) as port:
        result = inspect(host, port, connect='127.0.0.1',
                         ca_file=str(certificates / 'ca.crt') if trusted else None,
                         stdout=output)
    text = output.getvalue()
    assert result == status
    assert expected in text
    assert '\x1b[' in text  # Forced even though StringIO is not a TTY.
    assert 'SHA-256' in text and 'DNS:localhost' in text
    if trusted:
        assert f'PEM file: {certificates / "ca.crt"}' in text
    else:
        assert 'PEM file:' not in text
        assert '\x1b[1;31m' in text
    if name in ('expired', 'future'):
        assert '\x1b[1;31m' in text
    if name == 'valid':
        assert '\x1b[1;33m' in text  # Five days remaining.


def test_connection_failure():
    with socket.socket() as reserved:
        reserved.bind(('127.0.0.1', 0))  # Bound but not listening.
        output = io.StringIO()
        assert inspect('127.0.0.1', reserved.getsockname()[1], stdout=output) == 1
    assert '\x1b[1;31m' in output.getvalue()
    assert 'Error' in output.getvalue()


@pytest.mark.parametrize('args', [['https://example.com'], ['localhost:99999'],
                                  ['localhost', '--timeout', '0'],
                                  ['localhost', '--warn-days', '-1']])
def test_invalid_arguments(args):
    with pytest.raises(SystemExit) as exc:
        main(args)
    assert exc.value.code == 2


def test_cli_color_ignores_environment(certificates):
    import os
    from pathlib import Path
    import sys
    import wes_certificates

    with server(certificates, 'expired') as port:
        result = subprocess.run([
            sys.executable, str(Path(wes_certificates.__file__)), f'localhost:{port}',
            '--connect', '127.0.0.1', '--ca-file', str(certificates / 'ca.crt'),
        ], capture_output=True, text=True,
            env={**os.environ, 'NO_COLOR': '1', 'TERM': 'dumb', 'CLICOLOR': '0'})
    assert result.returncode == 1
    assert 'EXPIRED' in result.stdout and '\x1b[1;31m' in result.stdout
    assert not result.stderr


def test_native_trust_context_does_not_patch_ssl():
    import sys
    import truststore
    from wes_certificates import _verification_context

    original = ssl.SSLContext
    context, source = _verification_context(None)
    assert isinstance(context, truststore.SSLContext)
    assert context.verify_mode == ssl.CERT_REQUIRED
    assert context.check_hostname
    assert ssl.SSLContext is original
    if sys.platform == 'darwin':
        assert source == 'macOS Keychain'


def test_explicit_bundle_bypasses_native_trust(certificates, monkeypatch):
    import wes_certificates

    def unexpected(*args, **kwargs):
        pytest.fail('Explicit bundle must not use native trust')

    monkeypatch.setattr(wes_certificates.truststore, 'SSLContext', unexpected)
    output = io.StringIO()
    with server(certificates, 'valid') as port:
        assert inspect('localhost', port, connect='127.0.0.1',
                       ca_file=str(certificates / 'ca.crt'), stdout=output) == 0
    assert 'PEM file:' in output.getvalue()


@pytest.mark.parametrize('seconds,expected', [
    (0, 'less than 1 minute'),
    (59, 'less than 1 minute'),
    (60, '1 minute'),
    (1800, '30 minutes'),
    (3600, '1 hour'),
    (3660, '1 hour 1 minute'),
    (9000, '2 hours 30 minutes'),
    (86399, '23 hours 59 minutes'),
    (86400, '1.0 days'),
    (129600, '1.5 days'),
    (-1800, '30 minutes'),
    (-9000, '2 hours 30 minutes'),
])
def test_duration(seconds, expected):
    from wes_certificates import _duration
    assert _duration(seconds) == expected
