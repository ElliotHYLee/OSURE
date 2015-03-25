{{Parallax Serial Terminal Plus.spin

This object is made for direct use with the
Parallax Serial Terminal; a simple serial
communication program available with the
Propeller Tool installer and also separately
via the Parallax website (www.parallax.com).

See end of file for author, version,
copyright and terms of use.

This object launches a cog for 2-way,
high speed communication with Parallax
Serial Terminal software that you can run
on your PC.  It launches as soon as you call
one of its methods, with settings that match
the Parallax Serial Terminal's defaults.

You can also call the Start Method for
a different baud rate, or StartRxTx for
custom configurations.

Examples in each method's documentation
assume that this object was declared in a
program and nicknamed pst, with the system
clock set to run at 80 MHz using the
Propeller Baord of Education's 5 MHz
crystal oscillator.  Like this:

Example Program with pst Nickname
┌──────────────────────────────────────────┐
│''Hello message to Parallax Serial        │
│''Terminal                                │
│OJB                                       │
│ pst : "Parallax Serial Terminal Plus"    │
│ system: "Propeller Board of Education"   │
│                                          │
│PUB Go                                    │
│ system.Clock(80_000_000)  '80 Mhz clock  │
│ pst.Str(string("Hello!")) 'Message to PST│
└──────────────────────────────────────────┘

IMPORTANT: Make sure to click the Parallax 
           Serial Terminal's Enable button,
           either while the program is 
           loading or within 1 second    
           afterwards.  Otherwise, you will
           miss the message.
}}

CON
''
''     Parallax Serial Terminal
''    Control Character Constants
''─────────────────────────────────────
  CS = 16  ''CS: Clear Screen      
  CE = 11  ''CE: Clear to End of line     
  CB = 12  ''CB: Clear lines Below 

  HM =  1  ''HM: HoMe cursor       
  PC =  2  ''PC: Position Cursor in x,y          
  PX = 14  ''PX: Position cursor in X         
  PY = 15  ''PY: Position cursor in Y         

  NL = 13  ''NL: New Line        
  LF = 10  ''LF: Line Feed       
  ML =  3  ''ML: Move cursor Left          
  MR =  4  ''MR: Move cursor Right         
  MU =  5  ''MU: Move cursor Up          
  MD =  6  ''MD: Move cursor Down
  TB =  9  ''TB: TaB          
  BS =  8  ''BS: BackSpace          
           
  BP =  7  ''BP: BeeP speaker          

CON

  BUFFER_LENGTH = 64                                    ' Recommended as 64 or higher, but can be 2, 4, 8, 16, 32, 64, 128 or 256.
  BUFFER_MASK   = BUFFER_LENGTH - 1
  MAXSTR_LENGTH = 49                                    ' Maximum length of received numerical string (not including zero terminator).

  #1, _Start, _StartRxTx, _Stop, _Border, _Char,      {
  }   _Chars, _Charin, _Str, _StrIn, _StrInMax, _Dec, {
  }   _DecIn, _Bin, _BinIn, _Hex, _HexIn, _Clear,     {
  }   _ClearEnd, _ClearBelow, _Home, _Position,       {
  }   _PositionX, _PositionY, _NewLine, _LineFeed,    {
  }   _MoveLeft, _MoveRight, _MoveUp, _MoveDown,      {
  }   _Tab, _BackSpace, _Beep, _RxCount, _RxFlush,    {
  }   _LockTransmit, _UnlockTransmit, _LockReceive,   {
  }   _UnlockIn 
  
VAR                                                     ' This object instance's 
                                                        ' variables                        
  long        ObjTxLock, methTxLock 
  long        objRxLock, methRxLock
  long        txMethod, rxMethod
  long        xHome, yHome, xEnd, yEnd
  long        _x, _y
  long        winMode, tabcnt, cxy, cx, cy
  
DAT                                                     ' Variables shared with
                                                        ' all object instances
  txLockID    long  0
  rxLockID    long  0

  cog         long  0                                   ' Cog flag/id

  rx_head     long  0                                   ' 9 contiguous longs (must keep order)
  rx_tail     long  0  
  tx_head     long  0  
  tx_tail     long  0  
  rx_pin      long  0  
  tx_pin      long  0  
  rxtx_mode   long  0  
  bit_ticks   long  0  
  buffer_ptr  long  0  
                     
  rx_buffer   byte  0 [BUFFER_LENGTH]                   ' Receive and transmit buffers
  tx_buffer   byte  0 [BUFFER_LENGTH]     
  str_buffer  byte  0 [MAXSTR_LENGTH+1]                 ' String buffer for numerical strings

