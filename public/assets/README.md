# public assets

NOTE - do not edit this directory

If you change any of the assets - you must:

```bash
$ docker-compose up -d
$ make compose.app.assets
```

This will update the contents of this folder - commit the built artifacts (ideally in a different commit to the source).