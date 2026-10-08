# Storage and mounting

The HP Z440 uses Samsung 950 PRO 256 GB NVMe for Ubuntu and a Western Digital 1 TB SATA disk for model files and WebUI data.

The original HDD was NTFS; the owner confirmed nothing on it needed preserving. It was reformatted to ext4, and the resulting partition was mounted at `/mnt/llm-data`.

**Do not format a disk just because this guide mentions /dev/sda2.** Run:

```bash
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS,UUID
sudo blkid
findmnt /
findmnt /mnt/llm-data
```

Confirm which drive is which by model and serial number, back up any needed data, and only then consider a format. The setup script does not perform formatting.

## Persistent mount by UUID

After formatting a *verified target* and creating the mountpoint:

```bash
sudo mkdir -p /mnt/llm-data
sudo blkid /dev/sda2  # EXAMPLE ONLY; verify actual disk
```

Add exactly one line to `/etc/fstab` with the actual ext4 filesystem UUID:

```fstab
UUID=<actual-uuid> /mnt/llm-data ext4 defaults,nofail 0 2
```

Verify with `sudo systemctl daemon-reload && sudo mount -a && findmnt /mnt/llm-data`.

## Directories

```text
/mnt/llm-data/
├── ollama/       # ollama service user owns this
├── open-webui/   # persistent application data (treat as private)
├── models/       # standalone GGUF
├── datasets/
├── projects/
└── backups/      # temporary/local copies; keep off-machine backups too
```

The sample setup script copies the existing Ollama model cache (when present), creates those paths, sets `OLLAMA_MODELS` with a systemd drop-in, and restarts Ollama. Always confirm:

```bash
systemctl show ollama -p Environment --no-pager
findmnt /mnt/llm-data
ollama list
du -sh /mnt/llm-data/ollama
```

A missing mount can lead to unexpectedly writing to the smaller boot NVMe. For robust boot ordering consider an Ollama systemd drop-in with `RequiresMountsFor=/mnt/llm-data`; verify the mount exists before any model download.

HDD storage is cost-effective but slower for cold loads than the NVMe. Data on the same HDD are *not* backups against drive failure.
