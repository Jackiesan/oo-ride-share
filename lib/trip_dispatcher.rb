require 'csv'
require 'time'
require 'pry'
require 'awesome_print'

require_relative 'driver'
require_relative 'passenger'
require_relative 'trip'

module RideShare
  class TripDispatcher
    attr_reader :drivers, :passengers, :trips

    def initialize
      @drivers = load_drivers
      @passengers = load_passengers
      @trips = load_trips
    end

    def load_drivers
      my_file = CSV.open('support/drivers.csv', headers: true)

      all_drivers = []
      my_file.each do |line|
        input_data = {}
        # Set to a default value
        vin = line[2].length == 17 ? line[2] : "0" * 17

        # Status logic
        status = line[3]
        status = status.to_sym

        input_data[:vin] = vin
        input_data[:id] = line[0].to_i
        input_data[:name] = line[1]
        input_data[:status] = status
        all_drivers << Driver.new(input_data)
      end

      return all_drivers
    end

    def find_driver(id)
      check_id(id)
      @drivers.find{ |driver| driver.id == id }
    end

    def load_passengers
      passengers = []

      CSV.read('support/passengers.csv', headers: true).each do |line|
        input_data = {}
        input_data[:id] = line[0].to_i
        input_data[:name] = line[1]
        input_data[:phone] = line[2]

        passengers << Passenger.new(input_data)
      end

      return passengers
    end

    def find_passenger(id)
      check_id(id)
      @passengers.find{ |passenger| passenger.id == id }
    end

    def load_trips
      trips = []
      trip_data = CSV.open('support/trips.csv', 'r', headers: true, header_converters: :symbol)

      trip_data.each do |raw_trip|
        driver = find_driver(raw_trip[:driver_id].to_i)
        passenger = find_passenger(raw_trip[:passenger_id].to_i)

        parsed_trip = {
          id: raw_trip[:id].to_i,
          driver: driver,
          passenger: passenger,
          start_time: Time.parse(raw_trip[:start_time]),
          end_time: Time.parse(raw_trip[:end_time]),
          cost: raw_trip[:cost].to_f,
          rating: raw_trip[:rating].to_i
        }

        trip = Trip.new(parsed_trip)
        driver.add_trip(trip)
        passenger.add_trip(trip)
        trips << trip
      end

      trips
    end

    def request_trip(passenger_id)

      drivers_available = @drivers.reject { |driver| driver.status == :UNAVAILABLE }

      trip_data = {
        id: @trips.length + 1,
        driver: drivers_available[0],
        passenger: passenger_id,
        start_time: Time.now,
        end_time: nil,
        cost: nil,
        rating: nil,
      }

      new_trip = Trip.new(trip_data)
      drivers_available[0].change_to_unavailable
      drivers_available[0].add_trip(new_trip)
      find_passenger(passenger_id).add_trip(new_trip)
      trips << new_trip
      return new_trip
    end


    private

    def check_id(id)
      if id == nil || id <= 0
        raise ArgumentError.new("ID cannot be blank or less than zero. (got #{id})")
      end
    end

  end
end
#
### TESTING FOR REQUESTING TRIP ####
# dispatcher = RideShare::TripDispatcher.new
#
# passenger = dispatcher.find_passenger(3)
# actual_driver = dispatcher.find_driver(2)
# puts "original passenger trips #{passenger.trips.length}"
# puts "original driver trips : #{actual_driver.trips.length}"
#
# puts dispatcher.trips.length
# new_trip = dispatcher.request_trip(3)
# puts new_trip
# puts new_trip.class
# puts new_trip.id
# driver = new_trip.driver
# puts "Driver ID : #{driver.id}"
# puts "Driver Status: #{driver.status}"
# # passenger = new_trip.passenger
# # passenger = dispatcher.find_passenger(2)
#
# puts "Final passenger trips: #{passenger.trips.length}"
# puts "Final driver trips : #{actual_driver.trips.length}"
#

##############################################################

# dispatcher = RideShare::TripDispatcher.new
#
# trip = dispatcher.trips[1]
# puts trip.start_time
# puts trip.end_time
# puts trip.duration

# puts "Passenger ID: #{passenger.id}"
# puts dispatcher.trips.length
# puts new_trip.driver.id
# puts new_trip.passenger.id
# puts new_trip.
# driver = dispatcher.drivers[8]
# #
# puts driver.total_revenue
#
# driver.trips.each do |trip|
#   times = trip.duration
#   puts times
# end
# #
# #
# puts "Total revenue_per_hour: #{driver.total_revenue_per_hour}"
# puts passenger.name
# puts passenger.calculate_total_trips_duration

# puts passenger.calculate_total_money_spent
# # binding.pry
# dispatcher = RideShare::TripDispatcher.new
# puts dispatcher.load_passengers[0]
# puts dispatcher.load_trips
# puts dispatcher.trips[0].start_time
# puts dispatcher.trips[0].start_time.class
# puts dispatcher.trips[0].start_time.to_r
# puts dispatcher.trips[0].class
