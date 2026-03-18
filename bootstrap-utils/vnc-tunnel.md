# vnc-tunnel.sh

Creates an SSH tunnel to the `angie` host for VNC access. Useful for accessing VM consoles during OS installation.

## Usage

```bash
./vnc-tunnel.sh <port>
```

## Example

```bash
./vnc-tunnel.sh 5900
```

## Arguments

| Argument | Description |
|----------|-------------|
| `<port>` | The VNC port number to tunnel (e.g. 5900, 5901, 5902) |

## What it does

Opens an SSH tunnel forwarding `localhost:<port>` to `localhost:<port>` on `angie`. Once the tunnel is open, connect your VNC client to `localhost:<port>`.

## Notes

- Press `Ctrl+C` to close the tunnel when done
- Each VM typically uses a different port (5900, 5901, etc.)
