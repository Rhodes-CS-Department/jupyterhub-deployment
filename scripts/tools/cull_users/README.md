# User culling tool

Prerequisites:
* Python 3
* `pipenv`

## Removing users

Use `pipenv` to install dependencies in sandbox:
```
$ pipenv shell
$ pipenv sync
```

Run the script:
```
python3 cull_users.py [flags]
```

Flags:
* `--no_dry_run` - actually cull users; defaults to false to dry run by default
  and only logs intended actions.
* `--token` - API auth token (you can get a token from your server once you log
  in by going to "token" in the menu bar.
* `--token_file` - path to a filename containing only the token. `.hub_token` is
  ignored by git.
* `--api` - API endpoint (Rhodes server by defalt).
* `--age` - idle period (in weeks) of users to cull (default is 10). 0 will cull
  all users. Admin users are never culled.
