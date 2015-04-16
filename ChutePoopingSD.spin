'Kyle'
'popping the chute at a given Pressure altitude WITH SD Writing'
'Connect Altimeter SCL to P15
'Connect Altimeter SDA to P14
'Connect Altimeter VIN to 3.3V
'Connect Altimeter GND to GND

'Connect SDCard    3.3V to 3.3V
'Connect SDCard    Vss to GND
'Connect SDCard    CLK to P5
'Connect SDCard    CS  to P7
'Connect SDCard    DO  to P4
'Connect SDCard    DI  to P6


Con
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency

  START_ALT     = 800                ' Your starting altitude in feet.

VAR
'  long h  'altitude
'  long htarget, currentAltitude
  long poopCogId, targetAltitude, poopStack[128], lineNumber, fileName, numberOfFile

OBJ
  alt   : "29124_altimeter"
  pst   : "parallax serial terminal plus"
  system : "Propeller Board of Education"
  sd     : "PropBOE MicroSD"
  strConv : "String.spin"
  strOp  : "STRINGS.spin"
Pub ChutePooping   | j, direction, a, olda, base, stop, elapsed,  Poop


  system.Clock(80_000_000)
  Poop := FALSE
  direction := 0   'the direction of the rocket. >0 means going up. <0 means going down
  j := 0

                   '(SCL, SDA, true = background  false = foreground)
  alt.start_explicit(15  , 14  , true)              ' Start altimeter for QuickStart with FOREGROUND processing.
  alt.set_resolution(alt#HIGHEST)                        ' Set to highest resolution.
'  alt.set_altitude(alt.m_from_ft(START_ALT * 100))       ' Set the starting altitude, based on average local pressure.                  
  a := alt.altitude(alt.average_press)


  base:=alt.altitude(alt.average_press)
  sd.WriteDec(base)
  
'=====================================================================
'' Defining file Names and convesion to strings from integer
'' and opening a file
                         
  numberOfFile := 0

  fileName := strConv.integerToDecimal(numberOfFile, 3)
  'fileName =+000
  fileName := strOp.SubStr(fileName, 1,3)
  'fileName = 000
  fileName := strOp.combine(String("Altitude"), fileName))
  'fileName = Altitude000
  fileName := strOp.combine(fileName, String(".txt"))
  'fileName = Altitude000.txt

  sd.Mount(0)
  prepSD(fileName)

  lineNumber :=0
  
'=====================================================================
  repeat
    olda := a                                            ' store previous alitiude in olda
    a := alt.altitude(alt.average_press)                 ' Get the current altitude in cm, from new average local pressure.
    pst.newline
    pst.dec(a)
    pst.str(string(pst#HM, "Pressure Altitude:"))                 ' Print header.
    pst.str(alt.formatn(a, alt#METERS | alt#CECR, 8))    ' Print altitude in meters, clear-to-end, and CR.
    pst.str(alt.formatn(a, alt#TO_FEET | alt#CECR, 17))  ' Print altitude in feet, clear-to-end, and CR.
    sd.WriteByte(13)                                     ' Prints a new line in SD Card
    sd.WriteByte(10)                                     ' Moves Cursor?
    sd.WriteDec( a )                                     ' Writes the altitude in Feet *100

    'check which way we are going
    if ((a - olda) > 5)  &  (direction < 5)  &  ((a - base) > 100)       'we have gone up in altitude by 10 cm, but max it out at 5
      direction := (direction + 1)                        'increase direction by 1)
    elseif ((a - olda) < -5)  & ((a - base) > 500)                             'we have goine down in altitude by 10 cm
      direction := (direction - 1)                        'decrease direction by 1
    elseif ((a-base) < 100)
      pst.newline
      pst.str(String("Still below 1 meter from starting altitude"))
      pst.dec(base)
  
    pst.newline
    pst.dec(direction)
    sd.WriteStr(String("    "))
    sd.WriteDec(direction)
    sd.WriteStr(String("    "))
    if direction =< -5
      Poop:=1
      pst.str(string("POOPING CHUTE"))
      sd.WriteDec(Poop)
      quit
    else
      sd.WriteDec (Poop)
    if (pst.rxcount)                                     ' Respond to any key by clearing screen.
      pst.rxflush
      pst.char(pst#CS)

    lineNumber++
    if lineNumber > 6000
      sd.FileClose
      numberOfFile++
      lineNumber := 0
      prepSD(getFileNamePtr)
      
  sd.Unmount
  sd.Stop
    

PUB prepSD(fid)

  sd.FileDelete(fid)                   'Delete any old files
  sd.FileNew(fid)                      'Make a new file
  sd.FileOpen(fid, "W")                'Open file for writing
  sd.WriteStr(String("PAltCM    Dir    Poop    "))          'Print Header 
  


PUB getFileNamePtr


  fileName := strConv.integerToDecimal(numberOfFile, 3)
  'fileName =+000
  fileName := strOp.SubStr(fileName, 1,3)
  'fileName = 000
  fileName := strOp.combine(String("Altitude"), fileName))
  'fileName = Altitude000
  fileName := strOp.combine(fileName, String(".txt"))
  'fileName = Altitude000.txt

  return fileName