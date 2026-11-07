"""Live CLI command evidence. Reset freely; no GUI/picker integration."""
from xonsh.built_ins import XSH
from wes_command_usage import Recorder, default_path
from wes_command_usage.__main__ import main as _command_usage_main

XSH.env.register('XONSH_COMMAND_USAGE', type='bool', default=True)
XSH.env['XONSH_COMMAND_USAGE'] = XSH.env.get('XONSH_COMMAND_USAGE', True)
XSH.env.register('XONSH_COMMAND_USAGE_PYTHON_IO', type='bool', default=True)
XSH.env['XONSH_COMMAND_USAGE_PYTHON_IO'] = XSH.env.get('XONSH_COMMAND_USAGE_PYTHON_IO', True)
_command_usage_recorder = None

def _command_usage(args, stdin=None, stdout=None, stderr=None):
    global _command_usage_recorder
    if args and args[0] == 'reset':
        if _command_usage_recorder:
            _command_usage_recorder.close()
        _command_usage_main(['reset'])
        if XSH.env['XONSH_COMMAND_USAGE']:
            _command_usage_recorder = Recorder(default_path(), python_io=XSH.env['XONSH_COMMAND_USAGE_PYTHON_IO']).install()
        return 0
    if _command_usage_recorder:
        _command_usage_recorder.flush()
    return _command_usage_main(args)

aliases['command-usage'] = _command_usage
if XSH.env['XONSH_COMMAND_USAGE']:
    try:
        _command_usage_recorder = Recorder(default_path(), python_io=XSH.env['XONSH_COMMAND_USAGE_PYTHON_IO']).install()
    except Exception as error:
        print(f'command usage unavailable: {error}')
