import argparse
import logging
import requests
import sys


def get_users(endpoint, token):
    r = requests.get(endpoint + '/users',
                     headers={
                         'Authorization': f'token {token}',
                     })
    r.raise_for_status()
    users = r.json()
    return users


def cull_user(user, endpoint, token, dry_run=True):
    name = user['name']
    logging.info('Removing user %s' % name)

    # Shut down any active server.
    if user['server']:
        logging.info('Shutting down active server %s' % user['server'])
        if not dry_run:
            r = requests.delete(endpoint + f'/users/{name}/server',
                                headers={
                                    'Authorization': f'token {token}',
                                })
            if r.status_code != 204:
                logging.error(
                    'Could not delete server for user %s with code %d' % (name,
                                                                          r.status_code))
                return
            logging.info('OK')

    # Delete user.
    if not dry_run:
        r = requests.delete(endpoint + f'/users/{name}',
                            headers={
                                'Authorization': f'token {token}',
                            })
        if r.status_code != 204:
            logging.error('Could not delete user %s with code %d' % (name,
                                                                     r.status_code))
            return
        logging.info('OK')


def cull_users(endpoint, token, dry_run=True, cull_admin=False):
    users = get_users(endpoint, token)
    logging.info('Processing %d users...' % len(users))
    for user in users:
        if user['admin'] and not cull_admin:
            logging.info('Skipping admin user %s' % user['name'])
            continue
        cull_user(user, endpoint, token, dry_run)
    logging.info('Done!')


def main():
    parser = argparse.ArgumentParser(description='Cull user profiles')
    parser.add_argument('--dry_run', type=bool, default=True,
                        help='Whether to actually perform update operations')
    parser.add_argument('--token', type=str,
                        default='a85506cc6ec04ff588e306c5fd740557',
                        help='API auth token')
    parser.add_argument('--api', type=str,
                        default='https://rhodes-notebook.org/hub/api',
                        help='API endpoint')
    args = vars(parser.parse_args())
    logging.basicConfig(stream=sys.stdout, level=logging.INFO,
                        format='[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s')
    cull_users(args['api'], args['token'], args['dry_run'])


if __name__ == '__main__':
    main()
