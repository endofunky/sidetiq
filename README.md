Sidetiq
=======

[![Build Status](https://travis-ci.org/tobiassvn/sidetiq.png)](https://travis-ci.org/tobiassvn/sidetiq)

Recurring jobs for [Sidekiq](http://mperham.github.com/sidekiq/).

## DESCRIPTION

Sidetiq provides a simple API for defining recurring workers for Sidekiq.

- Flexible DSL based on [ice_cube](http://seejohnrun.github.com/ice_cube/)

- High-resolution timer using `clock_gettime(3)` (or `mach_absolute_time()` on
  Apple Mac OS X), allowing for accurate sub-second clock ticks.

- Sidetiq uses a locking mechanism (based on `setnx` and `pexpire`) internally
  so Sidetiq clocks can run in each Sidekiq process without interfering with
  each other (tested with sub-second polling of scheduled jobs by Sidekiq and
  Sidetiq clock rates above 100hz).

## DEPENDENCIES

- [Sidekiq](http://mperham.github.com/sidekiq/)
- [ice_cube](http://seejohnrun.github.com/ice_cube/)

## INSTALLATION

The best way to install Sidetiq is with RubyGems:

    $ [sudo] gem install sidetiq

If you're installing from source, you can use [Bundler](http://gembundler.com/)
to pick up all the gems ([more info](http://gembundler.com/bundle_install.html)):

    $ bundle install

## GETTING STARTED

Defining recurring jobs is simple:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # Daily at midnight
  tiq { daily }
end
```

It also is possible to define multiple scheduling rules for a worker:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  tiq do
    # Every third year in March
    yearly(3).month_of_year(:march)

    # Every second year in February
    yearly(2).month_of_year(:february)
  end
end
```

Or complex schedules:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # Every other month on the first monday and last tuesday at 12 o'clock.
  tiq { monthly(2).day_of_week(1 => [1], 2 => [-1]).hour_of_day(12) }
end
```

The first time the tiq method is called, Sidetiq will automatically spin up
it's clock thread and enqueue jobs for their next occurrence using
`#perform_at`. Note that by default Sidekiq only polls every 15 seconds.

## CONFIGURATION

```ruby
Sidetiq.configure do |config|
  # Thread priority of the clock thread (default: Thread.main.priority as
  # defined when Sidetiq is loaded).
  config.priority = 2

  # Clock tick resolution in seconds (default: 1).
  config.resolution = 0.5

  # Clock locking key expiration in ms (default: 1000).
  config.lock_expire = 100
end
```

## WEB EXTENSION

Sidetiq includes an extension for Sidekiq's web interface. It will not be
loaded by default, so it will have to be required manually:

```ruby
require 'sidetiq/web'
```

### SCREENSHOT

![Screenshot](http://f.cl.ly/items/1P2u1v091F3V1n381g2I/Screen%20Shot%202013-02-01%20at%2012.16.17.png)

## CONTRIBUTE

If you'd like to contribute to Sidetiq, start by forking my repo on GitHub:

[http://github.com/tobiassvn/sidetiq](http://github.com/tobiassvn/sidetiq)

To get all of the dependencies, install the gem first. The best way to get
your changes merged back into core is as follows:

1. Clone down your fork
1. Create a thoughtfully named topic branch to contain your change
1. Write some code
1. Add tests and make sure everything still passes by running `rake`
1. If you are adding new functionality, document it in the README
1. Do not change the version number, I will do that on my end
1. If necessary, rebase your commits into logical chunks, without errors
1. Push the branch up to GitHub
1. Send a pull request to the tobiassvn/sidetiq project.

## LICENSE

Sidetiq is released under the MIT License. See LICENSE for further details.
