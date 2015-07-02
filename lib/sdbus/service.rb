module Sdbus
  # Represents a service endpoint on a bus.
  # A service can contain multiple objects, each of which can implement
  # multiple interfaces.
  class Service
    # the {Sdbus::Bus} that this service is on.
    attr_reader :bus
    # the path to the service, e.g `org.freedesktop.DBus`
    attr_reader :path

    alias_method :name, :path

    # @private
    def initialize(bus, service_path)
      @bus  = bus
      @path = service_path
    end

    # returns a reference to the {Sdbus::Object} with the provided name.
    # @example Get a reference to the desktop notification object.
    #   obj = Sdbus.user_bus
    #     .service('org.freedesktop.Notifications')
    #     .object('org/freedesktop/Notifications')
    # @return [Sdbus::Object]
    def object(obj)
      Sdbus::Object.new(self, obj)
    end

    # returns a list of all objects currently available under this service.
    # @example List all objects under the hostname1 service.
    #   objs = Sdbus.system_bus
    #     .service('org.freedesktop.hostname1')
    #     .objects
    def objects
      root = object('/')
      [root, *root.children]
    end
  end
end
