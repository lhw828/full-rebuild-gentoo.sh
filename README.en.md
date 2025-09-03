# Gentoo Full System Rebuild Script

This repository provides a **safe and resumable script** to completely rebuild a Gentoo Linux system.  
It automates syncing, updating, deep cleaning, and running `emerge -e @system` and `emerge -e @world`,  
with logging and checkpoints so you can recover if something goes wrong.

---

## Features

- 🔄 **End-to-end rebuild pipeline**:
  1. Sync Portage tree
  2. Update `@world`
  3. Depclean unused packages
  4. Run `revdep-rebuild`
  5. Clean distfiles and old binpkgs
  6. `emerge -e @system`
  7. `emerge -e @world`
  8. Final `revdep-rebuild`
  9. Summary & outdated package check

- 📜 **Comprehensive logging**:  
  All actions are logged to `/var/log/gentoo-rebuild/full-rebuild-<timestamp>.log`.

- ⏸ **Step checkpointing**:  
  If the script aborts, just fix the issue and **re-run** it — it will resume at the failed step.

- ⚙️ **Parallel build support**:  
  Automatically detects number of CPUs (`nproc`) and sets `--jobs` / `--load-average`.  
  You can override with environment variables, e.g.:
  ```bash
  JOBS=4 LOAD_AVG=4 bash full-rebuild-gentoo.sh

* 🛡 **Safety checks**:

  * Requires root
  * Backs up `/etc/portage/make.conf` and `world` file
  * Warns about disk usage before rebuilding

---

## Usage

### 1. Download the script

Save the script as:

```bash
full-rebuild-gentoo.sh
```

Make it executable:

```bash
chmod +x full-rebuild-gentoo.sh
```

### 2. Run inside `tmux` or `screen`

Because the rebuild can take hours:

```bash
tmux new -s rebuild
./full-rebuild-gentoo.sh
```

### 3. Monitor progress

* Logs: `/var/log/gentoo-rebuild/`
* Current step: `/var/tmp/full-rebuild.step`

### 4. Resume after failure

If the script fails:

1. Fix the problem (e.g. mask a broken package, update USE flags).
2. Simply re-run the script:

   ```bash
   ./full-rebuild-gentoo.sh
   ```

   It will continue from the failed step.

---

## Notes

* This script **does not rebuild the kernel**.
  If you want to rebuild your kernel and modules, do it separately after the world rebuild.

* You may want to enable binary package caching for faster rebuilds on repeated runs:

  ```bash
  EMERGE_DEFAULT_OPTS="--buildpkg" emerge -e @world
  ```

* For huge rebuilds (e.g. stage4 upgrade), ensure you have:

  * Enough free disk space (`df -h`)
  * Adequate cooling (compilation is CPU intensive)

---

## Example Output

```bash
===== STEP: 06-emerge-e-system =====
>>> Rebuilding system set from source
...
===== STEP: 07-emerge-e-world =====
>>> Rebuilding world set from source
...
### Done at 2025-09-04 04:30
Log: /var/log/gentoo-rebuild/full-rebuild-20250904-0430.log
```

---

## Risk statement
Use at your own risk. Contributions welcome!
