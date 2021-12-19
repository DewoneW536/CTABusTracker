# CTABusTrackerV3
In this iOS project, I developed an application that utilizes the various functions offered by the Core Location and Map Kit frameworks.
To add onto the original CTATrackerV3 application, this app uses the CTA API to track all buses within a specified geographic location
and will simulate a virtual walk around the area specified within the Chicago area. As the simulation takes place, multiple bus stops
will appear as pins on the Map and will show the name of the bus station, along with the est. time until the next bus will arrive.
## Features
1. Used Core Location to determine user current location and display the location on a map, then displays the information that is most
relevant to the user's current location in the app (i.e nearby stations with buses approaching).
2. Dynamically updates and adjusts the display information of near-by stations and the upcoming buses as the user approaches a bus
station.
3. Utilize the location simulation feature to enhance user experience of the application via creating a simulated route in a GPX file.
## Main Concepts
1. Core Location/CLLocationManager
2. JSON parsing/Web Accesses
3. CTA API utilization
4. MKMapView
5. Virtual Simulation
