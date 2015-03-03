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

  repeat
    servoStart

  

  
PUB servoStart
  dira[servoPin]:=1
  repeat
    outa[servoPin]:=1
    waitcnt(cnt + clkfreq/1000000*servoPwm)
    outa[servoPin]:=0
    waitcnt(cnt + clkfreq/1000000*20)
    
  

  
