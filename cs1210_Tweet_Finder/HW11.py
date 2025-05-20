def hawkID():
    return("Nicholas Floyd")
    
import tkinter
import math
import ssl
from urllib.request import urlopen, urlretrieve
from urllib.parse import urlencode, quote_plus
import json

import sys
sys.path.insert(0,'./modulesForOAuth')
import requests
from requests_oauthlib import OAuth1
from urllib.parse import quote_plus
import webbrowser

import os
GOOGLEAPIKEY = os.getenv("GOOGLEAPIKEY")
API_KEY = os.getenv("API_KEY")
API_SECRET = os.getenv("API_SECRET")
ACCESS_TOKEN = os.getenv("ACCESS_TOKEN")
ACCESS_TOKEN_SECRET = os.getenv("ACCESS_TOKEN_SECRET")

#
# In HW10 and 11, you will use two Google services, Google Static Maps API
# and Google Geocoding API.  Both require use of an API key.
# 
# When you have the API key, put it between the quotes in the string below

# To run the HW10 program, call the last function in this file: HW10().

# The Globals class demonstrates a better style of managing "global variables"
# than simply scattering the globals around the code and using "global x" within
# functions to identify a variable as global.
#
# We make all of the variables that we wish to access from various places in the
# program properties of this Globals class.  They get initial values here
# and then can be referenced and set anywhere in the program via code like
# e.g. Globals.zoomLevel = Globals.zoomLevel + 1
#

    
class Globals:
   rootWindow = None
   mapLabel = None
   
   defaultLocation = "Mt. Fuji, Japan"
   mapLocation = defaultLocation
   mapFileName = 'googlemap.gif'
   mapSize = 400
   zoomLevel = 9
   mapType = 'roadmap'
   
   tweetText = None
   tweetName = None
   screenName = None
   entireString = ''
   
   
# Given a string representing a location, return 2-element tuple
# (latitude, longitude) for that location 
#
# See https://developers.google.com/maps/documentation/geocoding/
# for details about Google's geocoding API.
#
#
def geocodeAddress(addressString):
   urlbase = "https://maps.googleapis.com/maps/api/geocode/json?address="
   geoURL = urlbase + quote_plus(addressString)
   geoURL = geoURL + "&key=" + GOOGLEAPIKEY

   # required (non-secure) security stuff for use of urlopen
   ctx = ssl.create_default_context()
   ctx.check_hostname = False
   ctx.verify_mode = ssl.CERT_NONE
   
   stringResultFromGoogle = urlopen(geoURL, context=ctx).read().decode('utf8')
   jsonResult = json.loads(stringResultFromGoogle)
   if (jsonResult['status'] != "OK"):
      print("Status returned from Google geocoder *not* OK: {}".format(jsonResult['status']))
      result = (0.0, 0.0) # this prevents crash in retrieveMapFromGoogle - yields maps with lat/lon center at 0.0, 0.0
   else:
      loc = jsonResult['results'][0]['geometry']['location']
      result = (float(loc['lat']),float(loc['lng']))
   return result

# Contruct a Google Static Maps API URL that specifies a map that is:
# - is centered at provided latitude lat and longitude long
# - is "zoomed" to the Google Maps zoom level in Globals.zoomLevel
# - Globals.mapSize-by-Globals.mapsize in size (in pixels), 
# - will be provided as a gif image
#
# See https://developers.google.com/maps/documentation/static-maps/
#
# YOU WILL NEED TO MODIFY THIS TO BE ABLE TO
# 1) DISPLAY A PIN ON THE MAP
# 2) SPECIFY MAP TYPE - terrain vs road vs ...
#
def getMapUrl():
   args = ""
   lat, lng = geocodeAddress(Globals.mapLocation)
   urlbase = "http://maps.google.com/maps/api/staticmap?"
   args = "center={},{}&zoom={}&size={}x{}&format=gif&maptype={}".format(lat,lng,Globals.zoomLevel,Globals.mapSize,Globals.mapSize,Globals.mapType)
   args = args + "&key=" + GOOGLEAPIKEY
   args = args + Globals.entireString
   mapURL = urlbase + args
   return mapURL

# Retrieve a map image via Google Static Maps API, storing the 
# returned image in file name specified by Globals' mapFileName
#
def retrieveMapFromGoogle():
   url = getMapUrl()
   urlretrieve(url, Globals.mapFileName)

