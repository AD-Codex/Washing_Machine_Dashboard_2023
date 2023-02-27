# Washing machine

This is a Dashboard setup for Automatic Washing machine. Atmega328p chip was used for the task. 74HC595 shift register used for 7 segment display.

Youtube Link - https://youtu.be/mjMhEYf4CbU

![Screenshot (28) copy](https://user-images.githubusercontent.com/126350818/221586056-50a6d41e-8dff-4f25-a6ea-87ef66f4b395.jpg)


## Function
    1.  7 segment Display
    2.  EEPROM capability
    3.  Time counter
    4.  Error visibility

## Controlling Unit Process

    1.  In main menu "HI" display in the 7 segment
    2.  Close the machine door
    3.  Select the water level
    4.  Press the start button
    5.  If "E0" display door is not closed
    6.  Else Water inlet solenoid will activate
    7.  After water level detect inlet solenoid deactivate
    8.  Washing time display in 7segment
    9.  Press start button to stop the process
    10. Reset button reset the count
    11. To jump main menu press reset and start button
    12. After the washing process outlet solenoid activate
    13. Buzzer will activate
    14. Press start button to jump main menu
