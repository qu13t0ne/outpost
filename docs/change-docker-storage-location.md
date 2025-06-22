# Change Docker Storage Location

Consider changing the docker data storage location from the default (`/var/lib/docker`) to an alternate location such as on a secondary (non-OS) data drive.

To do this, edit `/etc/docker/daemon.json` to add a `data-root` reference to the alternate location.
If you look at the example [daemon.json](./daemon.json) file in this directory, I'm setting the storage location to `/srv/docker-<hostname>`.
Note that the literal path must be given.
Variable replacement, auto execution of commands like `$(hostname)` within the string, etc., do not work.

Easiest thing is to just replace the existing `daemon.json` file (if you haven't configured anything else, you may not even have one!) with a copy of the file in this directory.
The sample file includes some other handy configs like log handling.

```
sudo cp ./daemon.json /etc/docker/daemon.json
```

## Reference

- https://evodify.com/change-docker-storage-location/
