'Kyle'
'popping the chute at a given altitude'

Con
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency

  START_ALT     = 800                ' Your starting altitude in feet.

VAR
'  long h  'altitude
'  long htarget, currentAltitude
  long poopCogId, targetAltitude, poopStack[128] 

OBJ
  alt   : "29124_altimeter"
  pst   : "parallax serial terminal"


Pub ChutePooping   | j, direction, a, olda, base, stop, elapsed
  direction := 0   'the direction of the rocket. >0 means going up. <0 means going down
  j := 0

  pst.start(115200)                                       ' Start Parallax serial terminal.
                   '(SCL, SDA, true = background  false = foreground)
  alt.start_explicit(15  , 14  , true)              ' Start altimeter for QuickStart with FOREGROUND processing.
  alt.set_resolution(alt#HIGHEST)                        ' Set to highest resolution.
  alt.set_altitude(alt.m_from_ft(START_ALT * 100))       ' Set the starting altitude, based on average local pressure.                  
  a := alt.altitude(alt.average_press)

  repeat
    olda := a                                            ' store previous alitiude in olda
    a := alt.altitude(alt.average_press)                 ' Get the current altitude in cm, from new average local pressure.
    pst.newline
    pst.dec(a)
    pst.str(string(pst#HM, "Altitude:"))                 ' Print header.
    pst.str(alt.formatn(a, alt#METERS | alt#CECR, 8))    ' Print altitude in meters, clear-to-end, and CR.
    pst.str(alt.formatn(a, alt#TO_FEET | alt#CECR, 17))  ' Print altitude in feet, clear-to-end, and CR.

    'check which way we are going
    if ((a - olda) > 0)  &  (direction < 5)         'we have gone up in altitude, but max it out at 5
      direction := (direction + 1)                        'increase direction by 1)
    elseif (a - olda) < 0                               'we have goine down in altitude
      direction := (direction - 1)                        'decrease direction by 1

    pst.newline
    pst.dec(direction)
    if direction =< -5
      pst.str(string("POOPING CHUTE"))
      return

    if (pst.rxcount)                                     ' Respond to any key by clearing screen.
      pst.rxflush
      pst.char(pst#CS)

 