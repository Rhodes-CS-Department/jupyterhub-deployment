import argparse
import datetime
import logging
import requests
import sys
import time

from dateutil import parser


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
                return 0
            logging.info('OK')

    # Delete user.
    if not dry_run:
        logging.info('Deleteing uesr %s' % name)
        r = requests.delete(endpoint + f'/users/{name}',
                            headers={
                                'Authorization': f'token {token}',
                            })
        if r.status_code != 204:
            logging.error('Could not delete user %s with code %d' % (name,
                                                                     r.status_code))
            return 0
        logging.info('OK')
    return 1


def cull_users(endpoint, token, threshold=None, dry_run=True, cull_admin=False):
    since = None
    if threshold:
        since = datetime.datetime.now() - datetime.timedelta(weeks=threshold)
        logging.info('Culling users idle since %s' % since)

    users = get_users(endpoint, token)
    logging.info('Processing %d users...' % len(users))

    culled = 0
    cullable = 0

    for user in users:
        logging.debug(user)
        if user['admin'] and not cull_admin:
            logging.info('Skipping admin user %s' % user['name'])
            continue
        last_active = datetime.datetime.min
        if user['last_activity']:
            last_active = parser.parse(user['last_activity'])
        if since and last_active >= since.replace(tzinfo=last_active.tzinfo):
            logging.info('Skipping active user %s (%s)' % (user['name'],
                                                           last_active))
            continue
        cullable += 1
        culled += cull_user(user, endpoint, token, dry_run)

    logging.info('Done!')
    logging.info('Total users: %d Culled: %d Errors: %d\n', len(users),
                 culled, cullable-culled)


def main():
    parser = argparse.ArgumentParser(description='Cull user profiles')
    parser.add_argument('--no_dry_run', action='store_true',
                        help='Whether to actually perform update operations')
    parser.add_argument('--token', type=str,
                        default='',
                        help='API auth token')
    parser.add_argument('--token_file', type=str, default='.hub-token')
    parser.add_argument('--api', type=str,
                        default='https://rhodes-notebook.org/hub/api',
                        help='API endpoint')
    parser.add_argument('--age', type=int, default=10,
                        help='Age in weeks to cull (0 = all users)')
    parser.add_argument('--debug', action='store_true')
    args = vars(parser.parse_args())
    level = logging.INFO
    if args['debug']:
        level = logging.DEBUG
    logging.basicConfig(stream=sys.stdout, level=level,
                        format='[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s')
    logging.info(args)
    dry_run = not args['no_dry_run']
    logging.info('Dry run: %s' % dry_run)
    if not dry_run:
        print('WARNING: Not a dry run. Ctrl-C to quit if you do not want to delete users')
        time.sleep(5)

    token = args['token']
    if not token and args['token_file']:
        token = open(args['token_file']).readlines()[0].strip()

    cull_users(args['api'], token, threshold=args['age'], dry_run=dry_run)


if __name__ == '__main__':
    main()
