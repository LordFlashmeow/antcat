#!/usr/bin/env bash
cd ../database_export
docker run -d --rm --name web -p 9090:80 -v $PWD:/usr/local/apache2/htdocs/ httpd:2.4