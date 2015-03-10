OBJ

  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"
  pst    : "Parallax Serial Terminal Plus"

PUB go | x, y

  system.Clock(80_000_000)

  sd.Mount(0)
  sd.FileNew(String("SsData.txt"))
  sd.FileOpen(String("SsData.txt"), "W")
  
  sd.WriteStr(String("X Values, Y Values", 13, 10))
  
  repeat 3
    pst.Str(String("Enter x value "))
    x := pst.DecIn
    sd.WriteDec(x)
    sd.WriteByte(",")
    
    pst.Str(String("Enter y value "))
    y := pst.DecIn
    sd.WriteDec(y)
    sd.WriteByte(13)                             ' Carriage return
    sd.WriteByte(10)                             ' New line

  sd.FileClose  
  sd.Unmount  
  