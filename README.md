# yaks farm

This branch is a [yaks](https://github.com/joelgwebber/yaks) farm: tasks, notes
and working knowledge kept as markdown files, one per thing, so they read on
the web as they do in the terminal.

| Where | What |
|---|---|
| `<herd>/yaks/<id>.md` | a yak (a task), its notes at the end; attachments in `<herd>/yaks/<id>/` |
| `doks/`, `<herd>/doks/` | doks: documents that outlive a yak (designs, research, how-tos) |
| `sessions/` | session notes: how a working session went |
| `sources/` | outside material, saved once and cited |
| `schemas/` | the shape of typed doks, and the known tags |
| `config.yaml`, `schema` | the farm's settings and schema version |

Links between these files are paths from the root of this branch
(`/doks/design/x.md`), which GitHub and most hosts follow.

To work with it, install yaks (`npm i -g @j15r/yaks`) and run `yaks tui` from a
checkout of the repository this branch belongs to.
