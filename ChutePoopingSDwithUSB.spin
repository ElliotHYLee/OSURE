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

'Connect Accelerometer SDA to P1
'Connect Accelerometer SCL to P3
'Connect Accelerometer VIN to 3.3V
'Connect Accelerometer GND to GND


'IF YOU CHANGE ANY OF THESE CONNECTIONS ON THE ACTUAL MICROCONTROLLER
'THEN YOU MUST ALSO CHANGE THIS CODE
'THE "29124_altimeter" CODE AND THE
'"RocketPropBOE MicroSD" CODE AS WELL TO REFLECT YOUR NEW PINS
'OTHERWISE THE CODE WILL NOT WORK


Con
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency
  MAXLINENUMBER = 1000                 'define the maximum allowable line number in the .txt files
  
VAR
  'ONLY for attitude sensor
  byte sensorCodId
  long sensorStack[128]
  'for altimeter and SD card writing
  long poopCogId, targetAltitude, poopStack[128], lineNumber, fileName, numberOfFile, a, olda, direction, base, Poop,  eAngle, accel, gyro

OBJ
  alt   : "29124_altimeter"
  system : "Propeller Board of Education"
  sd     : "RocketPropBOE MicroSD"
  strConv : "String.spin"
  strOp  : "STRINGS.spin"
 ' sensor obj
  sensor : "tier2MPUMPL.spin"
  usb : "FullDuplexSerial.spin"


Pub ChutePooping   | stop, elapsed
  usb.quickstart
  system.Clock(80_000_000)
  Poop := 0
  direction := 0   'the direction of the rocket. >0 means going up. <0 means going down
  usb.strln(String("Hi1"))
'=====================================================================
''Start the altimeter and take the first reading
  usb.strln(String("Hi3"))
                   '(SCL, SDA, true = background processing  false = foreground processing)
  alt.start_explicit(15  , 14  , true)              ' Start altimeter explicitly with BACKGROUND processing.
  usb.strln(String("Hi2"))
  alt.set_resolution(alt#HIGHEST)                        ' Set to highest resolution.
  usb.strln(String("Hi2"))
  a := alt.altitude(alt.average_press)                     'take the first reading
'=====================================================================
  usb.strln(String("Hi2"))

''Start the accelerometer
'  startSensor

'=====================================================================
'' Defining file Names and convesion to strings from integer
'' and opening a file
                         
  numberOfFile := 0

''start the SD card
  sd.Mount(0)
  prepSD(getFileNamePtr)        'see prepSD function and getFileNamePtr function for details

  lineNumber :=0
  usb.strln(String("Hi3"))
  
'===================================================================== 

''write the first reading into the SD card
  base := alt.altitude(alt.average_press)
  sd.WriteDec(base) 


  repeat
    WriteAltitudeSD
    usb.strln(string("line added"))
    CheckAndWriteDirectionSD
'    WriteAccelSD
'    usb.decln(accel[0])
    'check if we have gone down in altitude a net 5 times. if so then poop the chute!
    if direction =< -5
      Poop:=1
      sd.WriteDec(Poop)
      lineNumber++
      quit
    else
      sd.WriteDec (Poop)
      lineNumber++
    usb.decln(lineNumber)
    usb.decln(numberOfFile)
    CheckLineNumber

'Quit that previous loop because we have pooped the chute,
'but we want to keep recording data. start a new loop

  repeat
    WriteAltitudeSD
    CheckAndWriteDirectionSD
    'WriteAccelSD
    'write our poop status. It should always be 1 at this point
    sd.WriteDec (Poop)  

    CheckLineNumber


        
  sd.FileClose
  sd.Unmount
  sd.Stop


''=====================================================
''Sensor Region 
''Number of Cog Used : 1
''=====================================================
{
PRI stopSensor
  if sensorCodId
    cogstop(sensorCodId ~ - 1)
  
PRI startSensor 
  sensor.initSensor(3,1) ' scl, sda, cFilter portion in %
  sensor.setMpu(%000_11_000, %000_01_000) '2000deg/s, 4g
  stopSensor
  sensorCodId:= cognew(runSensor, @sensorStack) + 1

PRI runSensor
  repeat
    sensor.run


  
    sensor.getEulerAngle(@eAngle)
    sensor.getGyro(@gyro)
    sensor.getAcc(@accel)

}

PUB prepSD(fid)
  usb.str(string("opn nw file: "))
  
  sd.FileDelete(fid)                   'Delete any old files
  sd.FileNew(fid)                      'Make a new file
  usb.strLn(fid)
  sd.FileOpen(fid, "W")                'Open file for writing
    'if we are using the accelerometer, use this header
    'sd.WriteStr(String("PAltCM    Dir    Ax    Ay    Az    Gx    Gy    Gz    Cx    Cy    Cz    Poop"))          'Print Header 

    'If no accelerometer, use this one
  sd.WriteStr(String("PAltCM    Dir    Poop"))          'Print Header 



PUB getFileNamePtr


  fileName := strConv.integerToDecimal(numberOfFile, 3)
  'fileName =+000
  fileName := strOp.SubStr(fileName, 1,3)
  'fileName = 000
  'fileName := strOp.combine(String("Altitude"), fileName)
  'fileName = Altitude000
  fileName := strOp.combine(fileName, String(".txt"))
  'fileName = Altitude000.txt
  return fileName


PUB WriteAltitudeSD
    olda := a                                            ' store previous alitiude in olda
    a := alt.altitude(alt.average_press)                 ' Get the current altitude in cm, from new average local pressure.
    sd.WriteByte(13)                                     ' Prints a new line in SD Card
    sd.WriteByte(10)                                     ' Moves Cursor?
    sd.WriteDec( a )                                     ' Writes the altitude in Feet *100

{
PUB WriteAccelSD  | i
  repeat i from 0 to 2
    sd.WriteStr(String("    "))
    sd.WriteDec(accel[i])
  repeat i from 0 to 2
    sd.WriteStr(String("    "))
    sd.WriteDec(gyro[i])
  repeat i from 0 to 2
    sd.WriteStr(String("    "))
    sd.WriteDec(eAngle[i])
 }
PUB CheckAndWriteDirectionSD
''check which way we are going
  if ((a - olda) > 5)  AND  (direction < 5)  AND  ((a - base) > 100)       'we have gone up in altitude by 5 cm, but max it out at 5
    direction := (direction + 1)                        'increase direction by 1)
  elseif ((a - olda) < -5)  AND ((a - base) > 500)                             'we have goine down in altitude by 5 cm
    direction := (direction - 1)                        'decrease direction by 1
  elseif ((a-base) < 100)
    'do nothing because we have not raised our altitude more than 1 meter from our starting altitude                        
  sd.WriteStr(String("    "))
  sd.WriteDec(direction)
  sd.WriteStr(String("    "))

  
PUB CheckLineNumber
  if lineNumber > MAXLINENUMBER    'then the file size is too large for propeller to handle and we must open a new one
    sd.FileClose
    usb.strln(string("close current file0"))
    numberOfFile++
    lineNumber := 0
    prepSD(getFileNamePtr)
   
    waitcnt(cnt+clkfreq)