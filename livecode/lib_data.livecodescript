script "LIB_DATA"
-- LIB_DATA: one default place on disk where every engine, tool and library loads and saves.
-- The Data folder is Documents/Data unless the user picks another one (Data.SetRoot),
-- which is remembered in <AppData>/Vibecode3D/data_root.txt. Inside it, files are sorted by
-- kind (Models, Games, Snapshots...), so nothing lands "wherever it got saved at 4 AM".
--
--   start using stack "<path>/LIB_DATA/livecode/lib_data.livecodescript"
--   put Data.Path("Models", "Vehicles_air/heli.glb") into tFile
--   put Data.SaveText("Reports", "fps.txt", tText, true) into tFile   -- dated name
--   answer file "Open a model" with Data.Folder("Models")
--
-- Kinds and their folders: Data.Kinds(). The layout and its rules: LIB_ig3d/DATA_FOLDER.md.
-- Names may contain "/" for subfolders but never "..": a name cannot leave the Data folder.
-- Handlers: Data.Root, Data.DefaultRoot, Data.SavedRoot, Data.ForwardedRoot, Data.SetRoot, Data.UseRoot,
-- Data.Ensure, Data.Kinds, Data.KindFolder, Data.Folder, Data.Path, Data.Relative,
-- Data.SaveText, Data.LoadText, Data.DatedName, Data.Error; test hook Data.TestFolders
--
-- Errors: a handler that cannot do its job returns empty (or false); Data.Error() says why.
--
-- Moving the Data folder (Data.SetRoot) also leaves a forwarding line in the default
-- Documents/Data/ROOT.md ("Moved to: <folder>"). When data_root.txt is lost (a cleaner wiped
-- AppData, a new Windows account, a reset PC), Data.Root follows that line and saves the
-- choice again; if the folder it names isn't there (a USB stick out), Documents/Data is used
-- and Data.Error() says so. Data.SetRoot(empty) takes the line away.

local sRoot        -- the root in use this session, once found and checked
local sSessionRoot -- set by Data.UseRoot: this session only, never saved
local sError       -- the last problem, for Data.Error
local sTestDocs, sTestSupport   -- test hook (Data.TestFolders): stand-ins for Documents, AppData

constant kAppFolder = "Vibecode3D"
constant kPointerFile = "data_root.txt"
constant kMoved = "Moved to: "   -- the forwarding line in the default ROOT.md

-------------------------------------------------------------------- the layout

-- one line per kind: kind,folder (relative to the root)
function Data.Kinds
   return "Games,Games" & return & \
         "Scripts,Scripts" & return & \
         "Tools,Tools" & return & \
         "Models,Models" & return & \
         "Grids,Grids" & return & \
         "Images,Images" & return & \
         "Sounds,Sounds" & return & \
         "Fonts,Fonts" & return & \
         "Emitters,Emitters" & return & \
         "Shaders,Shaders" & return & \
         "Procedures,Procedures" & return & \
         "Help,Help" & return & \
         "Users,Users" & return & \
         "Snapshots,Work/Snapshots" & return & \
         "Logs,Work/Logs" & return & \
         "Reports,Work/Reports" & return & \
         "Harvests,Work/Harvests" & return & \
         "Exports,Work/Exports" & return & \
         "Inbox,Work/Inbox"
end Data.Kinds

-- the folder of a kind, relative to the root ("Work/Snapshots"); empty if unknown
function Data.KindFolder pKind
   local tLine
   repeat for each line tLine in Data.Kinds()
      if item 1 of tLine is pKind then return item 2 of tLine
   end repeat
   return empty
end Data.KindFolder

-------------------------------------------------------------------- finding the root

-- Documents/Data
function Data.DefaultRoot
   if sTestDocs is not empty then return sTestDocs & "/Data"
   return specialFolderPath("Documents") & "/Data"
end Data.DefaultRoot

-- where the default Data folder's ROOT.md says the Data folder went, or empty
function Data.ForwardedRoot
   local tFile, tLine
   put Data.DefaultRoot() & "/ROOT.md" into tFile
   if there is not a file tFile then return empty
   repeat for each line tLine in textDecode(URL ("binfile:" & tFile), "UTF-8")
      replace numToChar(13) with empty in tLine
      if tLine begins with kMoved then return dataClean(char (the number of chars of kMoved + 1) to -1 of tLine)
   end repeat
   return empty
end Data.ForwardedRoot

-- the folder the user chose with Data.SetRoot, or empty
function Data.SavedRoot
   local tFile, tLine
   put dataPointerFile() into tFile
   if there is not a file tFile then return empty
   put line 1 of textDecode(URL ("binfile:" & tFile), "UTF-8") into tLine
   replace numToChar(13) with empty in tLine
   return dataClean(tLine)
end Data.SavedRoot

