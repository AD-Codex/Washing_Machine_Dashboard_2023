# Washing machine

This is a Dashboard setup for Automatic Washing machine. Atmega328p chip was used for the task. 74HC595 shift register used for 7 segment display.

## ------------------------------- Controlling Unit Process --------------------------------------

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
