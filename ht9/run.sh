#!/bin/bash

. .env

/usr/local/bin/docker-compose -f docker-compose.yml up -d --force-recreate