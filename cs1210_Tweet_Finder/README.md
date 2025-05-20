# Tweet Finder

## Description

Tweet Finder is a Python GUI application that uses the **Google Maps API** and the **Twitter API** to visualize tweets near any user-specified location.

Users can enter a location in the GUI, which will:
- Display the location on a Google Map
- Retrieve and analyze up to 100 recent tweets in the surrounding area
- Highlight the currently selected tweet with a **red marker**
- Show all other tweet locations with **yellow markers**

The interface supports:
- Zoom controls
- Map type selection (roadmap, terrain, satellite, hybrid)
- Scrolling through tweets with a slider
- Clicking tweet URLs to open them in the browser

The app authenticates securely with **OAuth1**, and all API keys are managed safely through a `.env` file.

## Skills Gained

This was one of my first major projects at the University of Iowa and taught me how to:
- Use real-world APIs (Google, Twitter)
- Build and manage GUI applications using **Tkinter**
- Handle **JSON**, HTTP requests, and geolocation data
- Integrate multiple services into a cohesive application

## Screenshot

Here’s an example of the generated map with tweet markers:

![Tweet Map Example](https://github.com/user-attachments/assets/ef595ab4-49f0-4194-acdf-eeb61f3b9019)
