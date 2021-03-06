{{PropBOE MicroSD.spin

IMPORTANT: This is not the final version, just an interim version
for the 2011.08.12 Propeller Educators Course.  Check at the
Propeller Board of Education site for updates.

Convenience methods for MicroSD data storage and retrieval through
SD-MMC_FATEngine.spin.

See end of file for author, version, copyright and terms of use.

  Example Program with sd Nickname
 ┌───────────────────────────────────────────┐
 │ OBJ                                       │
 │   system : "Propeller Board of Education" │
 │   sd     : "PropBOE MicroSD"              │
 │                                           │
 │ PUB Go                                    │
 │   system.Clock(80_000_000)                │
 │   sd.Mount(0)                             │
 │   sd.FileNew(String("Test.txt"))          │
 │   sd.FileOpen(String("Test.txt"), "W")    │
 │   sd.WriteStr(String("Hello sd card!"))   │
 │   sd.FileClose                            │
 │   sd.UnMount                              │
 │                                           │
 └───────────────────────────────────────────┘

For improved performance and a smaller program, use SD-MMC_FATEngine.spin
}}

OBJ

  sd   :   "SD-MMC_FATEngine"
  pst  :   "Parallax Serial Terminal Plus"
  time :   "Timing"

CON                                      ''
                                         '' I/O Pin Constants
  DO  = 12                               '' DO  = 22   
  CLK = 13                               '' CLK = 23   
  DI  = 11                               '' DI  = 24   
  CS  = 8                               '' CS  = 25   
  CD  = -1                               '' CD  = -1   
  WP  = -1                               '' WP  = -1   
  rt1 = -1                               '' rt1 = -1   
  rt2 = -1                               '' rt2 = -1   
  rt3 = -1                               '' rt3 = -1   
                                         ''
                                         '' statusVal error constants
  Disk_IO_Error = 1                      '' Disk_IO_Error = 1              
  Clock_IO_Error = 2                     '' Clock_IO_Error = 2             
  File_System_Corrupted = 3              '' File_System_Corrupted = 3      
  File_System_Unsupported = 4            '' File_System_Unsupported = 4    
  Card_Not_Detected = 5                  '' Card_Not_Detected = 5          
  Card_Write_Protected = 6               '' Card_Write_Protected = 6       
  Disk_May_Be_Full = 7                   '' Disk_May_Be_Full = 7           
  Directory_Full = 8                     '' Directory_Full = 8             
  Expected_An_Entry = 9                  '' Expected_An_Entry = 9          
  Expected_A_Directory = 10              '' Expected_A_Directory = 10      
  Entry_Not_Accessible = 11              '' Entry_Not_Accessible = 11      
  Entry_Not_Modifiable = 12              '' Entry_Not_Modifiable = 12      
  Entry_Not_Found = 13                   '' Entry_Not_Found = 13           
  Entry_Already_Exist = 14               '' Entry_Already_Exist = 14       
  Directory_Link_Missing = 15            '' Directory_Link_Missing = 15    
  Directory_Not_Empty = 16               '' Directory_Not_Empty = 16       
  Not_A_Directory = 17                   '' Not_A_Directory = 17           
  Not_A_File = 18                        '' Not_A_File = 18                

VAR

  byte started, mounted, fileOpened, displayMode    

PUB Start : okay | statusStr     
{{
Starts up the SDC driver running on a cog and checks out a lock for the
driver. This method should only be called once for any number of included
versions of this object. This method causes all included versions of this
object to need re-mounting when called.
 
Returns:
  okay - true on success or false if no cog available.
}}
                      '       ,       
  ifnot sd.CogStatus
    okay := sd.FATEngineStart(DO, CLK, DI, CS, CD, WP, rt1, rt2, rt3)

  if displayMode == 0
    ifnot okay
      pst.Str(statusStr)
    else
      pst.Str(String("SD engine started."))
    pst.NewLine

PUB Stop  : statusVal | statusStr
{{
Shuts down the SDC driver running on a cog and returns the lock used by the
driver.

Notes:
This method should only be called once for any number of included
versions of this object.  This method causes all included versions of this
object to need re-mounting when called.
}}

  if sd.CogStatus
    sd.FATEngineStop

  if displayMode == 0
    pst.Str(String("SD engine stopped."))
    pst.NewLine

