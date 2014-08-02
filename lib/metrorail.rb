require 'httpclient'
require 'json'

module Metrorail
    @@api_key = nil
    def self.set_api_key(key)
        @@api_key = key
    end

    # A class representing a location (i.e. latitude/longitude)
    class Location
        attr_reader :lat, :lon
        def initialize(lat, lon)
            @lat = lat
            @lon = lon
        end

        def to_s
            return "<Location: #{@lat}, #{@lon}>"
        end
    end

    # A class representing a station in the Metrorail system.
    class Station
        attr_reader :id, :name, :lines_served, :location, :is_transfer
        def initialize(id, name, lines_served, location)
            @id = id
            @name = name
            @lines_served = lines_served
            @location = location
            @is_transfer = false
        end

        def add_line_served(line)
            if not @lines_served.include? line
                @lines_served << line
            end
        end

        def to_s
            return "<Station: #{@name} (#{@id}) serving #{@lines_served.join(",")} at #{@location.to_s}>"
        end

        def self.all
            stations_request = Metrorail::make_request("Rail", "jStations")["Stations"]
            stations = []

            stations_request.each do |station|
                same_station = stations.select { |s| s.name == station["Name"] }
                if same_station.size > 0
                    old_station = same_station[0]
                    ["LineCode1", "LineCode2", "LineCode3", "LineCode4"].each do |linecode|
                        if station[linecode] != nil
                            old_station.add_line_served(station[linecode])
                        end
                    end
                else
                    new_station = Station.new(station["Code"], station["Name"], [], Location.new(station["Lat"], station["Lon"]))
                    ["LineCode1", "LineCode2", "LineCode3", "LineCode4"].each do |linecode|
                        if station[linecode] != nil
                            new_station.add_line_served(station[linecode])
                        end
                    end
                    stations << new_station
                end
            end

            return stations
        end
    end

    private
    def self.make_request(mod, submod, args={})
        client = HTTPClient.new
        args["api_key"] = @@api_key
        JSON::parse(client.get("http://api.wmata.com/#{mod}.svc/json/#{submod}", args).body)
    end
end