########## 
#  basic GUI code

def displayMap():
   retrieveMapFromGoogle()    
   mapImage = tkinter.PhotoImage(file=Globals.mapFileName)
   Globals.mapLabel.configure(image=mapImage)
   # next line necessary to "prevent (image) from being garbage collected" - http://effbot.org/tkinterbook/label.htm
   Globals.mapLabel.mapImage = mapImage
   
   
   
def readEntryAndDisplayMap():
   global tweets
   global search
   #### you should change this function to read from the location from an Entry widget
   #### instead of using the default location
   loc = locationEntry.get()
   Globals.mapLocation = loc
   displayMap()
   search = searchEntry.get()
   tweets = searchTwitter(search, latlngcenter = geocodeAddress(Globals.mapLocation))
   sortTweets()
   initsliderChanged()
   
   
def sortTweets():
    global tweetText
    global tweetName
    global screenName
    global tweetGeo
    global urls
    global url
    Globals.tweetText=[]
    Globals.tweetName=[]
    Globals.screenName=[]
    Globals.tweetGeo=[]
    Globals.urls=[]
    Globals.url=[]
    
    for i in range(len(tweets)):
        if i == 100:
            break
        Globals.tweetText.append(tweets[i]["text"])
        Globals.tweetName.append(tweets[i]["user"]['name'])
        Globals.screenName.append(tweets[i]['user']["screen_name"])
        Globals.urls.append(tweets[i]['entities']['urls'])
        try:
            Globals.url.append(Globals.urls[i][0]['url'])
        except:
            Globals.url.append("No URL")
        #print(tweets[i]['geo']['coordinates'])
        #print(tweets)
        try:
            Globals.tweetGeo.append(tweets[i]["geo"]['coordinates'])
            
        except:
            Globals.tweetGeo.append(geocodeAddress(Globals.mapLocation))
        
        
   # return(Globals.tweetText,Globals.tweetName, Globals.screenName,Globals.tweetGeo,Globals.urls)
        
    
     
def initializeGUIetc():
   Globals.rootWindow = tkinter.Tk()
   Globals.rootWindow.title("HW11")
   Globals.choiceVar = tkinter.IntVar()
   mainFrame = tkinter.Frame(Globals.rootWindow) 
   mainFrame.pack()
   global valueSlider
   global valueLabel
   global locationEntry
   global searchEntry
   global text1
   global urltext
   
   label1 = tkinter.Label(Globals.rootWindow, text="Enter location: ")
   label1.pack()
   locationEntry = tkinter.Entry(Globals.rootWindow)
   locationEntry.pack()
   
   label2 = tkinter.Label(Globals.rootWindow, text="Enter search term: ")
   label2.pack()
   searchEntry = tkinter.Entry(Globals.rootWindow)
   searchEntry.pack()
   
   
   Globals.valueLabel = tkinter.Label(Globals.rootWindow, text="0")
   Globals.valueLabel.pack()
   
   Globals.valueSlider = tkinter.Scale(Globals.rootWindow, orient=tkinter.HORIZONTAL,
                                       length=300, showvalue = 1,
                                       from_=1, to=2)
   Globals.valueSlider.pack()
   Globals.valueSlider.set(0)
   Globals.valueLabel.configure(text = "Tweet: 0")
   Globals.valueSlider.bind("<ButtonRelease-1>", func=sliderChanged)
   
   
   
   Globals.text1 = tkinter.Label(Globals.rootWindow, text="Tweet")
   Globals.text1.pack()
   
   Globals.urltext = tkinter.Label(Globals.rootWindow, text ="URL", fg="blue")
   Globals.urltext.pack()
   Globals.urltext.bind("<Button-1>", func = openUrl)
   
   
   
   
   increaseZoom = tkinter.Button(Globals.rootWindow, text="+", command=zoomIn)
   increaseZoom.pack()
   decreaseZoom = tkinter.Button(Globals.rootWindow, text="-", command=zoomOut)
   decreaseZoom.pack()
   
   
   roadbut = tkinter.Radiobutton(text="Roadmap", variable = Globals.choiceVar, value = 1, command = radioButtonChosen)
   roadbut.pack()
   satbut = tkinter.Radiobutton(text="Satellite", variable = Globals.choiceVar, value = 2, command = radioButtonChosen)
   satbut.pack()
   terrainbut = tkinter.Radiobutton(text="Terrain", variable = Globals.choiceVar, value = 3, command = radioButtonChosen)
   terrainbut.pack()
   hybridbut = tkinter.Radiobutton(text="Hybrid", variable = Globals.choiceVar, value = 4, command = radioButtonChosen)
   hybridbut.pack()
   
   
   # until you add code, pressing this button won't change the map (except
   # once, to the Beijing location "hardcoded" into readEntryAndDisplayMap)
   # you need to add an Entry widget that allows you to type in an address
   # The click function should extract the location string from the Entry widget
   # and create the appropriate map.
   readEntryAndDisplayMapButton = tkinter.Button(mainFrame, text="Show me the map!", command=readEntryAndDisplayMap)
   readEntryAndDisplayMapButton.pack()
   readEntryAndDisplayMapButton.bind("<ButtonRelease-1>", func=sliderChanged)
   # we use a tkinter Label to display the map image
   Globals.mapLabel = tkinter.Label(mainFrame, width=Globals.mapSize, bd=2, relief=tkinter.FLAT)
   Globals.mapLabel.pack()
   
