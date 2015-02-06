Con
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency

VAR
  long y

OBJ
  objServo   : "Servo32v7.spin"
  objSensor  : "sensor.spin"
  objPID     : "PID.spin"
  objSDcontrol : "SDcontrol.spin"
  objChutePoop : "ChutePooping.spin"
  objAttidude : "Attidude.spin"
  
PUB  Main
     ServoControl
     Altimeter
     Attidude
     SDcontrol
     PID
     ChutePooping
     repeat
       
       x:= objAttidude.getAX
       objPID.setAx(x)
       y:= objAttidude.getAY
       objPID.setAx(y)
    
PUB  ServoControl
  objServo.start
     '
     
PUB  Altimeter
  objSensor.start

PUB  Attidude
  objAttidude.start

PUB  SDcontrol
  objSDcontrol.start

PUB  PID
  objPID.start

PUB  ChutePooping
  objChutePoop.start

