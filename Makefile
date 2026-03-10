.PHONY: project open clean

project:
	xcodegen generate

open: project
	open PrayerTimes.xcodeproj

clean:
	rm -rf PrayerTimes.xcodeproj
	rm -rf DerivedData
