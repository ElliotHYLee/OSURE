OBJ

  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"
  pst    : "Parallax Serial Terminal Plus"

PUB go | value

  system.Clock(80_000_000)

  sd.Mount(0)
  sd.FileNew(String("ValData.txt"))
  sd.FileOpen(String("ValData.txt"), "W")
  
  repeat 3
    pst.Str(String("Enter value: "))
    value := pst.DecIn
    sd.Writelong(value)

  sd.FileClose  
  sd.FileOpen(String("ValData.txt"), "W")

  repeat 3
    pst.Str(String("You entered: "))
    value := sd.ReadLong
    pst.Dec(value)
    pst.NewLine    

  sd.FileClose
  sd.Unmount  
    

  