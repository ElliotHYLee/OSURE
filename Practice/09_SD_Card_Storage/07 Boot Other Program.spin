OBJ

  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"
  pst    : "Parallax Serial Terminal Plus"
  time   : "Timing"

PUB go | i

  system.Clock(80_000_000)

  pst.Str(String("This is 07 Boot Other Program.spin"))
  pst.NewLine
  time.Pause(1000)
  pst.Str(String("Let's run 05 Other Program.spin..."))
  pst.NewLine
  time.Pause(1000)
  
  sd.Run(String("05OTHE~1.EEP"))


  