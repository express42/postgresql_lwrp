#!/bin/sh

curl -o bundle.tgz https://s3.amazonaws.com/$AWS_BUCKET/postgresql-cookbook/bundle.tgz
tar -xf bundle.tgz

bundle install --path .bundle --quiet --without kitchen_vagrant development

exit 0
