#!/bin/sh
exec java -XX:TieredStopAtLevel=1 -jar /var/task/app.jar
