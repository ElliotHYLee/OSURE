{{
This code is written by The Ohio State University Rocket Team
No copy rights......
}}


CON
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency

VAR
  'ONLY For Kyle (pooping chute)
        long poopCogId, targetAltitude, poopStack[128]
  
  'ONLY For Chad and Jackie (PID)
        long pidCogId, pidStack[128]
        long eulerAnlge[3], targetEulerAngle[3]
  'Servo var
        long          RampFlag
        long          ZoneClocks
        long          NoGlitch
        long          pulse

  'ONLY For David
  long servoPwm, servoPin
  
OBJ
   'ONLY FOR Kyle (altitude)
   'altimeter : "dddddd"

   
PUB Main
{{
@ PUB Main
@ Initializing cogs for the corresponding functions. And turn off defualt cog.
@ params non
@ return non
}}
  servoPin := 0
  servoStart

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
' snensor.get alitude
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




''=====================================================
''Servo Control - David
''=====================================================
PUB servoStart
  dira[servoPin]:=1
  repeat
    outa[servoPin]:=1
    waitcnt(cnt + clkfreq/1000000*100)
    outa[servoPin]:=0
    waitcnt(cnt + clkfreq/1000000*20)
    
  

<<<<<<< HEAD
  
=======
PUB SeroStart   
    RampFlag := 0 
    ZoneClocks := (clkfreq / _1uS * ZonePeriod)                                 'calculate # of clocks per ZonePeriod
    NoGlitch   := $FFFF_FFFF-(clkfreq / _1uS * NoGlitchWindow)                  'calculate # of clocks for GlitchFree servos. Problem occurs when 'cnt' value rollover is less than the servo's pulse width.                                                                                                                                                                                                                         
    cognew(@ServoStart,@ZoneClocks)
    Servo
PUB Servo 
    totalElapse:=0
    baseTime := cnt
    
      repeat 
       outa[motorPin[0]]:= 1                                 'motorPin is the pin the Servo
       waitcnt(baseTime + clkfreq/1000000*pulse[0])          'pusle equals the length of the pulse => from PID
       outa[motorPin[0]]:= 0

          'second servo (add in later)  
       'outa[motorPin[1]]:= 1 
       'waitcnt(cnt + clkfreq/1000000*pulse[1])
       'outa[motorPin[1]]:= 0
          'posibility of multiple motors
       totalElapse := pulse[0] '+ pulse[1]
       waitcnt(baseTime + (clkfreq/1000*20 - clkfreq/1000000*totalElapse))  'insert total interval time in place of 20 (possibly #motors x maxPWM) 

      

>>>>>>> origin/master


