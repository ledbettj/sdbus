require 'spec_helper'

describe Sdbus do
  it 'has a version number' do
    expect(Sdbus::VERSION).not_to be nil
  end

  it 'does something useful' do
    obj = Sdbus.system_bus
    .service('org.freedesktop.hostname1')
    .object('/org/freedesktop/hostname1')

    puts "#{obj[:hostname]} running on #{obj[:kernel_name]} #{obj[:kernel_version]}"
 end
end
