#!/bin/sh
sleep $((`date -d '00:00 EST tomorrow' +%s` - `date +%s` + 1)) && aocd
