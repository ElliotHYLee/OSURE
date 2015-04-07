'Kyle'
'popping the chute at a given Pressure altitude WITH SD Writing'
'Connect Altimeter SCL to P15
'Connect Altimeter SDA to P14
'Connect Altimeter VIN to 3.3V
'Connect Altimeter GND to GND

'Connect SDCard    3.3V to 3.3V
'Connect SDCard    Vss to GND
'Connect SDCard    CLK to P7
'Connect SDCard    CS  to P6
'Connect SDCard    DO  to P5
'Connect SDCard    DI  to P4


Con
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency

'  START_ALT     = 800                ' Your starting altitude in feet.

VAR
  'ONLY for attitude sensor
  byte sensorCodId
  long sensorStack[128]
  
OBJ
  alt   : "29124_altimeter"
'  pst   : "parallax serial terminal plus"
  system : "Propeller Board of Education"
  sd     : "RocketPropBOE MicroSD"
  
 ' sensor obj
  sensor : "tier2MPUMPL.spin"
Pub ChutePooping   | direction, a, olda, base, stop, elapsed,  Poop , eAngle, accel, gyro  

  system.Clock(80_000_000)
  Poop := 0
  direction := 0   'the direction of the rocket. >0 means going up. <0 means going down

  'Start the altimeter
                   '(SCL, SDA, true = background  false = foreground)
  alt.start_explicit(15  , 14  , true)              ' Start altimeter explicitly with BACKGROUND processing.
  alt.set_resolution(alt#HIGHEST)                        ' Set to highest resolution.
'  alt.set_altitude(alt.m_from_ft(START_ALT * 100))       ' Set the starting altitude, based on average local pressure.                  
  a := alt.altitude(alt.average_press)                     'take the first reading

  'start the SD card
  sd.Mount(0)
  sd.FileDelete(String("Altitude.txt"))                   'Delete any old files
  sd.FileNew(String("Altitude.txt"))                      'Make a new file
  sd.FileOpen(String("Altitude.txt"), "W")                'Open file for writing
  sd.WriteStr(String("PAltCM    Dir    Poop"))          'Print Header 
  


  base := alt.altitude(alt.average_press)
  sd.WriteDec(base)
  repeat
    olda := a                                            ' store previous alitiude in olda
    a := alt.altitude(alt.average_press)                 ' Get the current altitude in cm, from new average local pressure.
    sd.WriteByte(13)                                     ' Prints a new line in SD Card
    sd.WriteByte(10)                                     ' Moves Cursor?
    sd.WriteDec( a )                                     ' Writes the altitude in Feet *100

    'check which way we are going
    if ((a - olda) > 5)  AND  (direction < 5)  AND  ((a - base) > 100)       'we have gone up in altitude by 5 cm, but max it out at 5
      direction := (direction + 1)                        'increase direction by 1)
    elseif ((a - olda) < -5)  AND ((a - base) > 500)                             'we have goine down in altitude by 5 cm
      direction := (direction - 1)                        'decrease direction by 1
    elseif ((a-base) < 100)
      'do nothing because we have not raised our altitude more than 1 meter from our starting altitude                        
    sd.WriteStr(String("    "))
    sd.WriteDec(direction)
    sd.WriteStr(String("    "))
    if direction =< -5
      Poop:=1
      sd.WriteDec(Poop)
      quit
    else
      sd.WriteDec (Poop)


'so i quit that previous loop because we have pooped the chute,
'but I want to keep recording data so I'm going to start a new loop

  repeat
    olda := a                                            ' store previous alitiude in olda
    a := alt.altitude(alt.average_press)                 ' Get the current altitude in cm, from new average local pressure.
    sd.WriteByte(13)                                     ' Prints a new line in SD Card
    sd.WriteByte(10)                                     ' Moves Cursor?
    sd.WriteDec( a )                                     ' Writes the altitude in Feet *100

    'check which way we are going
    if ((a - olda) > 5)  AND  (direction < 5)         'we have gone up in altitude by 10 cm, but max it out at 5
      direction := (direction + 1)                        'increase direction by 1)
    elseif (a - olda) < -5                               'we have goine down in altitude by 10 cm
      direction := (direction - 1)                        'decrease direction by 1
    elseif ((a-base) < 100)                          
    sd.WriteStr(String("    "))
    sd.WriteDec(direction)
    sd.WriteStr(String("    "))
    sd.WriteDec (Poop)  
  
  sd.FileClose
  sd.Unmount
  sd.Stop


''=====================================================
''Sensor Region 
''Number of Cog Used : 1
''=====================================================
PRI stopSensor
  if sensorCodId
    cogstop(sensorCodId ~ - 1)
  
PRI startSensor 
  sensor.initSensor(15,14) ' scl, sda, cFilter portion in %
  sensor.setMpu(%000_11_000, %000_01_000) '2000deg/s, 4g
  stopSensor
  sensorCodId:= cognew(runSensor, @sensorStack) + 1

PRI runSensor
  repeat
    sensor.run

{
  repeat
    sensor.getEulerAngle(@eAngle)
    sensor.getGyro(@gyro)
    sensor.getAcc(@accel)
}    