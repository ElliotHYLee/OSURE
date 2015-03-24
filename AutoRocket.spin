{{
This code is written by The Ohio State University Rocket Team
No copy rights...... Go Bucks
}}


CON
  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000                 'defining clock frequency

  'Servo's min and max pose, these constants are specific to a product
  sMin = 559  '-90 deg
  sMax = 2443 '+90 deg 

  
  'Kyle's constants
  START_ALT     = 800                'Your starting altitude in feet.
  chutePIN = 2                       'the I/O pin number of the parachute pooping device 
VAR
  'ONLY For Kyle (pooping chute)
  long poopCogId, poopStack[128]
  
{{  'ONLY For Chad and Jackie (PID)
  long pidCogId, pidStack[128]
  long eulerAnlge[3], targetEulerAngle[3]     
}}
  'ONLY For David
  long servoPin[2], servoStack[128], servoCogId
  long servoPosition
  'PID Variables
  long cur_pos        'Real Position
  long set_pos        'Set Point
  long K              'PID Gain
  long cur_error      'Current Error
  long pre_error      'Previous Error
  long output         'PID Output
  long PIDstack[30]      'COG Stack
  byte PIDcog            'cog number
  long dt             'Integral Time
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

   startChutePoop 
''=====================================================
''Servo Control - David
''Numberof Cog Used: 2

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
''Number Of Cog Used : 2
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

PUB chutePoop| j, direction, a, olda, base, stop, elapsed
{{
@ PUB chutePoop
@ Checks current altitude and poop the chute if the condition meets.
@ After pooping, it turns off the cog
@ params non
@ return cogId

}}
  direction := 0   'the direction of the rocket. >0 means going up. <0 means going down
  j := 0
                   '(SCL, SDA, true = background  false = foreground)
  alt.start_explicit(0  , 1  , false)              ' Start altimeter for QuickStart with FOREGROUND processing.
  alt.set_resolution(alt#HIGHEST)                        ' Set to highest resolution.
  alt.set_altitude(alt.m_from_ft(START_ALT * 100))       ' Set the starting altitude, based on average local pressure.                  
  a := alt.altitude(alt.average_press)

  repeat
    olda := a                                            ' store previous alitiude in olda
    a := alt.altitude(alt.average_press)                 ' Get the current altitude in cm, from new average local pressure.
    'check which way we are going
    if ((a - olda) > 0)  AND  (direction < 5)         'we have gone up in altitude, but max it out at 5
      direction := (direction + 1)                        'increase direction by 1)
    elseif (a - olda) < 0                               'we have goine down in altitude
      direction := (direction - 1)                        'decrease direction by 1

    ''if we go down net 5 then pop the parachute
    if (direction =< -5) AND (a > 200000)      ' this makes sure we aren't below 2000 meters before we poop the chute. (a is in cm)
      cogstop(PIDcog)
      dira[chutePIN] := 1    'set the parachute pin to output.
      outa[chutePIN] := 1    'set the parachute pin to high  (POOPING THE CHUTE)
      return

''=====================================================
''Sensor Region 
''Number of Cog Used : 1
''=====================================================





''=====================================================
''PID Region - Chad & Jackie
''Number of Cog Used : 1
''=====================================================

    
PUB Start
''Starts PID controller.  Starts a new cog to run in.
           ''Current_Addr  = Address of Long Variable holding actual position
           ''Set_Addr      = Address of Long Variable holding set point
           ''Gain          = PID Algorithm Gain, ie: large gain = large changes faster, though less precise overall
           ''Integral_Time = PID Algorithm Integral_Time
           ''Output_Addr   = Address of Long Variable which holds output of PID algorithm


  cur_pos := dtheta
  set_pos := 0
  Kp := 1                       'Proportional Gain
  Ki := 1                       'Integral Gain
  Kp := 1                       'Derivative Gain
  dt := 
  output := servoPosition

  pre_error :=  
  cur_error :=   

  PIDcog := cognew(Loop, @PIDstack)

PUB Loop | e, P, I, D

repeat
  long[cur_error] := long[set_pos] - long[cur_pos]
  P := Kp * long[cur_error]
  
  I := I + Ki * long[cur_error] * dt
  
  e := long[cur_error] - long[pre_error]
  D := Ki * e / dt
  
  long[pre_error] := long[cur_error]

  long[output] := P + I + D

    
  waitcnt(clkfreq / 1000 * dt + cnt)  
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
''Number of Cog Used : 1
''=====================================================

'init sd card

'wirte atidude
'wirte PID consts..





  