# -*- coding: utf-8 -*-
require 'rubygems'
require 'eventbrite-client'
require 'json'
require 'pry'
require 'mechanize'

# eventbrite2glimt - Query eventbrite.com for events in Oslo
# and post to the glimt.com
#
# Author: Thomas.Flemming@gmail.com
#
# Eventbrite API Documentation:
#   https://www.eventbrite.com/api/key?app_key=BB6GTX5V3XHGP5NLWA

def create_timezoned_date(start_date, timezone_offset)
  date = DateTime.parse(start_date)
  hours_offset = timezone_offset[/\d+/].to_i / 100
  return date.new_offset(hours_offset.to_f/24)
end

eb_auth_tokens = { app_key: 'BB6GTX5V3XHGP5NLWA', user_key: nil}
eb_client = EventbriteClient.new(eb_auth_tokens)
eb_client.event_search(:city => 'Oslo', :country => 'NO')

events = eb_client.event_search(:city => 'Oslo', :country => 'NO')
number_of_events = events["events"].size

glimt_events = []
events["events"][1..number_of_events].each do |eb_event|
  eb_event = eb_event["event"]
  glimt_event = {}
  puts "Title: '#{eb_event['title']}'"
  glimt_event["venueUrl"]            = nil
  glimt_event["venueName"]           = eb_event["venue"]["name"]
  glimt_event["organizerName"]       = eb_event["organizer"]["name"]
  glimt_event["eventId"]             = eb_event["url"]
  glimt_event["sourceURL"]           = eb_event["url"]
  glimt_event["title"]               = eb_event["title"][0..139] # Max 140 characters
  glimt_event["description"]         = eb_event["long_description"]
  glimt_event["shortDescription"]    = eb_event["description"]
  glimt_event["longitude"]           = eb_event["venue"]["longitude"]
  glimt_event["latitude"]            = eb_event["venue"]["latitude"]
  glimt_event["startTime"]           = create_timezoned_date(eb_event["start_date"],
                                                             eb_event["timezone_offset"])
  glimt_event["endTime"]             = create_timezoned_date(eb_event["end_date"],
                                                             eb_event["timezone_offset"])
  glimt_event["streetAddress"]       = eb_event["venue"]["address"]
  glimt_event["streetNumber"]        = eb_event["venue"]["address"] # TODO: Not a good match
  glimt_event["postalCode"]          = eb_event["venue"]["postal_code"]
  glimt_event["city"]                = eb_event["venue"]["city"]
  glimt_event["country"]             = eb_event["venue"]["country"]
  glimt_event["ticketPurchasingUrl"] = eb_event["url"]
  glimt_event["ageRestriction"]      = nil
  glimt_event["fullDayEvent"]        = nil
  glimt_events << glimt_event
end

agent = Mechanize.new
agent.post('http://glimt.com/input', { :events => glimt_events.to_json })
