# Sdbus

Sdbus is a set of ruby bindings for the `sd-bus` DBus/kdbus library.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sdbus'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sdbus

You will need a recent-ish version of `libsystemd` which incudes the
`sd-bus` bindings.

## Usage

First, specify the DBus object you are interested in:

```ruby
obj = Sdbus.system_bus
  .service('org.freedesktop.hostname1')
  .object('/org/freedesktop/hostname1')
  ```

### Listing Interfaces:

```
puts obj.interfaces.map(&:name)
```

## Listing Interface Properties:

```
puts obj.interfaces.map(&:properties)
```

### Accessing Properties:

```ruby
puts "#{obj[:hostname]} running on #{obj[:kernel_name]} #{obj[:kernel_version]}"

# or if this property were settable:

obj[:hostname] = 'Mybox'
```

### Calling Methods

```ruby
obj.call(:set_hostname, "MyBox", true)
```

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bundle exec rake console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ledbettj/sdbus.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

