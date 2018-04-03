## Testing

To run all tests execute:

```shell
bundle install

bundle exec cookstyle && \
  bundle exec foodcritic --contex --epic-fail any --tags '~FC113' . && \
  bundle exec kitchen test
```
