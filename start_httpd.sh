#!/bin/bash
PORT=8080
echo "Server now running on port $PORT"
busybox httpd -v -f -c httpd.conf -p $PORT