def openUrl(event):
    newValue = Globals.valueSlider.get()
    #print(newValue)
    #print(Globals.url)
    webbrowser.open_new(Globals.url[newValue])
    
    
def sliderChanged(event):
   newValue = Globals.valueSlider.get() 
   createMarkerString(newValue, Globals.tweetGeo, geocodeAddress(Globals.mapLocation))
   displayMap()
   Globals.valueLabel.configure(text = "Tweet: " + str(newValue) + " of " + str(len(tweets)-1))
   Globals.valueSlider.configure(from_=1, to=(len(tweets)-1))
   #print(newValue)
   Globals.text1.configure(text = Globals.tweetText[newValue] + "| Name: " + Globals.tweetName[newValue] + "| @" + Globals.screenName[newValue])
   Globals.urltext.configure(text = Globals.url[newValue])
def initsliderChanged(): #literally a copy of sliderchanged with no event because I needed the map to update before slider was moved
   #newValue = Globals.valueSlider.get() 
   createMarkerString(0, Globals.tweetGeo, geocodeAddress(Globals.mapLocation))
   displayMap()
   Globals.valueLabel.configure(text = "Tweet: " + str(1) + " of " + str(len(tweets)-1))
   Globals.valueSlider.configure(from_=1, to=(len(tweets)-1))
   Globals.valueSlider.set(0)
   #print(newValue)
   Globals.text1.configure(text = Globals.tweetText[0] + "| Name: " + Globals.tweetName[0] + "| @" + Globals.screenName[0])
   Globals.urltext.configure(text = Globals.url[0])
def radioButtonChosen():
     if Globals.choiceVar.get() == 1:
        Globals.mapType="roadmap"
     elif Globals.choiceVar.get() == 2:
        Globals.mapType="satellite"
     elif Globals.choiceVar.get() == 3:
        Globals.mapType="terrain"
     else:
        Globals.mapType="hybrid"
     displayMap()
def zoomIn():
    Globals.zoomLevel = Globals.zoomLevel + 1
    displayMap()

def zoomOut():
    if Globals.zoomLevel > 0: #If you spam button and don't have this you have to click + like a million times (roughly)
        Globals.zoomLevel = Globals.zoomLevel - 1
    displayMap()

def createMarkerString(currentTweetIndex, tweetLatLonList, mapCenterLatLon):
    global entireString
    red = '&markers=color:red|'
    yellow = '&markers=color:yellow|size:small|'
    entireString = ''
    #print(tweetLatLonList)
    for i in range(len(tweetLatLonList)):
        if (tweetLatLonList[i] == None):
            tweetLatLonList[i] = mapCenterLatLon
    red = red + str(tweetLatLonList[currentTweetIndex][0]) + ',' + str(tweetLatLonList[currentTweetIndex][1]) 
    
    for i in range(len(tweetLatLonList)):
        if(i != currentTweetIndex) and tweetLatLonList[i] != tweetLatLonList[currentTweetIndex]:
            yellow = yellow + (str(tweetLatLonList[i][0])) + ',' + (str(tweetLatLonList[i][1])) + '|'
    Globals.entireString = red + yellow
    return(Globals.entireString)
    
