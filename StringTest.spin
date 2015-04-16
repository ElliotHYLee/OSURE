CON

  _clkmode = xtal1 + pll16x            'defining clock mod
  _xinfreq = 5_000_000

OBJ

  usb : "FullDuplexSerial"
  strConv : "String.spin"
  strOp  : "STRINGS.spin"
Var

  long numberStr
  
PUB main

  usb.quickStart
  repeat
  
    numberStr := strConv.integerToDecimal(3, 3)
    numberStr := strOp.SubStr(numberStr, 1,3)
    usb.str(strOp.combine(numberStr, String(".txt")))
    usb.newline