module Sdbus
  class Service
    attr_reader :bus
    attr_reader :path

    alias_method :name, :path

    def initialize(bus, service_path)
      @bus  = bus
      @path = service_path
    end

    def object(obj)
      Sdbus::Object.new(self, obj)
    end

    def objects
      root = self.object('/')
      [root, *root.children]
    end
  end
end
