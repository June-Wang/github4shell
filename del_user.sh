#!/bin/bash

users=(
lp
shutdown
halt
news
uucp
games
operator
gopher
)

for user in "${users[@]}"
do
        grep "${user}" /etc/passwd >/dev/null 2>&1 && \
        userdel ${user}
done
