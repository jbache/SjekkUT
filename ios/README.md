# Sjekk UT for iOS

To build, ensure Cocoapods is installed, then run

`pod install`
   
and open Opptur.xcworkspace

To release a new build, run the 

`release.sh`

script. If this succeeds, it will tag the release and upload to hockeyapp.

Custom URL for API can be defined by setting the OPPTUR_API_URL environment variable (e.g. in the Scheme debug arguments section)..
