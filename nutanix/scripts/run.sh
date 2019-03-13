#!/bin/bash
rm -rf /tmp/ansible.facts/ /tmp/ansible.log *.retry
if [ ${1: -4} == ".yml" ]
then
  PLAY=$1
else
  PLAY=$1.yml
fi
ansible-playbook -i localhost, $PLAY --vault-password-file keys/vault.key
