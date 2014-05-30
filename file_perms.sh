#!/bin/bash
cd $(dirname "$0")

chmod 755 htdocs/
chmod 755 cgi-bin/
chmod 755 cgi-bin/*
chmod 777 htdocs/Results
chmod 777 htdocs/Uploads
