# nspawn-bootstrap

Bootstrap a systemd-nspawn container with either an Arch, Ubuntu, or Debian distro.

```sh
npm install -g nspawn-bootstrap
```

## Usage

```sh
nspawn-bootstrap ./ubuntu-16.04.img --ubuntu xenial --size 4GB
```

More options include

```
Usage: nspawn-bootstrap <container.img> [options]

  --size    <image-size>
  --ubuntu  <version>
  --debian  <version>
  --arch

Examples:

  nspawn-bootstrap --arch --size 4GB
  nspawn-bootstrap --ubuntu xenial --size 3GB
  nspawn-bootstrap --debian stable

```

## License

MIT
