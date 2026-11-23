#!/usr/bin/env bash
# Add efi_pstore.pstore_disable=0 to the Limine kernel cmdline (dots-d532).
#
# Why: hardlockup_panic=1 is now live, so the next hard hang should panic
# instead of wedging silently, and panic=20 reboots the box. But nothing
# currently persists the panic text across that reboot -- the console is owned
# by plymouth then the greeter, so nobody is looking at it. EFI-variable pstore
# is the capture path: CONFIG_EFI_VARS_PSTORE=y in this kernel but
# CONFIG_EFI_VARS_PSTORE_DEFAULT_DISABLE=y, so it needs the explicit flag.
#
# Deliberately adds ONLY this flag. It is pure observability and changes no
# behaviour, so it does not disturb the pcie_aspm=off experiment already in
# flight.
#
# Run with sudo. Idempotent.
set -euo pipefail

CONF=/etc/default/limine
FLAG='efi_pstore.pstore_disable=0'

[[ $EUID -eq 0 ]] || { echo "error: run with sudo" >&2; exit 1; }
[[ -f $CONF ]] || { echo "error: $CONF not found" >&2; exit 1; }

if grep -q "$FLAG" "$CONF"; then
  echo "already present in $CONF; nothing to do"
  exit 0
fi

backup="${CONF}.bak.$(date +%Y%m%d-%H%M%S)"
cp -a "$CONF" "$backup"
echo "backed up -> $backup"

# Append the flag inside the existing KERNEL_CMDLINE[default] quoted string.
sed -i -E 's/^(KERNEL_CMDLINE\[default\]\+?=".*)"$/\1 '"$FLAG"'"/' "$CONF"

if ! grep -q "$FLAG" "$CONF"; then
  echo "error: edit did not apply; restoring" >&2
  cp -a "$backup" "$CONF"
  exit 1
fi

echo
echo "--- diff ---"
diff -u "$backup" "$CONF" || true
echo
echo "Regenerating Limine entries..."
limine-update
echo
echo "Done. Next steps:"
echo "  limine-list                 # eyeball the entries before rebooting"
echo "  # after the reboot:"
echo "  cat /proc/cmdline           # confirm the flag took"
echo "  journalctl -k | grep -i pstore   # want: 'Registered efi as persistent store backend'"
echo "  ls /sys/fs/pstore/          # where a captured panic will land"
