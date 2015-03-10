OBJ

  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"
  pst    : "Parallax Serial Terminal Plus"

PUB go | value

  system.Clock(80_000_000)

  sd.Mount(0)
  sd.ListFiles("N")
  sd.Unmount




  