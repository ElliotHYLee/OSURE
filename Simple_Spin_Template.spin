CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
OBJ

  pst : "Parallax Serial Terminal"

Var
  long stack
  byte cogIndex
PUB main
 dira[12] := 1
 dira[11] := 1

  start
  repeat
    outa[12]:= 1
    waitcnt(cnt + clkfreq/100 )
    outa[12]:= 0
    waitcnt(cnt + clkfreq/100 )

    outa[11]:= 1
    waitcnt(cnt + clkfreq/100 )
    outa[11]:= 0
    waitcnt(cnt + clkfreq/100 )
PUB pwm
  repeat
    pst.str(string("Hello World"))
    pst.newline
    pst.start
PUB start
  stopMotor
  cogIndex:= cognew(pwm, 0Stack)
PUB stopMotor
  if cogIndex
      cogStop(cogIndex( ~ - 1 ))