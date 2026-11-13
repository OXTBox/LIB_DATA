#!/usr/bin/env python3
"""Run LIB_DATA's tests inside real LiveCode 9.6.3, through LIB_MCP's standalone server.

    python3 tests/run_tests.py

Works in a throwaway Data folder, C:/LIB_MCP/data_test (deleted before and after), using
Data.UseRoot so the user's own Documents/Data is never touched. Data.SetRoot is tested only
when no choice is saved yet, and is reset afterwards. Needs ~/projects/LIB_MCP.
"""
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(os.path.dirname(HERE), 'livecode', 'lib_data.livecodescript')
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(HERE)), 'LIB_MCP', 'python'))
from lib_mcp.client import Client, local_to_win

ROOT = 'C:/LIB_MCP/data_test'
ROOT_WSL = '/mnt/c/LIB_MCP/data_test'
SET_WSL = '/mnt/c/LIB_MCP/data_test_set'
APPDIR_WSL = '/mnt/c/Users/%s/AppData/Roaming/Vibecode3D' % os.environ.get('WINUSER', 'Private')

# (code that ends by putting its answer, expected answer)
TESTS = [
    ('put Data.KindFolder("Snapshots")', 'Work/Snapshots'),
    ('put Data.KindFolder("Models")', 'Models'),
    ('put Data.KindFolder("Nope") is empty', 'true'),
    ('put the number of lines of Data.Kinds()', '19'),
    ('put Data.DefaultRoot() ends with "/Documents/Data"', 'true'),
    ('Data.UseRoot "%s/"\nput Data.Root()' % ROOT, ROOT),
    ('put there is a file (Data.Root() & "/ROOT.md")', 'true'),
    ('put there is a folder (Data.Root() & "/Work/Inbox")', 'true'),
    ('put Data.Folder("Models", "Vehicles_air")', ROOT + '/Models/Vehicles_air'),
    ('put Data.Path("Grids", "Sprites/ship.txt")', ROOT + '/Grids/Sprites/ship.txt'),
    ('put there is a folder "%s/Grids/Sprites"' % ROOT, 'true'),
    ('put Data.SaveText("Reports", "fps.txt", "30 fps" & return & "Canyon")', ROOT + '/Work/Reports/fps.txt'),
    ('put Data.LoadText("Reports", "fps.txt")', '30 fps\nCanyon'),
    ('put Data.LoadText("Reports", "missing.txt") is empty and Data.Error() begins with "no file"', 'true'),
    ('put Data.SaveText("Inbox", "caf\u00e9 \u2665.txt", "\u00e9\u2665") into t\nput t & return & Data.LoadText("Inbox", "caf\u00e9 \u2665.txt")',
     ROOT + '/Work/Inbox/caf\u00e9 \u2665.txt\n\u00e9\u2665'),
    ('put Data.Path("Models", "../../evil.txt") is empty and Data.Error() begins with "unsafe"', 'true'),
    ('put Data.Path("Models", "C:/evil.txt") is empty', 'true'),
    ('put Data.Folder("Modles") is empty and Data.Error() is "unknown kind: Modles"', 'true'),
    ('put Data.Relative("%s/Models/a.glb")' % ROOT, 'Models/a.glb'),
    ('put Data.Relative("%s\\Models\\a.glb")' % ROOT.replace('/', '\\'), 'Models/a.glb'),
    ('put Data.Relative("D:/elsewhere/a.glb")', 'D:/elsewhere/a.glb'),
    ('put "11/12/2026 2:30 PM" into t\nconvert t to seconds\nput Data.DatedName("fps.txt", t)', '2026-11-12_1430_fps.txt'),
    ('put "1/2/2027 9:05 AM" into t\nconvert t to seconds\nput Data.DatedName("a.png", t)', '2027-01-02_0905_a.png'),
    ('put Data.SaveText("Snapshots", "x.txt", "", true) contains "/Work/Snapshots/2"', 'true'),
]

SET_TESTS = [
    ('Data.UseRoot empty\nput Data.SetRoot("%s_set")' % ROOT, ROOT + '_set'),
    ('put Data.SavedRoot()', ROOT + '_set'),
    ('put there is a file "%s_set/ROOT.md"' % ROOT, 'true'),
    ('Data.UseRoot "%s"\nput Data.SetRoot(empty)' % ROOT, ROOT),   # session root wins, Documents/Data untouched
    ('put Data.SavedRoot() is empty', 'true'),
]


def check(c, tests):
    failed = 0
    for code, want in tests:
        ok, got = c.run(code, in_server=True)
        got = got.replace('\r', '').rstrip('\n')
        good = ok and got == want
        failed += not good
        label = code.replace('\n', ' / ')
        print('%s  %s' % ('PASS' if good else 'FAIL', label if good else '%s\n      want %r\n      got  %r' % (label, want, got)))
    return failed


def main():
    for d in (ROOT_WSL, SET_WSL):
        shutil.rmtree(d, ignore_errors=True)
    c = Client.standalone()
    lib = local_to_win(LIB).replace('\\', '/')
    ok, out = c.run('if there is a stack "LIB_DATA" then delete stack "LIB_DATA"\n'
                    'start using stack "%s"\nput "loaded"' % lib, in_server=True)
    if not ok or 'loaded' not in out:
        print('Could not load LIB_DATA:', out)
        return 2
    total = len(TESTS)
    failed = check(c, TESTS)
    ok, saved = c.run('Data.UseRoot empty\nput Data.SavedRoot()', in_server=True)
    if ok and saved.strip() == '':
        total += len(SET_TESTS)
        failed += check(c, SET_TESTS)
    else:
        print('SKIP  Data.SetRoot tests: a Data folder choice is already saved (%s)' % saved.strip())
    # leave the server's Documents/Data alone: forget the session root, nothing else
    c.run('Data.UseRoot empty\nstop using stack "%s"' % lib, in_server=True)
    for d in (ROOT_WSL, SET_WSL):
        shutil.rmtree(d, ignore_errors=True)
    # the SetRoot tests leave an empty <AppData>/Vibecode3D; remove it only if it is empty
    if ok and saved.strip() == '':
        try:
            os.rmdir(APPDIR_WSL)
        except OSError:
            pass
    print('\n%d of %d passed' % (total - failed, total))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