def HW11():
    authTwitter()
    initializeGUIetc()
    displayMap()
    Globals.rootWindow.mainloop()
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    #Below is twitter access code not all is used

# 
# The code in this file won't work until you set up your Twitter Project
# and App at https://developer.twitter.com/en/portal/dashboard
# After you set up the app, copy the four long messy strings and API KEY
# and SECRET and ACCESS TOKEN and SECRET. You don't need the BEARER token.
#



# Quick test that everything is working:
# 1) Add the keys above
# 2) Load file into Python and do
#    >>> authTwitter()
#    >>> getMyRecentTweet()
#    >>> tweets = searchTwitter("party", latlngcenter=(40.758895, -73.985131))
#

# Call this function after starting Python.  It creates a Twitter client object (in variable client)
# that is authorized (based on your account credentials and the keys above) to talk
# to the Twitter API. You won't be able to use the other functions in this file until you've
# called authTwitter()
#
def authTwitter():
    global client
    client = OAuth1(API_KEY, API_SECRET,
                    ACCESS_TOKEN, ACCESS_TOKEN_SECRET)

# Study the documentation at 
# https://developer.twitter.com/en/docs/tweets/search/api-reference/get-search-tweets
# to learn about construction Twitter queries and at
# https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/tweet-object
# the understand the structure of the JSON results returned for search queries
#

# Try:
#      tweets = searchTwitter("finals")
#
# Iowa City's lat/lng is [41.6611277, -91.5301683] so also try:
#      tweets = searchTwitter("Iowa", latlngcenter=[41.6611277, -91.5301683])
#
# To find tweets with location, it's often helpful to search in big cities.
#      E.g. lat/long for Times Square in NYC is (40.758895, -73.985131)
#      tweets = searchTwitter("party", latlngcenter=(40.758895, -73.985131))
#      usually yields several tweets with location detail
#
    

    
    
def searchTwitter(searchString, count = 100, radius = 5, latlngcenter = None): 
    global response
    global query
    
    query = "https://api.twitter.com/1.1/search/tweets.json?q=" + quote_plus(searchString) + "&count=" + str(count)
    # if you want JSON results that provide full text of tweets longer than 140
    # characters, add "&tweet_mode=extended" to your query string.  The
    # JSON structure will be different, so you'll have to check Twitter docs
    # to extract the relevant text and entities.
    #query = query + "&tweet_mode=extended" 
    if latlngcenter != None:
        query = query + "&geocode=" + str(latlngcenter[0]) + "," + str(latlngcenter[1]) + "," + str(radius) + "km"
    
    response = requests.get(query, auth=client)
    resultDict = json.loads(response.text)
    # The most important information in resultDict is the value associated with key 'statuses'
    tweets = resultDict['statuses']
    tweetsWithGeoCount = 0 
    for tweetIndex in range(len(tweets)):
        tweet = tweets[tweetIndex]
        if tweet['coordinates'] != None:
            tweetsWithGeoCount += 1
            print("Tweet {} has geo coordinates.".format(tweetIndex))           
    return tweets
    
    

# sometimes tweets contain emoji or other characters that can't be
# printed in Python shell, yielding runtime errors when you attempt
# to print.  This function can help prevent that, replacing such charcters
# with '?'s.  E.g. for a tweet, you can do print(printable(tweet['text']))
#
def printable(s):
    result = ''
    for c in s:
        result = result + (c if c <= '\uffff' else '?')
    return result

#####

# You don't need the following functions for HW 9. They are just additional
# examples of Twitter API use.
#
def whoIsFollowedBy(screenName):
    global response
    global resultDict
    
    query = "https://api.twitter.com/1.1/friends/list.json?&count=50"
    query = query + "&screen_name={}".format(screenName)
    response = requests.get(query, auth=client)
    resultDict = json.loads(response.text)
    for person in resultDict['users']:
        print(person['screen_name'])
    
def getMyRecentTweets():
    global response
    global data
    global statusList 
    query = "https://api.twitter.com/1.1/statuses/user_timeline.json"
    response = requests.get(query,auth=client)
    statusList = json.loads(response.text)
    for tweet in statusList:
        print(printable(tweet['text']))
        print()