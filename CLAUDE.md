# LIB_DATA: notes for Claude Code

Read `README.md`. The layout and its rules live in `~/projects/LIB_ig3d/DATA_FOLDER.md`;
keep `Data.Kinds()`, the README table and that file in step.

- Compile-check: `~/projects/LIB_MCP/tools/lcmcp compile livecode/lib_data.livecodescript`
- Test in real LiveCode: `python3 tests/run_tests.py`. Tests must use `Data.UseRoot` with a
  throwaway folder: never create or write the owner's real `Documents/Data` from a test.
- Errors go in `sError` (read with `Data.Error()`), not `return ... for error`.
- A one-line `if` directly before `else` takes that else: use block ifs there.
- In a test, each `put` replaces the previous output: build one answer and put it once.