PUB Mount(partition) : statusVal | statusStr
{{
Mounts the specified partition.

Parameter:
  Partition - Partition number to mount (between 0 and 3). Default 0.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
Notes:
If a file is open when his method is called, it will be closed.

If the file system is FAT16 then it can be up to ~4GB.
If the file system is FAT32 then it can be up to ~1TB.
 
File sizes up to ~2GB are supported.
Directory sizes up to ~64K entries are supported. 
}}

  ifnot sd.CogStatus
    Start
    
  statusStr := \ sd.mountPartition(partition)
  statusVal :=   sd.partitionError

  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
    else
      pst.Str(String("Partition mounted."))
    pst.NewLine

PUB Unmount : statusVal | statusStr
{{
Unmounts the mounted partition.
 
Note:
If an error occurs and the object is in its default display mode, this method
will display a string describing that error in the Parallax Serial Terminal.
}}
  statusStr := \ sd.unmountPartition
  statusVal :=   sd.partitionError

  time.pause(1000)

  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
    else
      pst.Str(String("Partition unmounted."))
    pst.NewLine

PUB Run(filePathName) : statusVal | statusStr 
{{
Loads the propeller chip's RAM from the specified file. (Stop any other cogs
from accessing the driver before calling).
 
Parameter:
FilePathName - A file system path string specifying the path of the file to
               search for.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
 
Notes:
If a file is open when this method is called that file will be closed. The
file to be loaded and run must have a valid program checksum - if not the
propeller chip will shutdown.  The file to be loaded and run must have a
valid program base - if not the propeller chip will shutdown.  
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.bootPartition(filePathName)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
    else
      pst.Str(String("Run..."))  

PUB FileNew(nameStr) : statusVal | statusStr
{{
Creates a new file at the specified path.

Parameter:
  nameStr   - A file system path string specifying the path and name of the
              new file. Must be unique.
   
Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
Notes:
  If a file is open when his method is called, it will be closed.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.newFile(nameStr)
  statusVal :=   sd.partitionError

  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
    else
      pst.Str(String("Filename="))
      pst.Str(statusStr)
    pst.NewLine

PUB FileOpen(nameStr, mode) : statusVal | statusStr
{{
Searches the file system for the specified file in the path name and opens it
for reading, writing, or appending.

Parameters:
  nameStr   - A file system path string specifying the path of the file to
                 search for and the name of the file.
  Mode      - A character specifying the mode to use. R-Read, W-Write,
              A-Append.  Default read.
Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
Notes:
Each included version of this object may work with a different file.
Two objects allow for two files, etc.  Open files are not locked - Two
objects can read, write, and append a file at the same time. May cause
corruption.  Open files can also be deleted and moved by other included
versions of this object. This will cause corruption.  All files opened for
writing or appending must be closed or they will become corrupted.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.openFile(nameStr, mode)
  statusVal :=   sd.partitionError

  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
    else
      pst.Str(String("File opened."))
    pst.NewLine

PUB FileClose : statusVal | statusStr
{{
Closes the file open for reading, writing, or appending.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
Notes:
Each included version of this object may work with a different file.
Two objects allow for two files, etc.  Open files are not locked - Two objects
can read, write, and append a file at the same time. May cause corruption.
Open files can also be deleted and moved by other included versions of this
object. This will cause corruption.  All files opened for writing or appending
must be closed or they will become corrupted.  If an error occurs this method
will abort and return a pointer to a string describing that error.
}}

  statusStr := \ sd.closeFile
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
    else
      pst.Str(String("File closed."))
    pst.NewLine

PUB FileDelete(nameStr) : statusVal | statusStr
{{
Deletes a file or directory. Directories must be empty.

Parameters:
  nameStr - A file system path string specifying the path of the entry to
            search for.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.DeleteEntry(nameStr)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
    else
      pst.Str(String("File deleted."))
    pst.NewLine

PUB ReadByte : value | statusVal, statusStr     
{{
Reads a byte from the file that is currently open and advances the file
position by one.

Returns:
  value - The next byte to read from the file. Reads nothing when at the end
          of a file - returns zero.
Notes:
If an error occurs and the object is in its default display mode, this method
will display a string describing that error in the Parallax Serial Terminal.

This method will do nothing if a file is not currently open for reading
or writing.
}}

  value     := \ sd.readbyte
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine

PUB ReadWord : value | statusVal, statusStr     
{{
Reads a word from the file that is currently open and advances the file
position by two.

Returns:
  value - the next word to read from the file. Reads nothing when at the end
          of a file - returns zero.
Notes:
If an error occurs and the object is in its default display mode, this method
will display a string describing that error in the Parallax Serial Terminal.

This method will do nothing if a file is not currently open for reading
or writing.
}}

  value     := \ sd.readShort
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine

PUB ReadLong : value | statusVal, statusStr
{{
Reads a long from the file that is currently open and advances the file
position by four.

Returns:
  value - the next long to read from the file. Reads nothing when at the end
          of a file - returns zero.
Notes:
If an error occurs and the object is in its default display mode, this method
will display a string describing that error in the Parallax Serial Terminal.

This method will do nothing if a file is not currently open for reading
or writing.
}}

  value     := \ sd.readLong
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine

PUB ReadString(arrayAddr, maxLenth) : strPtr | statusVal, statusStr
{{
Reads a string from the file that is currently open and advances the file
position by the string length.

Parameters:
  arrayAddr - A pointer to a string to read to from the file.
  maxLength - The maximum read string length. Including the null
              terminating character.

Returns:
  strPtr    - The next string to read from the file. Reads nothing when at the
              end of a file.

Notes: This method will do nothing if a file is not currently open for reading
or writing.  If an error occurs this method will abort and return a pointer to
a string describing that error.  This method will stop reading when line feed
(ASCII 10) is found - it will be included within the string.  This method will
stop reading when carriage return (ASCII 13) is found - it will be included
within the string. 

}}

  strPtr    := \ sd.readString(arrayAddr, maxLenth)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine

PUB ReadData(arrayAddress, byteCnt) : statusVal | statusStr   
{{
Reads data from the file that is currently open and advances the file
position by that amount of data.

Parameters:
  arrayAddress - A pointer to the start of a data buffer to fill from disk.
  byteCnt      - The amount of data to read from disk. The data buffer must be
                 at least this large.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.

Notes:
This method will do nothing if a file is not currently open for reading or
writing.
}}

  statusStr := \ sd.readData(arrayAddress, byteCnt)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine
  
PUB WriteByte(value) : statusVal | statusStr   
{{
Writes a byte to the file that is currently open and advances the file
position by one.

Parameter:
  Value - A byte to write to the file. Writes nothing when at the end of a
          maximum size file.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
          
Note: This method will do nothing if a file is not currently open for writing.
}}

  statusStr := \ sd.writeByte(value)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine

PUB WriteWord(value) : statusVal | statusStr   
{{
Writes a word to the file that is currently open and advances the file
position by two.

Parameter:
  Value - A word to write to the file. Writes nothing when at the end of a
          maximum size file.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
          
Note: This method will do nothing if a file is not currently open for writing.
}}

  statusStr := \ sd.writeShort(value)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine

PUB WriteLong(value) : statusVal | statusStr   
{{
Writes a long to the file that is currently open and advances the file
position by four.

Parameter:
  Value - A long to write to the file. Writes nothing when at the end of a
          maximum size file.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
          
Note: This method will do nothing if a file is not currently open for writing.
}}
  statusStr := \ sd.writeLong(value)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine

PUB WriteStr(strPtr) : statusVal | statusStr  
{{
Writes a string to the file that is currently open and advances the file
position by the string length.

Parameter: 
  strPtr    - A pointer to a string to write to the file. Writes nothing
              when at the end of a maximum size file.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.

Note: This method will do nothing if a file is not currently open for writing.
}}
  statusStr := \ sd.WriteString(strPtr)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine
  
PUB WriteData(arrayAddr, count) : stride | statusStr, statusVal   
{{
Writes data to the file that is currently open and advances the file position
by that amount of data.

Parameters:
  arrrayAddr - A pointer to the start of a data buffer to write to disk.
  count      - The amount of data to write to disk. The data buffer must be at
               least this large.

Returns:
  stride     - the amount of data written to the disk. Writes nothing when at
               the end of a maximum size file.
Notes:
If an error occurs and the object is in its default display mode, this method
will display a string describing that error in the Parallax Serial Terminal.

This method will do nothing if a file is not currently open for reading
or writing.
}}

  statusStr := \ sd.WriteData(arrayAddr, count)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine
  
PUB FlushBuffer : statusVal | statusStr     
{{
Flushes data to the file that is currently open.

Flush data periodically for files opened for writing or appending open for
long periods of time to avoid corruption.

Notes:
If an error occurs and the object is in its default display mode, this method
will display a string describing that error in the Parallax Serial Terminal.

This method will do nothing if a file is not currently open for reading or
writing.
}}

  statusStr := \ sd.flushData
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
      pst.NewLine
  
PUB WriteDec(integer) | temp[3]
{{Writes a string of charcters that represents a decimal value to the open
file.

Parameter:
  Integer - Integer value to write.

Notes:
This method will do nothing if a file is not currently open for reading
or writing.
}}

  if(integer < 0) ' Print sign.
    sd.writeByte("-")

  byte[@temp][10] := 0
  repeat result from 9 to 0 ' Convert number.
    byte[@temp][result] := ((||(integer // 10)) + "0")
    integer /= 10

  result := @temp ' Skip past leading zeros.
  repeat while((byte[result] == "0") and (byte[result + 1]))
    result += 1

  sd.writeString(result~) ' Print number.


PUB WriteHex(integer)
{{Writes a string of charcters that represents a hexadecimal value to the open
file.

Parameter:
  Integer - Integer value to write.

Notes:
This method will do nothing if a file is not currently open for reading
or writing.
}}

  sd.writeString(string("0x")) ' Write header.

  repeat 8 ' Print number.
    integer <-= 4
    writeByte(lookupz((integer & $F): "0".."9", "A".."F"))

  
PUB Display
{{
Make this object display results and errors in the Parallax Serial Terminal.
This object displays these results by default.
}}
  displayMode := true

PUB NoDisplay
{{
Make this object stop displaying results and errors in the Parallax Serial
Terminal.  
}}
  displayMode := false

PUB DisplayText
{{
Displays text in the current open file in the Parallax Serial Terminal.

Note: If no file is open, no text will be displayed. 
}}             
  repeat sd.FileSize
    pst.Char(sd.ReadByte)
  pst.NewLine  

PUB FileSize : sizeBytes
{{
Report the current file size.

Returns:
  sizeBytes - The file size in bytes.

This method will do nothing if a file is not currently open for reading or
writing.
}}
  sizeBytes := sd.fileSize

PUB FindCursor : location
{{
Returns the file cursor position.

This method will do nothing if a file is not currently open for reading or
writing.
}}

  location := sd.fileTell

PUB PlaceCursor(location) : statusVal | statusStr
{{
Changes old the file position. Returns the new file position.

This method will do nothing if a file is not currently open for reading or
writing.

If an error occurs this method will abort and return a pointer to a string
describing that error.

Position - A byte position in the file. Between 0 and the file size minus 1.
Zero if file size is zero.
}}

  statusStr := \ sd.fileSeek(location)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
  
PUB Format(partition) : statusVal | statusStr
{{
Formats (erases all data on) and mounts the specified partition.
 
Partition - Partition number to format and mount (between 0 and 3). Default 0.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.
Notes:
If a file is open when his method is called, it will be closed.
 
If the file system is FAT16 then it can be up to ~4GB.
If the file system is FAT32 then it can be up to ~1TB.
 
File sizes up to ~2GB are supported.
Directory sizes up to ~64K entries are supported.  
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.formatPartition(partition)
  statusVal :=   sd.partitionError

  if displayMode == 0
    if statusVal
      pst.Str(statusStr)
    else
      pst.Str(String("Partition formatted."))
    pst.NewLine

PUB SetFolder(pathName) : statusStr | statusVal
{{
Searches the file system for the specified folder and changes the current
folder to be the specified directory.

Parameter:
  pathName - A file system path string specifying the path of the
             directory to search for.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.  If an error does not occur, it will
              display the directory's name.
Note: If a file is open when his method is called, it will be closed.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.changeDirectory(pathname)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
'    if statusVal
      pst.Str(statusStr)

PUB DeleteFolder(pathName) : statusVal | statusStr
{{
Deletes a file or directory. Directories must be empty.

Parameter:
  pathName - A file system path string specifying the path of the entry to
  search for.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.  If an error does not occur, it will
              display the deleted folder's name.

Note: If a file is open when this method is called that file will be closed.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.deleteEntry(pathname)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)

PUB Attributes(pathName, attributeString) : statusVal | statusStr
{{
Searches the file system for the specified entry in the path name and changes
its attributes.

Parameter:
  pathname        - A file system path string specifying the path of the entry
                    to search for.
  attributeString - A string of characters containing the new set of
                    attributes.  A-Archive, S-System, H-Hidden, R-Read Only.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.  If an error does not occur, it will
              display the entry's name.

Notes:
File can have the archive attribute.  Directories cannot have the archive
attribute.  

If a file is open when this method is called that file will be closed.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.changeAttributes(pathname, attributeString)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)

PUB Move(oldPathName, newPathName)  : statusVal | statusStr
{{
Moves a file or directory. "moveEntry(string("oldName"), string("newName"))"
renames the file or directory.

Parameters:
  oldPathName - A file system path string specifying the path of the old
                entry. (Path where to get and old name...)
  newPathName - A file system path string specifying the path of the new
                entry. (Path where to put and new name...)

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.  If an error does not occur, it will
              display the entry's new name.

Notes:
If a file is open when this method is called that file will be closed.

This method can create circular directory trees. A circular directory tree is
a directory tree inside of itself.  A circular directory tree can be orphaned
and leaked as memory from the file system with all of the entries inside of it.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.moveEntry(oldPathName, newPathName)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)

PUB FolderNew(pathStr) : statusVal | statusStr
{{
Creates a new directory at the specified path.

Parameter:
  pathStr - A file system path string specifying the path and name
           of the new directory. Must be unique.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.  If an error does not occur, it will
              display the directory's new name.

Note:
If a file is open when this method is called that file will be closed.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.newDirectory(pathStr)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)

PUB ListFiles(mode) : statusVal | statusStr

  ifnot sd.partitionMounted
    Mount(0)

  repeat while (statusVal := NextFileInfo("N"))
    pst.NewLine

PUB LoadFileInfo(pathName) : statusVal | statusStr
{{
Searches the file system for the specified entry in the path name. Wraps
around "listEntries." Caches the entry's information for use by the file
property methods. 

Parameter:
  pathName -  A file system path string specifying the path of the entry
              to search for.
   
Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.  If an error does not occur, it will
              display the filename and 

Note: If a file is open when this method is called that file will be closed.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.listEntries(pathName)
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)

PUB NextFileInfo(mode) : statusVal | statusStr 
{{
Searches the file system for the specified entry in the path name. Wraps
around "listEntries."  Caches the entry's information for use by the file
property methods. 

Parameter:
  filePathName - A character specifying the mode to use.
                 W-Wrap Around. N-Next Entry. Default next entry.

Returns:
  statusVal - Zero if success or nonzero error code.  Error codes can be
              looked up in the statusVal error constants table.  If an error
              occurs and the object is in its default display mode, this
              method will display a string describing that error in the
              Parallax Serial Terminal.  If an error does not occur, it will
              display the filename.

Note: If a file is open when this method is called that file will be closed.
}}

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.listEntries(mode)
  statusVal :=   statusStr
  
  if displayMode == 0
    if statusVal
      pst.Str(statusStr)

PUB ListName : statusVal | statusStr

  ifnot sd.partitionMounted
    Mount(0)

  statusStr := \ sd.listName
  statusVal :=   sd.partitionError
  
  if displayMode == 0
    pst.Str(statusStr)  

PUB Size : bytes
{{
Reports the file size.  You have to call either FindNext or
FindInFolder before calling this method.

Returns:
  bytes - The size in bytes of the entry pointed to by the listing methods.
         Directories have zero size.
 
If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}
  bytes := sd.listSize      

PUB IsReadOnly : trueFalse
{{
Reports whether the file or folder is read-only.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  size - The size in bytes of the entry pointed to by the listing methods.
         Directories have zero size.
 
If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  trueFalse := sd.listIsReadOnly

PUB IsHidden : trueFalse
{{
Reports whether the file or folder is hidden.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  trueFalse - True if the file is hidden
              False if the file is not hidden

If FindNextFile or FindFileInFolder errored or were not previously called
the value returned is invalid.  If an unrecoverable error occurred the value
returned is invalid.
}}
  trueFalse := sd.listIsHidden

PUB IsSystem : trueFalse
{{
Reports whether the file is a system file.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  trueFalse - True if the file is a system file
              False if the file is not a system file

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}
  trueFalse := sd.listIsSystem

PUB IsFolder : trueFalse
{{
Reports wether the entry is a folder.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  trueFalse - True if the entry is a folder
              False if the entry is not a folder

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}
  trueFalse := sd.listIsDirectory

PUB IsArchive : trueFalse
{{
Reports wether the entry is an archive.  You have to call either FindNext
or FindInFolder before calling this method.

Returns:
  trueFalse - True if the file is a system file
              False if the file is not a system file

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}
  trueFalse := sd.listIsArchive

PUB DiskSignature : signature
{{
Reports the disk signature number.

Returns:
  signature - the disk signature number
 
If an unrecoverable error occurred the value returned is invalid.
}}
  signature := sd.partitionDiskSignature

PUB VolumeId : id
{{
Reports the volume identification number.

Returns:
  id - the volume identification number
 
If an unrecoverable error occurred the value returned is invalid.
}}

  id := sd.partitionVolumeIdentification

PUB VolumeLabel : labelStrAddr
{{
Reports the volume label.

Returns:
  labelStrAddr - The address of the volume identification string
 
If an unrecoverable error occurred the value returned is invalid.
}}
  labelStrAddr := sd.partitionVolumeLabel  

PUB SectorBytes : byteCnt
{{
Reports the number of bytes per sector in the current partition.

Returns:
  byteCnt - the number of bytes per sector.
 
If an unrecoverable error occurred the value returned is invalid.
}}
  byteCnt := sd.partitionBytesPerSector

PUB ClustorSectors : sectorCnt
{{
Reports the number of sectors per clustor in the current partition.

Returns:
  sectorCnt - the number of sectors per clustor.
 
If an unrecoverable error occurred the value returned is invalid.
}}
  sectorCnt := sd.partitionSectorsPerCluster  

PUB PartitionSectors : sectorCnt
{{
Reports the number of sectors in the current partition.

Returns:
  sectorCnt - the number of sectors in the partition.
 
If an unrecoverable error occurred the value returned is invalid.
}}
  sectorCnt := sd.partitionDataSectors  

PUB PartitionClustors : clustorCnt
{{
Reports the number of clustors in the current partition.

Returns:
  clustorCnt - the number of clustors in the partition.
 
If an unrecoverable error occurred the value returned is invalid.
}}
  clustorCnt := sd.partitionCountOfClusters  

PUB SectorsUsed(mode) : sectorCnt
{{
Reports the number of sectors that store data in the current partition.

Returns:
  sectorCnt - the number of used sectors in the partition.
 
If an unrecoverable error occurred the value returned is invalid.
}}

  sectorCnt := sd.partitionUsedSectorCount(mode)  

PUB SectorsFree(mode) : sectorCnt
{{
Reports the number of sectors that are not storing data in the current
partition.

Returns:
  sectorCnt - the number of free sectors in the partition.
 
If an unrecoverable error occurred the value returned is invalid.
}}
  sectorCnt := sd.partitionFreeSectorCount(mode)

PUB IsMounted : trueFalse
{{
Reports whether or not the file system is mounted.

Returns:
  trueFalse - True if the file system is mounted.
              False if the file system is not mounted.
}}
  trueFalse := sd.partitionMounted

PUB IsWriteProtected : trueFalse
{{
Reports whether or not the partition is write protected.

Returns:
  trueFalse - True if the partition is write protected.
              False if the partition is not write protected.
}}
  trueFalse := sd.partitionWriteProtected

PUB CardNotDetected : trueFalse
{{
Reports whether or not the MicroSD card is is detected in the socket.

Returns:
  trueFalse - True if the MicroSD card is detected.
              False if the partition is not detected.
}}
  trueFalse := sd.partitionCardNotDetected

PUB SecondCreated : secondVal
{{
Reports the second the file or folder was created.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  secondVal - The second the file or folder was created.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  secondVal := sd.listCreationSeconds

PUB MinuteCreated : minuteVal
{{
Reports the minute the file or folder was created.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  minuteVal - The minute the file or folder was created.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  minuteVal := sd.listCreationMinutes  

PUB DayCreated : dateVal
{{
Reports the date day the file or folder was created.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  dateVal - The date day the file or folder was created.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  dateVal := sd.listCreationDay

PUB MonthCreated : monthVal
{{
Reports the month the file or folder was created.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  monthVal - The month the file or folder was created.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  monthVal := sd.listCreationMonth

PUB YearCreated : yearVal
{{
Reports the year the file or folder was created.  You have to call either
FindNext or FindInFolder before calling this method.

Returns:
  yearVal - The year the file or folder was created.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}
  yearVal := sd.listCreationYear  

PUB DayAccessed : dateVal
{{
Reports the date day the file or folder was last accessed.  You have to call
either FindNext or FindInFolder before calling this method.

Returns:
  dateVal - The day the file or folder was last accessed.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}
  dateVal := sd.listAccessDay

PUB MonthAccessed : monthVal
{{
Reports the month the file or folder was last accessed.  You have to call
either FindNext or FindInFolder before calling this method.

Returns:
  monthVal - The month the file or folder was last accessed.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}
  monthVal := sd.listAccessMonth

PUB YearAccesssed : yearVal
{{
Reports the year the file or folder was last accessed.  You have to call
either FindNext or FindInFolder before calling this method.

Returns:
  yearVal - The year the file or folder was last accessed.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  yearVal := sd.listAccessYear  

PUB SecondModified : secondVal
{{
Reports the second the file or folder was last modified.  You have to call
either FindNext or FindInFolder before calling this method.

Returns:
  secondVal - The second the file or folder was last modified.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}
  secondVal := sd.listModificationSeconds

PUB MinuteModified : minuteVal
{{
Reports the minute the file or folder was last modified.  You have to call
either FindNext or FindInFolder before calling this method.

Returns:
  minuteVal - The minute the file or folder was last modified.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  minuteVal := sd.listModificationMinutes  

PUB DayModified : dateVal
{{
Reports the date day the file or folder was last modified.  You have to call
either FindNext or FindInFolder before calling this method.

Returns:
  dateVal - The day the file or folder was last modified.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  dateVal := sd.listModificationDay

PUB MonthModified : monthVal
{{
Reports the month the file or folder was last modified.  You have to call
either FindNext or FindInFolder before calling this method.

Returns:
  monthVal - The month the file or folder was last modified.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  monthVal := sd.listModificationMonth

PUB YearModified : yearVal
{{
Reports the year the file or folder was last modified.  You have to call
either FindNext or FindInFolder before calling this method.

Returns:
  yearVal - The year the file or folder was last modified.

If FindNext or FindInFolder errored or were not previously called the value
returned is invalid.  If an unrecoverable error occurred the value returned
is invalid.
}}

  yearVal := sd.listModificationYear  

DAT                                           
{{
file:      PropBOE MicroSD.spin
Date:      2011.07.29
Version:   0.5
Author:    Andy Lindsay

           This object merely provides an abstraction
           layer for Kwabena's SD-MMC_FATEngine
           object to establish consistency with other
           Propeller Board of Education Lessons.

           Kwabena W. Agyeman did the hard work when
           he developed the SD-MMC_FATEngine.

           Portions of the documentation comments
           are also direct copy and paste from
           SD-MMC_FATEngine.
             
                
Copyright: (c) 2011 Parallax Inc. 

┌────────────────────────────────────────────┐
│TERMS OF USE: MIT License                   │
├────────────────────────────────────────────┤
│Permission is hereby granted, free of       │
│charge, to any person obtaining a copy      │
│of this software and associated             │
│documentation files (the "Software"),       │
│to deal in the Software without             │
│restriction, including without limitation   │
│the rights to use, copy, modify,merge,      │
│publish, distribute, sublicense, and/or     │
│sell copies of the Software, and to permit  │
│persons to whom the Software is furnished   │
│to do so, subject to the following          │
│conditions:                                 │
│                                            │
│The above copyright notice and this         │
│permission notice shall be included in all  │
│copies or substantial portions of the       │
│Software.                                   │
│                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT   │
│WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES │
│OF MERCHANTABILITY, FITNESS FOR A           │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN  │
│NO EVENT SHALL THE AUTHORS OR COPYRIGHT     │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR │
│OTHER LIABILITY, WHETHER IN AN ACTION OF    │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM,  │
│OUT OF OR IN CONNECTION WITH THE SOFTWARE   │
│OR THE USE OR OTHER DEALINGS IN THE         │
│SOFTWARE.                                   │
└────────────────────────────────────────────┘
}}  