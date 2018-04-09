## Testing

To run all tests execute:

```shell
bundle install

bundle exec cookstyle && \
  bundle exec foodcritic --contex --epic-fail any . && \
  bundle exec kitchen test
```
