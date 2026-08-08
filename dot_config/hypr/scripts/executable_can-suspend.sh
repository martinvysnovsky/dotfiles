#!/bin/sh
# Gate for hypridle's suspend listener.
# exit 0 = allow suspend, non-zero = stay awake.
# Defers suspend while an SSH session is connected.
ss -tn state established '( sport = :ssh )' | grep -q . && exit 1
exit 0
