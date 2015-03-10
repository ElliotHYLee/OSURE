OBJ

  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"

PUB go

  system.Clock(80_000_000)
  
  sd.Mount(0)
  sd.FileNew(String("Test.txt"))
  sd.FileOpen(String("Test.txt"), "W")
  sd.WriteStr(String("Hello SD card!"))
  sd.FileClose
  sd.Unmount       




  