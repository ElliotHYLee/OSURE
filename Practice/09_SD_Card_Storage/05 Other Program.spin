OBJ

  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"
  pst    : "Parallax Serial Terminal Plus"
  time   : "Timing"

PUB go | c

  system.Clock(80_000_000)

  pst.Str(String("Now 05 Other Program.spin running."))
  pst.NewLine
  repeat
    repeat c from "a" to "z"
      pst.Char(c)
      time.pause(100)





      