-- the Data folder in use: Data.UseRoot's, else the saved choice, else where Documents/Data's
-- ROOT.md says it moved (the choice is saved again), else Documents/Data.
-- Creates it, with its folders and ROOT.md, the first time.
function Data.Root
   local tRoot, tFwd
   if sRoot is not empty then return sRoot
   put sSessionRoot into tRoot
   if tRoot is empty then put Data.SavedRoot() into tRoot
   if tRoot is empty then
      put Data.ForwardedRoot() into tFwd
      if tFwd is not empty and there is a folder tFwd then
         -- the saved choice was lost: follow the forwarding line, and remember it again
         put tFwd into tRoot
         get dataSavePointer(tRoot)
      else if tFwd is not empty then
         put "the Data folder moved to " & tFwd & ", which isn't there now; using " & Data.DefaultRoot() into sError
      end if
   end if
   if tRoot is empty then put Data.DefaultRoot() into tRoot
   if not dataMakeFolder(tRoot) then return empty
   put tRoot into sRoot
   Data.Ensure
   return sRoot
end Data.Root

-- remember a new Data folder for every later session (empty: back to Documents/Data)
function Data.SetRoot pFolder
   local tFile
   put dataPointerFile() into tFile
   put empty into sRoot
   if pFolder is empty then
      if there is a file tFile then
         delete file tFile
      end if
      dataForward empty
   else
      put dataClean(pFolder) into pFolder
      if not dataMakeFolder(pFolder) then return empty
      if not dataSavePointer(pFolder) then return empty
      -- a second copy of the choice, where it survives a wiped AppData
      if pFolder is Data.DefaultRoot() then
         dataForward empty
      else
         dataForward pFolder
      end if
   end if
   return Data.Root()
end Data.SetRoot

-- use a folder for this session only, without saving the choice (tests, a USB stick);
-- empty goes back to the saved choice
command Data.UseRoot pFolder
   put dataClean(pFolder) into sSessionRoot
   put empty into sRoot
end Data.UseRoot

-- create every kind's folder and ROOT.md where missing
command Data.Ensure
   local tRoot, tLine, tText
   put sRoot into tRoot
   if tRoot is empty then put Data.Root() into tRoot
   if tRoot is empty then exit Data.Ensure
   repeat for each line tLine in Data.Kinds()
      get dataMakeFolder(tRoot & "/" & item 2 of tLine)
   end repeat
   if there is not a file (tRoot & "/ROOT.md") then
      put "# Data" & return & return & \
            "This is the Data folder: every Vibecode3D / xt3d tool loads and saves here." & return & \
            "Made by LIB_DATA. Keep the folder names exactly as they are." & return & return & \
            "| Kind | Folder |" & return & "|---|---|" & return into tText
      repeat for each line tLine in Data.Kinds()
         put "| " & item 1 of tLine & " | " & item 2 of tLine & "/ |" & return after tText
      end repeat
      put textEncode(tText, "UTF-8") into URL ("binfile:" & tRoot & "/ROOT.md")
   end if
end Data.Ensure

-------------------------------------------------------------------- paths

-- the full path of a kind's folder, or a subfolder of it; created if missing
--   Data.Folder("Models")  Data.Folder("Models", "Vehicles_air")
function Data.Folder pKind, pSub
   local tPath
   put dataKindPath(pKind) into tPath
   if tPath is empty then return empty
   if pSub is not empty then
      if not dataNameIsSafe(pSub) then return empty
      put "/" & dataClean(pSub) after tPath
   end if
   if not dataMakeFolder(tPath) then return empty
   return tPath
end Data.Folder

-- the full path of a file of that kind; its folder is created, the file is not
--   Data.Path("Models", "Vehicles_air/heli.glb")
function Data.Path pKind, pName
   local tPath, tFolder
   if pName is empty or not dataNameIsSafe(pName) then return empty
   put dataKindPath(pKind) into tPath
   if tPath is empty then return empty
   put tPath & "/" & dataClean(pName) into tPath
   set the itemDelimiter to "/"
   put item 1 to -2 of tPath into tFolder
   if not dataMakeFolder(tFolder) then return empty
   return tPath
end Data.Path

-- a path written relative to the root, for saving inside levels and docs
-- ("C:/Users/x/Documents/Data/Models/a.glb" -> "Models/a.glb"); other paths come back unchanged
function Data.Relative pPath
   local tRoot, tCut
   put dataClean(pPath) into pPath
   put Data.Root() into tRoot
   if tRoot is not empty and pPath begins with (tRoot & "/") then
      put the number of chars of tRoot + 1 into tCut
      delete char 1 to tCut of pPath
   end if
   return pPath
end Data.Relative

-------------------------------------------------------------------- reading and writing

-- write text (UTF-8) as a file of that kind and return its full path.
-- pDated true puts the date and time first: "2026-11-12_1430_fps.txt"
function Data.SaveText pKind, pName, pText, pDated
   local tPath
   if pDated is true then put Data.DatedName(pName) into pName
   put Data.Path(pKind, pName) into tPath
   if tPath is empty then return empty
   put textEncode(pText, "UTF-8") into URL ("binfile:" & tPath)
   if the result is not empty then
      put "could not write " & tPath & ": " & the result into sError
      return empty
   end if
   return tPath
end Data.SaveText

