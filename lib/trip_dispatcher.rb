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

    def assign_driver
      ### WAVE 2 ###

      # drivers_available = @drivers.reject { |driver| driver.status == :UNAVAILABLE }
      #
      # if drivers_available.length == 0
      #   raise ArgumentError.new("There are no drivers available.")
      # else
      #   return drivers_available.first
      # end

      ### WAVE 3 ###

      drivers_pool = drivers.reject { |driver| (driver.status == :UNAVAILABLE) || (driver.trips.length == 0)}

      most_recent_trips = []

      if drivers_pool.length == 0
        raise ArgumentError.new("There are no drivers available.")
      else
        drivers_pool.each do |driver|
          most_recent_trips << driver.trips.max_by { |trip| trip.end_time }
        end
        oldest_trip = most_recent_trips.min_by { |trip| trip.end_time }
        return oldest_trip.driver
      end
    end

    def request_trip(passenger_id)

      check_id(passenger_id)
      passenger = find_passenger(passenger_id)

      if passenger == nil
        raise ArgumentError.new("Passenger ID #{passenger_id} not valid.")
      else
        driver = assign_driver

        trip_data = {
          id: @trips.length + 1,
          driver: driver,
          passenger: passenger,
          start_time: Time.now,
          end_time: nil,
          cost: nil,
          rating: nil,
        }

        new_trip = Trip.new(trip_data)
        driver.change_to_unavailable
        driver.add_trip(new_trip)
        passenger.add_trip(new_trip)
        trips << new_trip
        return new_trip
      end
    end

    def inspect
      "#<#{self.class.name}:0x#{self.object_id.to_s(16)}>"
    end

    private

    def check_id(id)
      if id == nil || id <= 0
        raise ArgumentError.new("ID cannot be blank or less than zero. (got #{id})")
      end
    end

  end
end
