#!/home/alon/venv/bin/python3

import sys

from aocd.get import current_day
from aocd import submit

submit(sys.argv[1])
if current_day() == 25:
  submit(0, part="b", day=25)
