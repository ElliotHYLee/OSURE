{{
This code is written by The Ohio State University Rocket Team
No copy rights......
}}


CON
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency

  'Servo's min and max pose, these constants are specific to a product
  sMin = 559  '-90 deg
  sMax = 2443 '+90 deg 
  
VAR
  'ONLY For Kyle (pooping chute)
  long poopCogId, targetAltitude, poopStack[128]
  
  'ONLY For Chad and Jackie (PID)
  long pidCogId, pidStack[128]
  long eulerAnlge[3], targetEulerAngle[3]     

  'ONLY For David
  long servoPin[2], servoStack[128], servoCogId
  long servoPosition
OBJ
 'ONLY FOR Kyle (altitude)
  alt : "29124_altimeter"

  SERVO : "Servo32v7.spin"  
   
PUB Main
{{
@ PUB Main
@ Initializing cogs for the corresponding functions. And turn off defualt cog.
@ params non
@ return non
}}
  servoPin[0] := 0
  servoStart

  servoPosition := 0
'  repeat
'    servoPosition++
'    waitcnt(cnt + clkfreq/1000*500)
'    if servoPosition >89
'      servoPosition := -100


''=====================================================
''Servo Control - David
''=====================================================
PUB servoStart
  SERVO.Start
  servoStop
  servoCogId := cognew(runServo, @servoStack) + 1

PUB servoStop
  if servoCogId>0
    'what is the code to stop?
    cogstop(servoCogId ~ - 1) 'For David, <3 Kyle
    
PUB runServo
  repeat
    poseServoAt(servoPosition)
    waitcnt(cnt + clkfreq/1000000*100)

PUB poseServoAt(degree) | y, m
  m := (sMax-sMin)/180
  y := m*(degree-90) + sMax
  Servo.set(servoPin[0], y)
 

         
''
''=====================================================
''Altitude Reading and Pooping Region - Kyle
''=====================================================
PUB stopChutePoop
{{
@ PUB stopChutePoop
@ Stops poop cog if it's running
@ params none
@ return nah
}}
  if poopCogId
    cogstop(poopCogId ~ - 1)

PUB startChutePoop
{{
@ PUB startChutePoop
@ Make sure that the cog is not already running. And starts poop cog
@ params none
@ return nah
}}
  stopChutePoop
  poopCogId := cognew(chutePoop, @poopStack) + 1

PUB chutePoop
{{
@ PUB chutePoop
@ Checks current altitude and poop the chute if the condition meets.
@ After pooping, it turns off the cog
@ params non
@ return cogId

}}
'  snensor.get alitude
'   cog if(htart>current)
'   poop
'   turn off

''
''=====================================================
''PID Region - Chad & Jackie
''=====================================================
PUB stopPid
{{
@ PUB stopPID
@ Stops PID cog if it's running
@ params none
@ return
}}
  if pidCogId
    cogstop(pidCogId ~ - 1)
    
PUB startPid
{{
@ PUB startPID
@ Make sure that the cog is not already running. And starts PID cog
@ params none
@ return
}}
  stopPid
  pidCogId := cognew(pid, @pidStack) + 1

PUB pid
{{
@ PUB pid
@ Checks calculates PID forever
@ After pooping,stop controlling
@ params none
@ return none

}}

'read EulerAngles(x,y,z)

'calculate ouput
'update the output

               
''
''=====================================================
''SD card (gyro + acc) - Done by everyone
''=====================================================

'init sd card

'wirte atidude
'wirte PID consts..





  