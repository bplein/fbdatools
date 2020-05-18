#!/usr/bin/env bash
/usr/sbin/sshd -D -p $SSH_PORT

#exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"