PUB Start(baudrate) : okay
{{Start communication with the Parallax
Serial Terminal using the Propeller's
programming connection.
Waits 1 second for connection, then clears
screen.

IMPORTANT: You do not need to call this
method if you just want to send messages
to the Parallax Serial Terminal at its
default baudrate of 115.2 kbps.  Any
method call will call this start method
with the default buad rate if it has not
allready been called.

Parameters:
  baudrate - bits per second.  Make sure it
  matches the Parallax Serial Terminal's
  Baud Rate field.

Returns:
  True (non-zero) if cog started
  False (0) if no cog is available.

Example:
  'Start communication with the
  'Parallax Serial Terminal at a baud
  'rate of 115.2 kbps.

  pst.Start(115_2000)  
}}
  okay := StartRxTx(31, 30, 0, baudrate)
  waitcnt(clkfreq + cnt)                                ' Wait 1 second for PST
  Clear                                                 ' Clear display

PUB StartRxTx(rxpin, txpin, mode, baudrate) : okay
{{Start serial communication with designated
pins, mode, and baud.

Parameters:
  rxpin    - input pin; receives signals
             from external device's TX pin.
  txpin    - output pin; sends signals to
             external device's RX pin.
  mode     - signaling mode (4-bit pattern).
             bit 0 - inverts rx.
             bit 1 - inverts tx.
             bit 2 - open drain/source tx.
             bit 3 - ignore tx echo on rx.
  baudrate - bits per second.

Returns:
  True (non-zero) if cog started
  False (0) if no cog is available.

Example:
  'Start communication with the
  'Parallax Serial Terminal at a baud
  'rate of 115.2 kbps using the serial
  'programming and communication pins.

  pst.StartRxTx(31,30,0,115_200)
}}

  stop

  if (txLockId := locknew) == -1
    return 0
  if (rxLockId := locknew) == -1
    return 0
      
  longfill(@rx_head, 0, 4)
  longmove(@rx_pin, @rxpin, 3)
  bit_ticks := clkfreq / baudrate
  buffer_ptr := @rx_buffer
  tabcnt := 8  
  okay := cog := cognew(@entry, @rx_head) + 1

PUB Stop
{{Stop serial communication; frees a cog.}}

  if cog
    cogstop(cog~ - 1)  
  longfill(@rx_head, 0, 9)

  if txLockId <> -1
    lockclr(txLockId~~)
  if rxLockId <> -1
    lockclr(rxLockId~~)

PUB Box(xLeft, yTop, width, height)
{{Define a box for this object instance.

Parameters:
  xLeft  - leftmost "home" character position
  yTop   - topmost "home" character position
  width  - width of box in characters
  height - height of box in carriage returns

Example: Define a ten character wide by four
         carrige return high box with a top-left
         corner two characeters over and three
         carriage returns down.

         pst.Box(2, 3, 10, 4)
}}

  ifnot cog
    start(115_200)

  xHome   := xLeft
  yHome   := yTop
  xEnd    := xHome + width
  yEnd    := yTop + height
  tabcnt  := 8
  winMode := true

PUB NoBox
{{Stop constraining text displayed by the
Parallax Serial Terminal in a box.}}

  ifnot cog
    start(115_200)

  winMode := false

