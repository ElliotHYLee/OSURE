OBJ

  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"

PUB go

  system.Clock(80_000_000)
  
  sd.Mount(0)
  sd.FileDelete(String("Test.txt"))
  sd.FileNew(String("Test.txt"))
  sd.FileOpen(String("Test.txt"), "W")
  sd.WriteStr(String("Hello sd card!"))
  sd.WriteDec(50)
  sd.FileClose


  'open for reading
  sd.FileOpen(String("Test.txt"), "R")
  sd.DisplayText

  sd.FileClose
  sd.Unmount       




  