# Docker Ansible Role (TLS Edition)

Installs the official Docker CE binaries explicitly natively on Debian 13 architectures perfectly configuring **Docker Daemon TLS Authentication** across all networked nodes.

## Features
- **Official Repositories**: Pulls identically perfectly from `download.docker.com`.
- **Systemd Overrides**: Flawlessly injects an `override.conf` systemd drop-in to aggressively strip the default `-H fd://` flags so `daemon.json` can natively enforce TCP.
- **TLS Authentication**: Authenticates clients over port `2376` using Vault-encrypted certificates natively injected sequentially into `/etc/docker/tls`.

---

## 🔑 Certificate Generation

To generate your own initial Docker TLS certificates, run the included generation script. It will automatically create the CA, Server, and Client certificates and output them perfectly formatted for Ansible:

```bash
bash generate_certs.sh
```

Once the script completes, simply copy the printed YAML block and paste it directly into `roles/docker/vars/main.yml` (or your preferred `host_vars` file) to replace the default certificates.

---

## 🔒 Security (Ansible-Vault)

Because you want these certificates synced across multiple Docker nodes gracefully, the raw generated `CA`, `Server`, and `Client` payloads should be stored in `roles/docker/vars/main.yml`.

They are currently **unencrypted** after generation, allowing you to visually inspect them!
Before committing this to version control, you must encrypt the file using Ansible Vault to prevent exposing your private keys.

1. **Set your Vault Password**: Create or update the `roles/docker/vault_pass.txt` file with your desired decryption password. *(Ensure this file is added to your `.gitignore`!)*
2. **Encrypt the File**: Run the `ansible-vault` command to securely encrypt your certificates using the password file:

```bash
ansible-vault encrypt roles/docker/vars/main.yml --vault-password-file roles/docker/vault_pass.txt
```

*(When executing your playbooks, Ansible will correctly decrypt the variables on the fly securely if you pass the `--vault-password-file` argument.)*

---

## Client (Laptop) Authentication
If you want to manage these Docker nodes securely from your actual laptop (over port 2376), I explicitly generated a client payload for you perfectly matched to the CA! Look securely inside `vars/main.yml` for the `docker_tls_client_cert` blocks.

Simply copy those to a `.docker` folder on your laptop natively and export `DOCKER_CERT_PATH=` and `DOCKER_TLS_VERIFY=1`!

---

## 🐳 Docker Compose Deployments (Host-Level Automation)

This role comes fully weaponized to deploy unlimited `docker-compose` applications entirely from the host-level variables! This completely abstracts away the need to manage dozens of custom `.j2` template files manually!

To orchestrate the deployment of containers sequentially to a specific machine, simply map them identically in your `host_vars/hostname.yml` like this:

```yaml
docker_apps:
  - name: "plex_media_server"
    dest_dir: "/opt/docker/plex"

    # Write the literal raw compose.yaml string completely inline!
    compose_content: |
      services:
        plex:
          image: lscr.io/linuxserver/plex:latest
          restart: unless-stopped
          ports:
            - 32400:32400

    # Want to map a secret .env file natively alongside it?
    env_content: |
      TZ=America/New_York
      PUID=1000

    # You can even inject massive custom configuration files on the fly!
    custom_files:
      - dest: "amdgpu.ids"
        mode: "0444"
        content: |
          // Raw bypass firmware strings ...
```

When Ansible executes the role, it will flawlessly create `/opt/docker/plex`, securely dump the `compose.yaml` and `.env` files straight to disk, dynamically check for state changes natively via `docker compose up -d`, and seamlessly build every single container requested identically!