-- the text (UTF-8) of a file of that kind; empty if it is not there
function Data.LoadText pKind, pName
   local tPath
   if pName is empty or not dataNameIsSafe(pName) then return empty
   put dataKindPath(pKind) into tPath
   if tPath is empty then return empty
   put tPath & "/" & dataClean(pName) into tPath
   if there is not a file tPath then
      put "no file " & tPath into sError
      return empty
   end if
   return textDecode(URL ("binfile:" & tPath), "UTF-8")
end Data.LoadText

-- "fps.txt" -> "2026-11-12_1430_fps.txt" (now, or at pSeconds)
function Data.DatedName pName, pSeconds
   local tD
   if pSeconds is empty then put the seconds into pSeconds
   put pSeconds into tD
   convert tD to dateItems
   return item 1 of tD & "-" & dataTwo(item 2 of tD) & "-" & dataTwo(item 3 of tD) & "_" & \
         dataTwo(item 4 of tD) & dataTwo(item 5 of tD) & "_" & pName
end Data.DatedName

-- the last problem a handler met ("unknown kind: Modles", "unsafe name: ../x")
function Data.Error
   return sError
end Data.Error

-- test hook: stand-ins for the Documents and AppData folders (empty: the real ones again)
command Data.TestFolders pDocuments, pSupport
   put dataClean(pDocuments) into sTestDocs
   put dataClean(pSupport) into sTestSupport
   put empty into sRoot
end Data.TestFolders

-------------------------------------------------------------------- private

private function dataPointerFile
   if sTestSupport is not empty then return sTestSupport & "/" & kAppFolder & "/" & kPointerFile
   return specialFolderPath("support") & "/" & kAppFolder & "/" & kPointerFile
end dataPointerFile

-- write data_root.txt; false (and Data.Error) if it can't be
private function dataSavePointer pFolder
   local tFile, tDir
   put dataPointerFile() into tFile
   set the itemDelimiter to "/"
   put item 1 to -2 of tFile into tDir
   if not dataMakeFolder(tDir) then return false
   put textEncode(pFolder, "UTF-8") into URL ("binfile:" & tFile)
   return true
end dataSavePointer

-- the forwarding line in the default Data folder's ROOT.md: pFolder, or none when empty.
-- The rest of ROOT.md is kept; a default folder that doesn't exist yet is made for it.
private command dataForward pFolder
   local tDefault, tFile, tText, tLine, tOut
   put Data.DefaultRoot() into tDefault
   put tDefault & "/ROOT.md" into tFile
   if there is a file tFile then
      put textDecode(URL ("binfile:" & tFile), "UTF-8") into tText
   else if pFolder is empty then
      exit dataForward
   else
      if not dataMakeFolder(tDefault) then exit dataForward
      put "# Data" & return & return & "The default Data folder (LIB_DATA)." & return into tText
   end if
   replace numToChar(13) with empty in tText
   repeat for each line tLine in tText
      if tLine begins with kMoved or tLine begins with "The Data folder moved" then next repeat
      put tLine & return after tOut
   end repeat
   repeat while tOut ends with (return & return)
      delete the last char of tOut
   end repeat
   if pFolder is not empty then
      put return & "The Data folder moved (Data.SetRoot). Every tool follows the line below when its saved choice is lost:" & return & kMoved & pFolder & return after tOut
   end if
   put textEncode(tOut, "UTF-8") into URL ("binfile:" & tFile)
end dataForward

-- the full path of a kind's folder (not created); empty and a message if the kind is unknown
private function dataKindPath pKind
   local tRel, tRoot
   put Data.KindFolder(pKind) into tRel
   if tRel is empty then
      put "unknown kind: " & pKind into sError
      return empty
   end if
   put Data.Root() into tRoot
   if tRoot is empty then return empty
   return tRoot & "/" & tRel
end dataKindPath

-- forward slashes, no trailing slash
private function dataClean pPath
   replace "\" with "/" in pPath
   repeat while the last char of pPath is "/" and the number of chars of pPath > 1
      delete the last char of pPath
   end repeat
   return pPath
end dataClean

-- a name may hold subfolders but may not climb out or be absolute
private function dataNameIsSafe pName
   replace "\" with "/" in pName
   if pName contains ".." or pName begins with "/" or char 2 of pName is ":" then
      put "unsafe name: " & pName into sError
      return false
   end if
   return true
end dataNameIsSafe

-- create a folder and any missing parents; true if it exists afterwards
private function dataMakeFolder pPath
   local tSoFar, tPart, tCount, tIndex
   put dataClean(pPath) into pPath
   if there is a folder pPath then return true
   set the itemDelimiter to "/"
   put the number of items of pPath into tCount
   put 0 into tIndex
   repeat for each item tPart in pPath
      add 1 to tIndex
      if tIndex = 1 then
         put tPart into tSoFar
      else
         put "/" & tPart after tSoFar
      end if
      if tPart is empty or (tIndex = 1 and the last char of tPart is ":") then next repeat
      if there is not a folder tSoFar then create folder tSoFar
   end repeat
   if there is a folder pPath then return true
   put "could not create folder " & pPath into sError
   return false
end dataMakeFolder

private function dataTwo pNumber
   if pNumber < 10 then return "0" & pNumber
   return pNumber
end dataTwo
