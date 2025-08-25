Keycloak
========

To understand the contents of your Keycloak installation, see the [directory structure guide](https://www.keycloak.org/server/directory-structure).

To get help configuring Keycloak via the CLI, run:

on Linux/Unix:

    $ bin/kc.sh

on Windows:

    $ bin\kc.bat

To try Keycloak out in development mode, run: 

on Linux/Unix:

    $ bin/kc.sh start-dev

on Windows:

    $ bin\kc.bat start-dev

After the server boots, open http://localhost:8080 in your web browser. The welcome page will indicate that the server is running.

To get started, check out the [configuration guides](https://www.keycloak.org/guides#server).

## Import a realm

1. Put your "realm-export.json" in some path (e.g.: ./exports/realm-export.json).
2. Execute:
```bash
bin/kc.sh import --file ./exports/realm-export.json
```
This will load the realm in the storage of dev-file (`data/`).

Then simply run again:
```bash
bin/kc.sh start-dev
```
and you will have the realm already imported.

## Import a client

The client's JSON exported is not a realm, therefore `kc.sh import` will not accept it directly.

You have two options:

### Option A - Include it in the realm export
Edit the `realm-export.json` and add your client under the section `"clients"`. Then import it as mentioned above.

### Option B - Use *kcadm.sh*
With `start-dev` the admin is created on the fly.

If for instance you don't have an admin user configured, you can set one by doing:
```bash
bin/kc.sh bootstrap-admin user --username admin 
```
You will be requested for the admin password, it has to be compliant with the realm policies.

Example (if your admin is `admin`/`admin`):
```bash
bin/kcadm.sh config credentials \
    --server http://localhost:8080 \
    --realm master \
    --user admin \
    --password <KC_ADMIN_PWD>

bin/kcadm.sh create clients -r Optimal -f ./exports/frontend.json
```
If the client exists with the same `clientId` and you want to update it:
```bash
CID=$(bin/kcadm.sh get clients -r Optimal -q clientId=frontend | jq -r '.[0].id')
bin/kcadm.sh update clients/$CID -r Optimal -f ./exports/frontend.json
```