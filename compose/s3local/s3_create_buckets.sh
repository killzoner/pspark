#!/bin/bash

sleep 2;

BUCKET="pspark-release"
mc config host add myminio http://minio:9000 12345678 12345678;
mc rm -r --force myminio/$BUCKET;
mc mb myminio/$BUCKET;
mc policy set public myminio/$BUCKET
