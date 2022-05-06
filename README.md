# Local device health checks and diagnostics
Run health checks and diagnostics on a local heartbeat only device without
requiring VPN connectivity.

This can be run locally or pushed to a device running balenaOS that is located on the same network
with the device that is being debugged.

Running locally
===============

The API key passed to the container must have access to the device, and the
SSH keys from the user running the container needs to be added to the cloud
as the container will use the authentication credentials from the user running it.

To add the key follow these steps:

```
balena login -t <api token>
balena key add <name> <path>
```

For example:
```
balena key add testKey ~/.ssh/id_rsa.pub
```

Once finished, you can remove the key with:
```
balena key rm <id>
```
The key ID can be found with:
```
balena keys
```

To build and run the container:

```
docker-compose build
docker run -it --rm -v /tmp:/out --net host local-device-diags_device-check:latest -u <device UUID> -t <API token> -r https://registry2.balena-cloud.com -a https://api.balena-cloud.com
```

The reports will be available in the local `/tmp` directory named as:
```
device_[checks|diagnose]_$UUID_$DATETIME.log
```

Pushing to a fleet
==================

The following device variables must be defined for the test App:
    API_ENDPOINT: The Balena endpoint, usually `https://api.balena-cloud.com`
    REGISTRY_ENDPINT: The Balena registry endpoint, usually `https://registry2.balena-cloud.com`
    UUID: UUID of the device that is being debugged
    API_TOKEN: Balena API token with access to the fleet the device belongs to
