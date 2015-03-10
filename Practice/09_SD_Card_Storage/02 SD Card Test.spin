OBJ

  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"

PUB go

  system.Clock(80_000_000)

  sd.Mount(0)
  sd.FileOpen(String("Test.txt"), "R")
  sd.DisplayText
  sd.FileClose
  sd.Unmount



  