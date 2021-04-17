# AWS Docker Sandbox

Deploys Docker Engine in AWS.

## Files

* `docker-sandbox-template.yaml` - a stack template for a cloud sandbox.
* `docker-sandbox.sh` - a script to manage a cloud sandbox.

## Commands

Create a sandbox:

```bash
. ./docker-sandbox.sh create
```

Delete a sandbox:

```bash
. ./docker-sandbox.sh delete
```
