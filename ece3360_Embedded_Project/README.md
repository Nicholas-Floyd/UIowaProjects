# ECE:3360 – Automatic AC Project

## Description

In this embedded systems project, my partner Alex Viner and I designed and built an automatic air conditioning control system using the following components:

- **Arduino Uno (ATMega328P microcontroller)**
- **AHT20** temperature and humidity sensor
- **DS1307 RTC** with a 32.768kHz crystal
- **1602 LCD display**
- **CPU fan**
- **Potentiometer and pushbutton**

The system reads both real-time clock (RTC) and ambient temperature values, and displays the current and set temperature on the LCD screen.

### Key Features

- **Temperature Control:** The user can adjust the set temperature using the potentiometer. The system compares this with the measured temperature and turns the fan on/off accordingly.
- **RTC Scheduling:** Users can set start/stop times for the AC system via the Arduino IDE.
- **Manual Override:** The pushbutton enables manual on/off control independent of the schedule or temperature logic.
- **Interactive Menu:** The Arduino IDE interface provides options for setting time, scheduling AC operation, and managing system behavior.

More details about the design and implementation can be found in the project report:
📄 [`EmbeddedProjectReport.pdf`](EmbeddedProjectReport.pdf)

> 🎥 If you'd like a video demo of the system in action, feel free to contact me at **nicholasafloyd@gmail.com**.
