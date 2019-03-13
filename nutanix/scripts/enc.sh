#!/bin/bash
ansible-vault encrypt_string $1 --vault-password-file keys/vault.key
