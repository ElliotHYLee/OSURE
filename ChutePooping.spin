'Kyle'
'popping the chute at a given altitude'

Con
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency

VAR
  long h  'altitude
  long htarget
OBJ


Pub ChutePooping
  'Set an htarget
  htarget := 10000 'feet

  'do we calculate current h in here?
  'or is it from another part of the code?
  
  if h >= htarget 'if we have reached or exceeded our goal altitude
      'poop the chute
      'blast the charge? or is it turn a servo motor
      return
    else
      'just keep waiting
   


  