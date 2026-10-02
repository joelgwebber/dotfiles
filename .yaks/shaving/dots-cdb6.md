---
id: dots-cdb6
title: Every time I change the wallpaper, I get a sudo dialog
type: bug
priority: 3
created: '2026-09-27T18:24:42Z'
updated: '2026-10-02T03:52:33Z'
labels:
- greeter
- linux
- auth
verify: test -f /etc/polkit-1/rules.d/49-noctalia-greeter-sync.rules
---

"Authorization is required to sync appearance to the login greeter"

---
▸ 2026-10-02T03:52:24Z [Joel Webber]
Root cause found, and it is upstream's deliberate default rather than a
misconfiguration here.

The dialog is polkit, for action `org.noctalia.greeter.sync-appearance`, defined
in /usr/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy
(noctalia-greeter 1.5.0-1). Its defaults:

    allow_any      auth_admin
    allow_inactive auth_admin
    allow_active   auth_admin

`auth_admin`, not even `auth_admin_keep` -- so there is no 5-minute grace
period and *every* invocation prompts. Confirmed in the journal:

    Sep 30 22:13:13 pkexec[1791]: joel: Executing command [USER=root]
      [COMMAND=/usr/bin/noctalia-greeter-apply-appearance --sync
       /run/user/1000/noctalia-greeter-sync]
    Oct 01 23:02:46 pkexec[1036030]: (same)

What fires it: the noctalia shell setting **shell.greeter_sync.auto**
("Auto-Sync Greeter", Settings -> Greeter), whose own description reads
*"Automatically sync the greeter whenever wallpaper, colors, theme mode, or
shell font change. Authorization still follows system policy; this setting does
not enable passwordless sync."* So upstream expects a local polkit rule if you
want it quiet -- that sentence is the sanctioned escape hatch, not a warning
against it.

Why root is needed at all: the sync target is /var/lib/noctalia-greeter, mode
0750 greeter:greeter per /usr/lib/tmpfiles.d/noctalia-greeter.conf. joel cannot
write it, hence the helper.

Three ways out, in order of preference:

1. **Polkit rule** (recommended, keeps auto-sync working):
   ![49-noctalia-greeter-sync.rules](artifacts/dots-cdb6/49-noctalia-greeter-sync.rules)

       sudo install -m 0644 \
         .yaks/artifacts/dots-cdb6/49-noctalia-greeter-sync.rules \
         /etc/polkit-1/rules.d/49-noctalia-greeter-sync.rules

   No restart needed; polkitd picks up rules.d changes on its own. joel is in
   `wheel` (verified via `id`), and /usr/share/polkit-1/rules.d/50-default.rules
   already declares `unix-group:wheel` as the admin identity, so the group
   choice is consistent with the rest of the system. Numbered 49 to sort ahead
   of 50-default.rules. Do **not** edit the vendor .policy -- package-owned,
   overwritten on upgrade.

2. Turn **Auto-Sync Greeter off** and use the "Sync Now" button when you
   actually want the login screen to match. Prompts once, when you asked for it.

3. `shell.greeter_sync.privilege_command` can override the escalation command,
   but for constrained sync it still appends `--sync` and still goes through the
   same action -- no help.

Security note on option 1: the action's annotations pin it to executing
/usr/bin/noctalia-greeter-apply-appearance with `--sync` as argv[1], but the
path argument is caller-supplied, so a passwordless grant means code running as
joel could have root read an arbitrary path and copy it into
/var/lib/noctalia-greeter. joel already has unrestricted sudo, so this is not a
real escalation -- it is just the reason the rule is scoped to one action id and
gated on `subject.active && subject.local`.

Related but distinct: [[dots-2998]] is the other recurring auth prompt, and it
is a PAM/keyring problem, not polkit. [[dots-3d5e]] is the third
noctalia-greeter annoyance (journal flooding).
