"""Reject full releases whose account-backed features cannot be configured."""
import os
import re


def validate(environment):
    application = environment.get('SPOTIFLAC_DISCORD_APPLICATION_ID', '')
    if not re.fullmatch(r'[1-9][0-9]{5,24}', application):
        raise ValueError('Configure the project DISCORD_APPLICATION_ID repository variable')
    for name in ('LASTFM_API_KEY', 'LASTFM_API_SECRET'):
        if not environment.get(name):
            raise ValueError(f'Configure the project {name} repository secret')
    if environment.get('MOBILE_BUILD') == 'true' and not environment.get('DISCORD_MOBILE_SDK_PASSPHRASE'):
        raise ValueError('Stage the authorized Discord mobile SDK and configure DISCORD_MOBILE_SDK_PASSPHRASE')


if __name__ == '__main__':
    try:
        validate(os.environ)
    except ValueError as error:
        raise SystemExit(str(error))
    print('Full-release account configuration is present; live service access is not tested.')
