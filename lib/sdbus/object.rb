require 'rexml/document'

module Sdbus
  class Object
    attr_reader :service
    attr_reader :path

    def initialize(service, obj_path)
      @service = service
      @path = obj_path
    end

    def interfaces
      @ifaces ||= introspect!
    end

    def properties
      interfaces.flap_map(&:properties)
    end

    def bus_methods
      interfaces.flat_map(&:bus_methods)
    end

    def [](property_name)
      iface = interfaces.find{ |i| i.property?(property_name) }
      raise ArgumentError if iface.nil?

      iface.get(property_name)
    end

    def []=(property_name, value)
      iface = interfaces.find{ |i| i.property?(property_name) }
      raise ArgumentError if iface.nil?

      iface.set(property_name, value)
    end

    def call(method, *args)
      iface = interfaces.find{ |i| i.bus_method?(method) }
      raise ArgumentError if iface.nil?
      iface.call(method, *args)
    end

    private

    def introspect!
      err   = FFI::MemoryPointer.new(:uint8, Native::BusError.size)
      reply = FFI::MemoryPointer.new(:pointer)

      rc = Native.sd_bus_call_method(
        service.bus.ptr,
        service.path,
        self.path,
        'org.freedesktop.DBus.Introspectable',
        'Introspect',
        err,
        reply,
        ''
      )

      if rc < 0
        e = Native::BusError.new(err)
        puts e[:message]
        raise BaseError.new(rc)
      end

      msg = Message.new(reply.read_pointer, 's')
      parse_introspect(msg[0])
    end

    def collect_args(method)
      args = {in: [], out: []}

      method.elements.each('arg') do |a|
        args[a.attributes['direction'].to_sym].push(
          name: a.attributes['name'],
          type: a.attributes['type']
        )
      end

      args[:sig] = {
        in:  args[:in].map{ |e| e[:type] }.join(''),
        out: args[:out].map{ |e| e[:type] }.join('')
      }

      args
    end

    def parse_introspect(body)
      doc = REXML::Document.new(body)
      ifaces = []

      doc.root.elements.each('interface') do |e|
        iface = Interface.new(self, e.attributes['name'])
        ifaces.push(iface)

        e.elements.each('property') do |p|
          iface.add_property(
            p.attributes['name'],
            p.attributes['type'],
            p.attributes['access']
          )
        end

        e.elements.each('method') do |m|
          iface.add_method(m.attributes['name'], collect_args(m))
        end
      end

      ifaces
    end
  end
end