PUB Border(bytechr, padding) | i
{{Please a border around a box that has been
defined by a call to the Box method.

Parameters:
  bytechr - character used to display the border
  padding - number of empty spaces between box edge
            and border and number of carriage returns
            between box top/bottom and border.

Example: Place a border around your box with the "*"
         character with two space/carriage return
         padding.

         pst.Border("*", 2)

Note: Make sure to call the Box method before you
      call this one.                     
}}

  LockTX(_Border)

  ifnot cog
    start(115_200)

  tx(2)
  tx((xHome-padding) #> 0)
  tx((yHome-padding) #> 0)
  
  repeat i from ((xhome-padding)#>0) to ((xend+padding)#>0)
    tx(2)
    tx(i)
    tx(yHome-padding)
    tx(byteChr)
    tx(2)
    tx(i)
    tx(yEnd+padding)
    tx(byteChr)
    
  repeat i from ((yhome-padding)#>0) to ((yend+padding)#>0)
    tx(2)
    tx(xhome-padding)
    tx(i)
    tx(byteChr)
    tx(2)
    tx(xEnd+padding)
    tx(i)
    tx(byteChr)

  Home

  UnlockTX(_Border)

PUB ChangeTab(charcnt)
{{Change the number of characters in a tab.
The default is 8 characters per tab.

Parameter:
  charcnt - number of characters in a tab.
}}

  tabcnt := charcnt

PUB Char(bytechr) | i, j
{{Send single-byte character.  Waits for
room in transmit buffer if necessary.

Parameter:
  bytechr - character (ASCII byte value)
            to send.

Eamples:
  'Send "A" to Parallax Serial Terminal
  pst.Char("A")
  'Send "A" to Parallax Serial Terminal
  'using its ASCII value
  pst.Char(65)              
}}

  ifnot cog
    start(115_200)

  LockTx(_Char)
  
  if winMode <> true
    tx(bytechr)
  else
    if cxy==1
      _x := ((bytechr + xHome) {#> xhome <# xend})
      tx(_x)
      cxy:=2
    elseif cxy==2
      _y := ((bytechr + yHome) {#> yhome <# yend})
      tx(_y)
      cxy := 0
    elseif cx==1
      _x := (bytechr+xhome) '#> xhome <# xend
      tx(_x)
      cx := 0
    elseif cy==1
      _y := (bytechr+yhome) '#> xhome <# xend
      tx(_y)
      cy := 0
    else
      case bytechr
        0, CS:                                            ' Clear Screen
          repeat _y from yHome to yEnd
            repeat _x from xHome to xEnd
              tx(PC)
              tx(_x)
              tx(_y)
              tx(" ")
          tx(PC)
          tx(_x:=xHome)
          tx(_y:=yHome)    
        HM:                                                ' Home Cursor
          tx(PC)
          tx(xHome)
          tx(yHome)
          _x := xhome
          _y := yhome
        PC:                                                ' Position Cursor(x,y)
          tx(byteChr)
          cxy:=1
        ML:                                                ' Move Cursor Left
          if _x > xHome
            tx(bytechr)
            _x-- 
        MR:                                                ' Move Cursor Right
          if _x < xEnd
            tx(bytechr)
            _x++
        MU:                                                ' Move Cursor Up
          if _y > yHome
            tx(bytechr)
            _y-- 
        MD:                                                ' Move Cursor Down
          if _y < yEnd
            tx(bytechr)
            _y++
  '     BP:                                                ' Beep Speaker
        BS:                                                ' Backspace
          if _x > xHome
            tx(bytechr)
            _x--
        TB:                                                ' Tab
          if (_x + tab) < xEnd
            tx(byteChr)
            _x += tab
          else
            repeat (xEnd - _x)
              tx(4)
            _x := xEnd    
        LF:                                               ' Line Feed
          if _y < yEnd
            tx(byteChr)
            _y+=1
        CE:                                               ' Clear to End of Line
          if _x < xEnd
            repeat (xEnd - _x)
              tx(" ")
            tx(PX)
            tx(_x)  
        CB:                                               ' Clear Lines Below
          if _y < yEnd
          _x:=xHome
          _y++
          i := _x
          j := _y
          repeat ((yEnd-_y)*(xEnd-xHome))
            if _x =< xEnd
            elseif _y < yEnd
              _x := xHome
              _y ++
            else
              _x := xHome
              _y := yHome
            tx(PC)
            tx(_x++)
            tx(_y)
            tx(" ")
          _x := i
          _y := j  
          tx(PC)
          tx(_x)
          tx(_y)  
        NL:                                               ' New Line
          if _y < yEnd
            tx(PC)
            tx(_x:=xHome)
            tx(++_y)
        PX:                                               ' Position Cursor(x)
          cx:=1
          tx(byteChr)
        PY:                                               ' Position Cursor(y)
          cy:=1
          tx(byteChr)
        other:
          if _x =< xEnd
          elseif _y < yEnd
            _x:=xHome
            _y++
          else
            _x := xHome
            _y := yHome
          tx(PC)
          tx(_x++)
          tx(_y)
          tx(bytechr)
           
  UnlockTx(_Char)

PUB Chars(bytechr, count)
{{Send multiple copies of a single-byte
character. Waits for room in transmit buffer
if necessary.

Parameters:
  bytechr - character (ASCII byte value) to
            send.
  count   - number of bytechrs to send.

Example:
  'Send "AAAAA" to Parallax Serial Terminal
  pst.Chars("A", 5)
}}
 
  ifnot cog
    start(115_200)

  LockTx(_Chars)

  repeat count
    Char(bytechr)

  UnlockTx(_Chars)


PUB CharIn : bytechr
{{Receive single-byte character.  Waits
until character received.

Returns:
  A byte value (0 to 255) which
  represents a character that has been typed 
  into the Parallax Serial Terminal.

Example:
  ' Get a character that is typed into the
  ' Parallax Serial Terminal, and copy it to
  ' a variable named c.
  c := pst.CharIn
}}

  ifnot cog
    start(115_200)

  LockRx(_CharIn)

  repeat while (bytechr := RxCheck) < 0

  UnlockRx(_CharIn)

PUB Str(stringptr)
{{Send zero terminated string.
Parameter:
  stringptr - pointer to zero terminated
              string to send.

Examples:
  ''Send string with String operator.
  pst.Str(String("Hello!"))

  ''Send string from DAT block
  '...code omitted
  PUB Go
    pst.Str(@myDatString)
  DAT
    myDatString byte "abcdefg", 0
    '                           
    '        Zero terminator ───┘
}}

  ifnot cog
    start(115_200)

  LockTx(_Str)

  repeat strsize(stringptr)
    Char(byte[stringptr++])

  UnlockTx(_Str)

PUB StrIn(stringptr)
{{Receive a string (carriage return
terminated) and stores it  (zero terminated)
starting at stringptr.  Waits until full
string received.
Parameter:
  stringptr - pointer to memory in which to
    store received string characters.
    Memory reserved must be large enough for
    all string characters plus a zero
    terminator.

Example:

  ' Get a string that's up to 100 characters
  ' long (including zero terminator) from
  ' the Parallax Serial Terminal.
  '...code omitted
  VAR
    byte mystr(100)
  PUB Go
    '... code omitted
    pst.StrIn(@mystr)
}}
  
  ifnot cog
    start(115_200)

  LockRx(_StrIn)

  StrInMax(stringptr, -1)

  UnlockRx(_StrIn)

PUB StrInMax(stringptr, maxcount)
{{Receives a string of characters (either
carriage return terminated or maxcount in
length) and stores it (zero terminated)
starting at stringptr.  Waits until either
full string received or maxcount characters
received.

Parameters:
  stringptr - pointer to memory in which to
  store received string characters. Memory
  reserved must be large enough for all
  string characters plus a zero terminator
  (maxcount + 1).  maxcount  - maximum
  length of string to receive, or -1 for
  unlimited.

Example:
  ' Get a string that's up to 100 characters
  ' long (including zero terminator) from
  ' the Parallax Serial Terminal.  ...and
  ' make sure that the string buffer isn't
  ' overloaded.
  '...code omitted
  VAR
    byte mystr(100)
  PUB Go
    '... code omitted
    pst.StrInMax(@mystr, 99)
}}
    
  ifnot cog
    start(115_200)

  LockRx(_StrInMax)

  repeat while (maxcount--)                                                     'While maxcount not reached
    if (byte[stringptr++] := CharIn) == NL                                      'Get chars until NL
      quit
  byte[stringptr+(byte[stringptr-1] == NL)]~                                    'Zero terminate string; overwrite NL or append 0 char

  UnlockRx(_StrInMax)

PUB Dec(value) | i, x
{{Send value as decimal characters.
Parameter:
  value - byte, word, or long value to
  send as decimal characters.
 
Examples:

  'Display 100 in Parallax Serial Terminal
  pst.Dec(100)

  'Display variable value as decimal in
  'Parallax Serial Terminal.
  '...code omitted
  VAR
    long val
  PUB Go
    '... code omitted
    val := 100
    pst.Dec(val)
}}

  ifnot cog
    start(115_200)

  LockTx(_Dec)

  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative
    Char("-")                                                                   'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i                                                               
      Char(value / i + "0" + x*(i == 1))                                        'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      Char("0")                                                                 'If zero digit (or only digit) output it
    i /= 10                                                                     'Update divisor

  UnlockTx(_Dec)

PUB DecIn : value
{{Receive carriage return terminated string
of characters representing a decimal value.

Returns: the corresponding decimal value.

Example:

  ' Get a decimal value that is typed into
  ' the Parallax Serial Terminal's
  ' Transmit windowpane.
  '...code omitted
  VAR
    long val
  PUB Go
    '...code omitted
    val := pst.DecIn
  }}

  ifnot cog
    start(115_200)
    
  LockRx(_DecIn)
    
  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 10)

  UnlockRx(_DecIn)

PUB Bin(value, digits)
{{Send value as binary characters up to
digits in length.

Parameters:
  value  - byte, word, or long value to send
           as binary characters.
  digits - number of binary digits to send.
           Will be zero padded if necessary.

Examples:

  'Display decimal-10 as a binary value in
  'the Parallax Serial Terminal.  The result
  'should be 1010, which is binary for 10.
  pst.Bin(10, 4)

  'Display variable value as binary in
  'Parallax Serial Terminal.  Also, try
  'val := %1010.  The % operator means you
  'are using a binary value instead of a
  'decimal one.
  '...code omitted
  VAR
    long val
  PUB Go
    '... code omitted
    val := 10
    pst.Bin(val, 4)
}}
   
  ifnot cog
    start(115_200)

  LockTx(_Bin)
    
  value <<= 32 - digits
  repeat digits
    Char((value <-= 1) & 1 + "0")

  UnlockTx(_Bin)

PUB BinIn : value
{{Receive carriage return terminated string
of characters representing a binary value.

Returns:
  the corresponding binary value.

Example:

  ' Get a binary value that is typed into
  ' the Parallax Serial Terminal's
  ' Transmit windowpane.
  '...code omitted
  VAR
    long val
  PUB Go
    '...code omitted
    val := pst.BinIn
}}
   
  ifnot cog
    start(115_200)
    
  LockRx(_BinIn)

  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 2)

  UnlockRx(_BinIn)
   
PUB Hex(value, digits)
{{Send value as hexadecimal characters up to
digits in length.
Parameters:
  value  - byte, word, or long value to send
           as hexadecimal characters.
  digits - number of hexadecimal digits to
           send.  Will be zero padded if
           necessary.

Examples:

  'Display decimal-10 as a hexadecimal value
  'in the Parallax Serial Terminal.  The
  'result should be the hexadecimal 0A.
  pst.Hex(10, 2)

  'Display variable value as hexadecmial in
  'Parallax Serial Terminal.  Also, try
  'val := $A.  The $ operator means you
  'are using a hexadecimal value instead of
  'a decimal one.
  '...code omitted
  VAR
    long val
  PUB Go
    '... code omitted
    val := 10
    pst.Hex(val, 2)
}}
 
  ifnot cog
    start(115_200)

  LockTx(_Hex)
    
  value <<= (8 - digits) << 2
  repeat digits
    Char(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

  UnlockTx(_Hex)

PUB HexIn : value
{{Receive carriage return terminated string
of characters representing a hexadecimal
value.
  Returns: the corresponding hexadecimal
  value.

Example:

  ' Get a binary value that is typed into
  ' the Parallax Serial Terminal's
  ' Transmit windowpane.
  '...code omitted
  VAR
    long val
  PUB Go
    '...code omitted
    val := pst.BinIn
}}

  ifnot cog
    start(115_200)
    
  LockRx(_HexIn)

  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 16)

  UnlockRx(_HexIn)

PUB Clear
{{Clear screen and place cursor at top-left.

Example:
  pst.Clear
}}
  
  ifnot cog
    start(115_200)

  LockTx(_Clear)
    
  Char(CS)

  UnlockTx(_Clear)
  

PUB ClearEnd
{{Clear line from cursor to end of line.

Example:
  pst.ClearEnd
}}
  
  ifnot cog
    start(115_200)

  LockTx(_ClearEnd)
    
  Char(CE)

  UnlockTx(_ClearEnd)
  
PUB ClearBelow
{{Clear all lines below cursor.

Example:
  pst.ClearBelow
}}
  
  ifnot cog
    start(115_200)

  LockTx(_ClearBelow)
    
  Char(CB)

  UnlockTx(_ClearBelow)
  
PUB Home
{{Send cursor to home position (top-left).

Example:
  pst.Home
}}
  
  ifnot cog
    start(115_200)

  LockTx(_Home)
    
  Char(HM)

  UnlockTx(_Home)
  
PUB Position(x, y)
{{Position cursor at column x, row y (from
top-left).

Example:
  'Position cursor 5 spaces to the right
  'and 6 carriage returns from the top.
  pst.Position(5, 6)
}}
  
  ifnot cog
    start(115_200)

  LockTx(_Position)

  Char(PC)
  Char(x)
  Char(y)

  UnlockTx(_Position)
  
PUB PositionX(x)
{{Position cursor at column x of current row.

Example:
  'Position cursor 5 spaces to the right in
  'whatever row the cursor is located.
  pst.PositionX(5)
}}

  ifnot cog
    start(115_200)

  LockTx(_PositionX)
    
  Char(PX)
  Char(x)

  UnlockTx(_PositionX)
  
PUB PositionY(y)
{{Position cursor at row y of current column.
Example:
  'Position cursor 6 carriage returns down
  'from its current position.
  pst.PositionY(6)
}}

  ifnot cog
    start(115_200)

  LockTx(_PositionY)
    
  Char(PY)
  Char(y)

  UnlockTx(_PositionY)

PUB NewLine
{{Send cursor to new line (carriage return
plus line feed).}}
  
  ifnot cog
    start(115_200)

  LockTx(_NewLine)
    
  Char(NL)

  UnlockTx(_NewLine)
  
PUB LineFeed
{{Send cursor down to next line.

Example:
  pst.LineFeed
}}
  
  ifnot cog
    start(115_200)

  LockTx(_LineFeed)
    
  Char(LF)

  UnlockTx(_LineFeed)
  
PUB MoveLeft(x)
{{Move cursor left x characters.

Example:
  'Move cursor 3 characters to the left.
  pst.MoveLeft(3)
}}
  
  ifnot cog
    start(115_200)

  LockTx(_MoveLeft)
    
  repeat x
    Char(ML)

  UnlockTx(_MoveLeft)
  
PUB MoveRight(x)
{{Move cursor right x characters.

Example:
  'Move cursor 3 characters to the right.
  pst.MoveRight(3)
}}
  
  ifnot cog
    start(115_200)

  LockTx(_MoveRight)
    
  repeat x
    Char(MR)

  UnlockTx(_MoveRight)
  
PUB MoveUp(y)
{{Move cursor up y lines.

Example:
  'Move cursor 3 lines upward.
  pst.MoveUp(3)
}}
  
  ifnot cog
    start(115_200)

  LockTx(_MoveUp)
    
  repeat y
    Char(MU)

  UnlockTx(_MoveUp)
  
PUB MoveDown(y)
{{Move cursor down y lines.

Example:
  'Move cursor 3 lines down.
  pst.MoveDown(3)
}}
  
  ifnot cog
    start(115_200)

  LockTx(_MoveDown)
    
  repeat y
    Char(MD)

  UnlockTx(_MoveDown)
  
PUB Tab
{{Send cursor to next tab position.

Example:
  pst.Tab
}}

  LockTx(_Tab)
    
  ifnot cog
    start(115_200)

  Char(TB)

  UnlockTx(_Tab)
  
PUB Backspace
{{Delete one character to left of cursor and
move cursor there.

Example:
  pst.Backspace
}}
  
  ifnot cog
    start(115_200)

  LockTx(_Backspace)
    
  Char(BS)

  UnlockTx(_Backspace)
  
PUB Beep
{{Play bell tone on PC speaker.

Example:
  pst.Bell
}}
  
  ifnot cog
    start(115_200)

  LockTx(_Beep)
    
  Char(BP)

  UnlockTx(_Beep)
  
PUB RxCount : count
{{Get count of characters in receive buffer.
  Returns: number of characters waiting in
  receive buffer.

Examples:
  'Store how many characters are in the
  'intput buffer in a variable anmed val.
  '...code omitted
  VAR
    word val
  PUB Go
  '...code omitted
    val := pst.RxCount

  'Clear the buffer if it has more than
  '20 characters
  VAR
    byte mystr(21)
  PUB Go
  '...code omitted
    if pst.RxCount > 20
      pst.MaxStr(@myStr, 20)
  '...       
}}

  ifnot cog
    start(115_200)
    
  LockRx(_RxCount)

  count := rx_head - rx_tail
  count -= BUFFER_LENGTH*(count < 0)

  UnlockRx(_RxCount)

PUB RxFlush
{{Flush receive buffer.

This method can be useful if you know there
will be a bunch of characters in the buffer
that do not matter to your application.  For
example, maybe the first 5 seconds of
characters that get sent don't matter

Example:

  if t > 5
    pst.RxFlush
}}

  ifnot cog
    start(115_200)
    
  LockRx(_RxFlush)

  repeat while rxcheck => 0

  UnlockRx(_RxFlush)
    
PUB LockTransmit

  if objTxLock == false
    repeat until not lockset(txLockId)
    objTxLock := true
    txMethod := _LockTransmit  

PUB UnlockTransmit

  if txMethod == _LockTransmit
    lockclr(txLockId)
    objTxLock := false
    txMethod := 0

PUB LockReceive

  if objRxLock == false
    repeat until not lockset(rxLockId)
    objRxLock := true
    rxMethod := _LockReceive  

PUB UnlockReceive

  if rxMethod == _LockReceive
    lockclr(rxLockId)
    objRxLock := false
    rxMethod := 0

PRI LockTx(methodId)

  if objTxLock == false
    repeat until not lockset(txLockId)
    objTxLock := true
    txMethod := methodID  

PRI UnlockTx(methodID)

  if txMethod == methodID
    lockclr(txLockId)
    objTxLock := false
    txMethod := 0

PRI LockRx(methodID)

  if objRxLock == false
    repeat until not lockset(rxLockId)
    objRxLock := true
    rxMethod := methodID  

PRI UnlockRx(methodID)

  if rxMethod == methodID
    lockclr(rxLockId)
    objRxLock := false
    rxMethod := 0

PRI RxCheck : bytechr
{Check if character received; return immediately.
  Returns: -1 if no byte received, $00..$FF if character received.}

  bytechr~~
  if rx_tail <> rx_head
    bytechr := rx_buffer[rx_tail]
    rx_tail := (rx_tail + 1) & BUFFER_MASK

PRI StrToBase(stringptr, base) : value | chr, index
{Converts a zero terminated string representation of a number to a value in the designated base.
Ignores all non-digit characters (except negative (-) when base is decimal (10)).}

  value := index := 0
  repeat until ((chr := byte[stringptr][index++]) == 0)
    chr := -15 + --chr & %11011111 + 39*(chr > 56)                              'Make "0"-"9","A"-"F","a"-"f" be 0 - 15, others out of range     
    if (chr > -1) and (chr < base)                                              'Accumulate valid values into result; ignore others
      value := value * base + chr                                                  
  if (base == 10) and (byte[stringptr] == "-")                                  'If decimal, address negative sign; ignore otherwise
    value := - value
       
PRI tx(bytechr)

  repeat until (tx_tail <> ((tx_head + 1) & BUFFER_MASK))
  tx_buffer[tx_head] := bytechr
  tx_head := (tx_head + 1) & BUFFER_MASK

  if rxtx_mode & %1000
    CharIn

DAT

'***********************************
'* Assembly language serial driver *
'***********************************

                        org
'
'
' Entry
'
entry                   mov     t1,par                'get structure address
                        add     t1,#4 << 2            'skip past heads and tails

                        rdlong  t2,t1                 'get rx_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                 'get tx_pin
                        rdlong  t2,t1
                        mov     txmask,#1
                        shl     txmask,t2

                        add     t1,#4                 'get rxtx_mode
                        rdlong  rxtxmode,t1

                        add     t1,#4                 'get bit_ticks
                        rdlong  bitticks,t1

                        add     t1,#4                 'get buffer_ptr
                        rdlong  rxbuff,t1
                        mov     txbuff,rxbuff
                        add     txbuff,#BUFFER_LENGTH

                        test    rxtxmode,#%100  wz    'init tx pin according to mode
                        test    rxtxmode,#%010  wc
        if_z_ne_c       or      outa,txmask
        if_z            or      dira,txmask

                        mov     txcode,#transmit      'initialize ping-pong multitasking
'
'
' Receive
'
receive                 jmpret  rxcode,txcode         'run chunk of tx code, then return

                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                        test    rxmask,ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits,#9             'ready to receive byte
                        mov     rxcnt,bitticks
                        shr     rxcnt,#1
                        add     rxcnt,cnt                          

:bit                    add     rxcnt,bitticks        'ready next bit period

:wait                   jmpret  rxcode,txcode         'run chunk of tx code, then return

                        mov     t1,rxcnt              'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc    'receive bit on rx pin
                        rcr     rxdata,#1
                        djnz    rxbits,#:bit

                        shr     rxdata,#32-9          'justify and trim received byte
                        and     rxdata,#$FF
                        test    rxtxmode,#%001  wz    'if rx inverted, invert byte
        if_nz           xor     rxdata,#$FF

                        rdlong  t2,par                'save received byte and inc head
                        add     t2,rxbuff
                        wrbyte  rxdata,t2
                        sub     t2,rxbuff
                        add     t2,#1
                        and     t2,#BUFFER_MASK
                        wrlong  t2,par

                        jmp     #receive              'byte done, receive next byte
'
'
' Transmit
'
transmit                jmpret  txcode,rxcode         'run chunk of rx code, then return

                        mov     t1,par                'check for head <> tail
                        add     t1,#2 << 2
                        rdlong  t2,t1
                        add     t1,#1 << 2
                        rdlong  t3,t1
                        cmp     t2,t3           wz
        if_z            jmp     #transmit

                        add     t3,txbuff             'get byte and inc tail
                        rdbyte  txdata,t3
                        sub     t3,txbuff
                        add     t3,#1
                        and     t3,#BUFFER_MASK
                        wrlong  t3,t1

                        or      txdata,#$100          'ready byte to transmit
                        shl     txdata,#2
                        or      txdata,#1
                        mov     txbits,#11
                        mov     txcnt,cnt

:bit                    test    rxtxmode,#%100  wz    'output bit on tx pin 
                        test    rxtxmode,#%010  wc    'according to mode
        if_z_and_c      xor     txdata,#1
                        shr     txdata,#1       wc
        if_z            muxc    outa,txmask        
        if_nz           muxnc   dira,txmask
                        add     txcnt,bitticks        'ready next cnt

:wait                   jmpret  txcode,rxcode         'run chunk of rx code, then return

                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#:bit          'another bit to transmit?

                        jmp     #transmit             'byte done, transmit next byte
'
'
' Uninitialized data
'
t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

{{
File: Parallax Serial Terminal Plus.spin
Date: 2011.05.12
Version: 1.01 (Andy Lindsay Updates)
  - Does not require a Start method call
  - If a method other than Start is
    called first, this object starts
    automatically, and its settings
    will match the Parallax Serial
    Terminal software's defaults.
Version: 1.02 (Andy Lindsay Updates)
  - Can be incorporated into and used by
    multiple objects and/or cogs.      
  - Box, NoBox, Border, and ChangeTab methods
    added.  This gives library objects the
    ability to display disgnostic info in
    boxes within the Parallax Serial Terminal
    window.  
  - All methods use locks transparently, and
    it is transparent to the object calling.
  - Optional Lock and Unlock methods allow
    an object to give priority to printing
    a block of information.  In most cases,
    it's not necessary because the boxes
    support interleaved messages and keep
    track of their own cursor positions.

Authors: Jeff Martin, Andy Lindsay, Chip Gracey  

This object is heavily based on
FullDuplexSerialPlus (by Andy Lindsay),
which is itself heavily based on
FullDuplexSerial (by Chip Gracey).

Copyright (c) 2009 Parallax, Inc.

┌────────────────────────────────────────────┐
│TERMS OF USE: MIT License                   │
├────────────────────────────────────────────┤
│Permission is hereby granted, free of       │
│charge, to any person obtaining a copy      │
│of this software and associated             │
│documentation files (the "Software"),       │
│to deal in the Software without             │
│restriction, including without limitation   │
│the rights to use, copy, modify,merge,      │
│publish, distribute, sublicense, and/or     │
│sell copies of the Software, and to permit  │
│persons to whom the Software is furnished   │
│to do so, subject to the following          │
│conditions:                                 │
│                                            │
│The above copyright notice and this         │
│permission notice shall be included in all  │
│copies or substantial portions of the       │
│Software.                                   │
│                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT   │
│WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES │
│OF MERCHANTABILITY, FITNESS FOR A           │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN  │
│NO EVENT SHALL THE AUTHORS OR COPYRIGHT     │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR │
│OTHER LIABILITY, WHETHER IN AN ACTION OF    │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM,  │
│OUT OF OR IN CONNECTION WITH THE SOFTWARE   │
│OR THE USE OR OTHER DEALINGS IN THE         │
│SOFTWARE.                                   │
└────────────────────────────────────────────┘
}}

{
PUB Dec2(value) | i, x
{{Send value as decimal characters.
Parameter:
  value - byte, word, or long value to
  send as decimal characters.
 
Examples:

  'Display 100 in Parallax Serial Terminal
  pst.Dec(100)

  'Display variable value as decimal in
  'Parallax Serial Terminal.
  '...code omitted
  VAR
    long val
  PUB Go
    '... code omitted
    val := 100
    pst.Dec(val)
}}

  ifnot cog
    start(115_200)

  LockTx(_Dec)

  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative
    tx("-")                                                                   'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i                                                               
      tx(value / i + "0" + x*(i == 1))                                        'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      tx("0")                                                                 'If zero digit (or only digit) output it
    i /= 10                                                                     'Update divisor

  UnlockTx(_Dec)

}