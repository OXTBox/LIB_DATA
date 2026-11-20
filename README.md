# LIB_DATA

One default place on disk where every engine, tool and library loads and saves: the
**Data folder**. Files are sorted by kind (models, games, snapshots, logs...), so nothing
lands "wherever it got saved at 4 AM", and paths written into levels and docs stay valid on
any machine.

```
start using stack "<path>/LIB_DATA/livecode/lib_data.livecodescript"
put Data.Path("Models", "Vehicles_air/heli.glb") into tFile     -- full path, folder made
put Data.SaveText("Reports", "fps.txt", tText, true) into tFile  -- Work/Reports/2026-11-12_1430_fps.txt
answer file "Open a model" with Data.Folder("Models")            -- dialogs start in the right place
put Data.Relative(tFile) into tStored                           -- "Models/Vehicles_air/heli.glb"
```

## Where the Data folder is

1. `Data.UseRoot` (this session only: tests, a USB stick), else
2. the user's choice saved by `Data.SetRoot`, kept in `<AppData>/Vibecode3D/data_root.txt`
   (outside the Data folder, so moving the folder keeps the setting), else
3. where `Documents/Data/ROOT.md` says the Data folder moved (`Moved to: <folder>`), when
   that folder is there; the choice is then saved again, else
4. **`Documents/Data`**, the default.

The first use creates the folder, every kind's subfolder and a `ROOT.md` that explains it.
`Data.SetRoot(folder)` also writes the forwarding line into the default `Documents/Data/ROOT.md`
(making that folder if needed), so a wiped AppData, a reset PC or a new account still finds
the Data folder. If the folder it names is missing (a USB stick out), `Documents/Data` is used,
the line is kept, and `Data.Error()` says why. `Data.SetRoot(empty)` goes back to the default
and takes the line away.

## Kinds

| Kind | Folder | | Kind | Folder |
|---|---|---|---|---|
| Games | `Games/` | | Procedures | `Procedures/` |
| Scripts | `Scripts/` | | Help | `Help/` |
| Tools | `Tools/` | | Users | `Users/` |
| Models | `Models/` | | Snapshots | `Work/Snapshots/` |
| Grids | `Grids/` | | Logs | `Work/Logs/` |
| Images | `Images/` | | Reports | `Work/Reports/` |
| Sounds | `Sounds/` | | Harvests | `Work/Harvests/` |
| Fonts | `Fonts/` | | Exports | `Work/Exports/` |
| Emitters | `Emitters/` | | Inbox | `Work/Inbox/` |
| Shaders | `Shaders/` | | Menus | `Menus/<game or app>/` |

What you make and keep goes at the top; what the machine makes goes in `Work/`, which is
safe to empty. `Inbox` is the default for "Save as..." when nothing else fits. The layout
and its rules (taken from iGame3D's 2008 `Data/` folder) are in `~/projects/LIB_ig3d/DATA_FOLDER.md`.

| Handler | Does |
|---|---|
| `Data.Root()` | the Data folder in use (created with its layout the first time) |
| `Data.DefaultRoot()`, `Data.SavedRoot()` | `Documents/Data`; the saved choice or empty |
| `Data.SetRoot(folder)` | remember a new Data folder for later sessions; empty = default |
| `Data.UseRoot folder` | this session only, not saved |
| `Data.Ensure` | create missing folders and `ROOT.md` |
| `Data.Kinds()`, `Data.KindFolder(kind)` | `kind,folder` lines; one kind's folder |
| `Data.Folder(kind [, sub])` | full path of a kind's folder or subfolder, created |
| `Data.MenuFolder(app [, true])` | `Menus/<game or app>/` (menu item lists), or its `Functions/` (callbacks) with true; created |
| `Data.Path(kind, name)` | full path of a file; its folder is created, the file is not |
| `Data.Relative(path)` | a full path written relative to the root |
| `Data.SaveText(kind, name, text [, dated])` | write UTF-8 text, return the path |
| `Data.LoadText(kind, name)` | read UTF-8 text |
| `Data.DatedName(name [, seconds])` | `2026-11-12_1430_name` |
| `Data.Error()` | why the last handler returned empty |

Names may hold subfolders (`"Vehicles_air/heli.glb"`) but never `..` or a drive: a name
cannot leave the Data folder.

## Tests

`python3 tests/run_tests.py`: 29 checks in real LiveCode 9.6.3 through LIB_MCP, in a
throwaway folder (`C:/LIB_MCP/data_test`); the user's own `Documents/Data` is never created
or touched. All pass.

`OXT-BEYOND/tests/t50_data_menus.txt`: the Menus kind and `Data.MenuFolder`, headless, 13 checks, all pass on OXT-Beyond and 9.6.3.

`OXT-BEYOND/tests/t32_data_forwarding.txt`: the forwarding line, headless (no window), on the
OXT-Beyond engine and the 9.6.3 server, with `Data.TestFolders` standing in for Documents and
AppData. 19 checks, all pass on both.

## Next

- Use it in the engines: Vibecode3D's reports (now `Documents/Vibecode3D/REPORT_*.txt`), the
  xt3d bench's model folder, LIB_MCP's snapshots and logs (now `C:\LIB_MCP`), XTJSON harvests.
- A "Change Data folder..." menu item in each engine that calls `Data.SetRoot`.
- `data_layout.json` so Python tools (xtalk_py, Spark runners) follow the same layout.

Part of the family of separate libraries listed in `~/projects/LIB_MCP/README.md`.

## Licence

GPL-3.0 (see `LICENSE`), because the xTalk work here is built on the GPL-licensed LiveCode Community 9 engine. Copyright (c) 2026 xAction.

The Python files (`.py`) and other material that is not xTalk are also offered under the MIT licence, Copyright (c) 2026 xAction: you may use them under either licence.
