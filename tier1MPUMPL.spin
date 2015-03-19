{{
  ┌──────────────────────────────────────────┐
  │ MPU-9150 demo using my I2C driver        │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2014 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
}}

CON
  _clkmode = xtal1 + pll16x                                                    
  _xinfreq = 5_000_000

  SCL = 15
  SDA = 14

  ACC_X_CAL = 512
  ACC_Y_CAL = 436
  ACC_Z_CAL = -700
  
' useful assignments:
  mpuAdd = $68
  ak8Add = $0C
  
VAR
 
  '1st-tier data
  long  acc[3], temperature, gyro[3], mag[3]

  'intermediate data
  long  gyroBias[3]
  byte  asax, asay, asaz

  'raw data
  byte  array[14],array2[14], MPU[10]

OBJ
  I2C : "I2C Spin driver v1.3"
  FDS : "FullDuplexSerial"

PUB Main 
  fds.quickStart
  
  initSensor(SCL, SDA)                                                    

  setMpu(%000_11_00, %000_01_000)

  fds.decLn(gyroBias[0])
  fds.decLn(gyroBias[1])
  fds.decLn(gyroBias[2])

 ' return
  
  MPU_9150_demo


PUB MPU_9150_demo 

  repeat
    fds.clear

    getMpu
    fds.str(String("accX "))
    fds.dec(acc[0])
    fds.newline
    fds.newline
    fds.str(String("   magX "))
    fds.dec(mag[0])
    fds.str(String("   magY "))
    fds.dec(mag[1])
    fds.str(String("   magZ "))
    fds.decLn(mag[2])
    fds.newline
    fds.newline
    
    fds.str(String("   gyroX "))
    fds.dec(gyro[0])
    fds.str(String("   gyroY "))
    fds.dec(gyro[1])
    fds.str(String("   gyroZ "))
    fds.decLn(gyro[2])

    fds.str(String("magnituide"))
    
    fds.decLn(acc[0]*acc[0]+acc[1]*acc[1]+acc[2]*acc[2])
       
    getAk8
 {     
    orthogonalize

    fds.str(String("Orth accX "))
    fds.decLn(mpu[0])
    fds.str(String("Orth accY "))
    fds.decLn(mpu[1])
    fds.str(String("Orth accZ "))
    fds.decLn(mpu[2])        
    fds.newline

    fds.str(String("Orth   gyroX "))
    fds.decLn(mpu[4])
    fds.str(String("Orth   gyroY "))
    fds.decLn(mpu[5])
    fds.str(String("Orth   gyroZ "))
    fds.decLn(mpu[6])
 }   
    waitcnt(cnt+clkfreq/10)

PUB reportData(accPtr, gyroPtr, magPtr, temPtr)

  getMpu
  getAk8
   
  Long[accPtr][0] := acc[0]
  Long[accPtr][1] := acc[1]
  Long[accPtr][2] := acc[2]

  Long[gyroPtr][0] := gyro[0]
  Long[gyroPtr][1] := gyro[1]
  Long[gyroPtr][2] := gyro[2]

  Long[magPtr][0] := mag[0]
  Long[magPtr][1] := mag[1]
  Long[magPtr][2] := mag[2]                           

  Long[temPtr] := temperature

                                                 
PUB initSensor(sc, sd)

  I2C.start(sc,sd)      

PUB setMpu(gyroSense, accSense) 

  I2C.write(mpuAdd,$6B,$01)                                                        ' take out of sleep and use gyro-x as clock source
  I2C.write(mpuAdd,$37,$02)                                                        ' enable I2C bypass in order to communicate with the magnetometer at address $0C
  I2C.write(ak8Add,$0A,%1111)                                                      ' access the magnetometer Fuse ROM
  I2C.read_page(ak8Add,$10,@asax,3)                                                ' Read the magnetometer adjustment values

  asax := (asax - 128) / 2                                                      ' These values never change so might as well do a partial calculation here
  asay := (asay - 128) / 2                                                      '  equation from datasheet:    Hadj = H x (((ASA - 128) x 0.5 / 128) + 1) 
  asaz := (asaz - 128) / 2                                                      '  microcontroller friendlier: Hadj = (H x (ASA - 128) / 2) / 128 + H

  I2C.write(mpuAdd,$19,$01)                                                        ' Sample rate divider (divide gyro_rate by 1 + x)
  I2C.write(mpuAdd,$1A,%00_000_110)                                                ' Digital low-pass filtering (0 = 8KHz gyro_rate, !0 = 1KHz gyro_rate)
  I2C.write(mpuAdd,$1B,gyroSense)                                                ' Accelerometer sensitivity ±250°/s
  I2C.write(mpuAdd,$1C,accSense)                                                ' Accelerometer sensitivity ±2g

  calcBias


PUB calcBias

  repeat 256
    repeat until I2C.read(mpuAdd,$3A) & $01
    I2C.read_page(mpuAdd,$43,@array,6)
    gyroBias[0] += ~array[0] << 8 | array[1]
    gyroBias[1] += ~array[2] << 8 | array[3]
    gyroBias[2] += ~array[4] << 8 | array[5]

  gyroBias[0] /=256
  gyroBias[1] /=256
  gyroBias[2] /=256

PUB getMpu | i

  if I2C.read(mpuAdd,$3A) & $01                                                    ' wait for new data (based on sampling rate and digital low-pass filtering registers)
    I2C.read_page(mpuAdd,$3B,@array,14)
    I2C.read(mpuAdd,$3B)
    
    acc[0]  := ~array[0] << 8 | array[1]' - ACC_X_CAL                             ' The accelerometer and gyroscope values are read as big-endians
    acc[1]  := ~array[2] << 8 | array[3]'  - ACC_Y_CAL
    acc[2]  := ~array[4] << 8 | array[5]'  - ACC_Z_CAL

    temperature   := ~array[6] << 8 | array[7] / 340 + 35                              ' Convert Temp into °c, formula if from the register map document

    
    gyro[0] := ~array[8] << 8 | array[9] - gyroBias[0]          
    gyro[1] := ~array[10] << 8 | array[11] - gyroBias[1]        
    gyro[2] := ~array[12] << 8 | array[13] - gyroBias[2]

     return true
    

PUB getAk8

  longfill(@mag[0],0,3)                                                          ' Clear the mag registers

  repeat 1                                                                     ' Average 16 samples together
    I2C.write(ak8Add,$0A,$01)                                                      ' Perform single measurement by setting mode to 1 in control register $0A
    repeat until (I2C.read(ak8Add,$02) & $01)                                      ' Check data ready bit in status1 register
    I2C.read_page(ak8Add,$03,@array2,6)
    mag[0] += ~array2[1] << 8 | array2[0]                                          ' The magnetometer values are read as little-endians
    mag[1] += ~array2[3] << 8 | array2[2]
    mag[2] += ~array2[5] << 8 | array2[4]

'  mag[0] ~>= 4                                                                   ' Divide by 16 while preserving the sign
'  mag[1] ~>= 4
'  mag[2] ~>= 4

  mag[0] := (mag[0] * asax + 64 ) / 128 + mag[0]                                         ' Apply the adjustment values 
  mag[1] := (mag[1] * asay + 64 ) / 128 + mag[1]                                         ' Hadj = (H x (ASA - 128) / 2) / 128 + H     
  mag[2] := (mag[2] * asaz + 64 ) / 128 + mag[2]


          