# Homelab MCP with Codex

Homelab MCP uses Authentik OAuth. Tailscale provides remote network access;
Codex signs in separately through your browser. Authentication was introduced
by the September 21, 2026 homelab configuration change, not by a reboot.

## Connect from a laptop

1. Connect Tailscale when away from home. The subnet router must advertise
   and have approval for `192.168.0.0/24`, and the laptop must accept that route.
   Tailnet access rules must allow your laptop to reach the homelab services.
2. Configure Tailscale split DNS for `home.arpa` using the restricted nameserver
   `192.168.0.152`. The laptop must accept Tailscale DNS settings.
   `mcp-server.home.arpa` should resolve to `192.168.0.100`.
3. Trust the Homelab Root CA in the laptop's system certificate store. The
   public CA certificate is in the private `homelab-iac` repository at
   `infrastructure/ansible/files/homelab-ca.crt`. Use that trusted copy;
   do not disable TLS verification. Import it into the browser too if the
   browser uses a separate certificate store.
4. Ensure the browser can reach `https://auth.merl.one` for Authentik login.

The dotfiles already configure this endpoint in `~/.codex/config.toml`:

```toml
[mcp_servers."homelab-mcp"]
url = "https://mcp-server.home.arpa/mcp/"
```

If setting up Codex without applying these dotfiles, add it once:

```sh
codex mcp add homelab-mcp --url https://mcp-server.home.arpa/mcp/
```

On each machine, run:

```sh
codex mcp login homelab-mcp
```

Open the displayed URL in a browser **on the same machine**, sign in to
Authentik with an account in `homelab-admins`, and approve access. Wait for
`Successfully logged in to MCP server 'homelab-mcp'` in the terminal.
The callback uses the laptop's loopback address; no inbound Tailscale port
or homelab callback change is needed when Codex runs locally on the laptop.

Start a fresh Codex session (restart the app or extension if applicable).
In the CLI, use `/mcp` to check that `homelab-mcp` is connected and lists tools.
OAuth credentials stay local to each machine; do not put tokens, authorization
URLs, or the server's OIDC client secret in dotfiles.

## Understand a 401 after login

This checks DNS, routing, TLS, and whether authentication is enforced:

```sh
curl -I https://mcp-server.home.arpa/mcp/
```

**HTTP 401 is expected, even after a successful Codex login.** Curl does not
read Codex's saved OAuth token. Opening `/mcp/` directly in a browser also
does not test Codex's authenticated MCP connection. Use a fresh Codex
session and `/mcp` to verify that connection.

| Symptom | Check |
| --- | --- |
| Host cannot be resolved | Tailscale DNS and the `home.arpa` restricted nameserver |
| Connection times out | Tailscale connection, accepted subnet route, and access rules |
| Certificate verification fails | Homelab Root CA trust on this machine |
| Plain curl returns 401 | Expected: curl supplied no bearer token |
| Authentik denies access | Account membership in `homelab-admins` |
| Codex still requires login | Restart Codex; confirm login used the same OS user, `CODEX_HOME`, server name, and exact URL |

If a fresh Codex session still fails, run `codex mcp login homelab-mcp`
on that machine and retry. Report the actual Codex error rather than the
unauthenticated curl response. Do not paste saved tokens into a bug report.

## Verification performed

On September 23, 2026, checks from the homelab workstation confirmed:

- An unauthenticated MCP initialization request returned **401**.
- The same initialization through the public HTTPS endpoint using the saved
  Codex OAuth token returned **200** (`homelab-context-server`, version `1.26.0`).
- Authenticated `tools/list` returned **200** with **12 tools**.
- A fresh `codex app-server` process reported `homelab-mcp` with auth status
  `oAuth` and **12 tools** through `mcpServerStatus/list`.

These checks verify authentication and Codex tool discovery, not every tool's
operation. The remote laptop's Tailscale connectivity must be checked there.

## References

- [Codex MCP configuration and OAuth](https://developers.openai.com/codex/extend/mcp)
- [Tailscale DNS configuration](https://tailscale.com/docs/reference/dns-in-tailscale)
- Private `homelab-iac` runbooks: `docs/operations/tailscale-remote-access.md`
  and `docs/operations/certificate-management.md`
