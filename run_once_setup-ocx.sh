#!/bin/bash

ocx init --global
ocx registry add https://registry.kdco.dev --name kdco --global 2>/dev/null || true
ocx add kdco/worktree --global 2>/dev/null || true
