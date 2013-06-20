Sidetiq
=======

[![Build Status](https://travis-ci.org/tobiassvn/sidetiq.png)](https://travis-ci.org/tobiassvn/sidetiq)
[![Dependency Status](https://gemnasium.com/tobiassvn/sidetiq.png)](https://gemnasium.com/tobiassvn/sidetiq)

Recurring jobs for [Sidekiq](http://mperham.github.com/sidekiq/).

Table Of Contents
-----------------

   * [Overview](#section_Overview)
   * [Dependencies](#section_Dependencies)
   * [Installation](#section_Installation)
   * [Introduction](#section_Introduction)
   * [Backfills](#section_Backfills)
   * [Configuration](#section_Configuration)
      * [Logging](#section_Configuration_Logging)
   * [API](#section_API)
   * [Polling](#section_Polling)
   * [Known Issues](#section_Known_Issues)
   * [Web Extension](#section_Web_Extension)
   * [Contribute](#section_Contribute)
   * [License](#section_License)
   * [Author](#section_Author)

<a name='section_Overview'></a>
Overview
--------

Sidetiq provides a simple API for defining recurring workers for Sidekiq.

- Flexible DSL based on [ice_cube](http://seejohnrun.github.com/ice_cube/)

- Sidetiq uses a locking mechanism (based on `setnx` and `pexpire`) internally
  so Sidetiq clocks can run in each Sidekiq process without interfering with
  each other (tested with sub-second polling of scheduled jobs by Sidekiq and
  Sidetiq clock rates above 100hz).

Detailed API documentation is available on [rubydoc.info](http://rdoc.info/github/tobiassvn/sidetiq/).

<a name='section_Dependencies'></a>
Dependencies
------------

- [Sidekiq](http://mperham.github.com/sidekiq/)
- [ice_cube](http://seejohnrun.github.com/ice_cube/)

<a name='section_Installation'></a>
Installation
------------

The best way to install Sidetiq is with RubyGems:

    $ [sudo] gem install sidetiq

If you're installing from source, you can use [Bundler](http://gembundler.com/)
to pick up all the gems ([more info](http://gembundler.com/bundle_install.html)):

    $ bundle install

<a name='section_Introduction'></a>
Introduction
------------

Defining recurring jobs is simple:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # Daily at midnight
  recurrence { daily }

  def perform
    # do stuff ...
  end
end
```

It also is possible to define multiple scheduling rules for a worker:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence do
    # Every third year in March
    yearly(3).month_of_year(:march)

    # Every second year in February
    yearly(2).month_of_year(:february)
  end

  def perform
    # do stuff ...
  end
end
```

Or complex schedules:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # Every other month on the first monday and last tuesday at 12 o'clock.
  recurrence { monthly(2).day_of_week(1 => [1], 2 => [-1]).hour_of_day(12) }

  def perform
    # do stuff ...
  end
end
```

Additionally, the last and current occurrence time (as a `Float`) can be
passed to the worker simply by adding arguments to `#perform`. Sidetiq
will check the method arity before enqueuing the job:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { daily }

  # Receive last and current occurrence times.
  def perform(last_occurrence, current_occurrence)
    # do stuff ...
  end
end
```

To start Sidetiq, simply call `Sidetiq::Clock.start!` in a server specific
configuration block:

```ruby
Sidekiq.configure_server do |config|
  Sidetiq::Clock.start!
end
```

Additionally, Sidetiq includes a middleware that will check if the clock
thread is still alive and restart it if necessary.

<a name='section_Backfills''></a>
Backfills
---------

In certain cases it is desirable that missed jobs will be enqueued
retroactively, for example when a critical, hourly job isn't run due to
server downtime. To solve this, `#recurrence` takes a *backfill* option. If
missing job occurrences have been detected, Sidetiq will then enqueue
the jobs automatically. It will also ensure that the timestamps passed to
`#perform` are as expected:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence backfill: true do
    hourly
  end

  def perform(last_occurrence, current_occurrence)
    # do stuff ...
  end
end
```

<a name='section_Configuration'></a>
Configuration
-------------

```ruby
Sidetiq.configure do |config|
  # Thread priority of the clock thread (default: Thread.main.priority as
  # defined when Sidetiq is loaded).
  config.priority = 2

  # Clock tick resolution in seconds (default: 1).
  config.resolution = 0.5

  # Clock locking key expiration in ms (default: 1000).
  config.lock_expire = 100

  # When `true` uses UTC instead of local times (default: false).
  config.utc = false

  # When `true` passes last and current occurrence time to the worker
  # (default: true).
  config.time_args = true
end
```
<a name='section_Configuration_Logging'></a>
### Logging

By default Sidetiq uses Sidekiq's logger. However, this is configuration:

```ruby
Sidetiq.logger = Logger.new(STDOUT)
```

The logger should implement Ruby's [Logger API](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html).

<a name='section_API'></a>
API
---

Sidetiq implements a simple API to support reflection of recurring jobs at
runtime:

`Sidetiq.schedules` returns a `Hash` with the `Sidekiq::Worker` class as the
key and the Sidetiq::Schedule object as the value:

```ruby
Sidetiq.schedules
# => { MyWorker => #<Sidetiq::Schedule> }
```

`Sidetiq.workers` returns an `Array` of all workers currently tracked by
Sidetiq (workers which include `Sidetiq::Schedulable` and a `.recurrence`
call):

```ruby
Sidetiq.workers
# => [MyWorker, AnotherWorker]
```

`Sidetiq.scheduled` returns an `Array` of currently scheduled Sidetiq jobs
as `Sidekiq::SortedEntry` (`Sidekiq::Job`) objects. Optionally, it is
possible to pass a block to which each job will be yielded:

```ruby
Sidetiq.scheduled do |job|
  # do stuff ...
end
```

This list can further be filtered by passing the worker class to `#scheduled`,
either as a String or the constant itself:

```ruby
Sidetiq.scheduled(MyWorker) do |job|
  # do stuff ...
end
```

The same can be done for recurring jobs currently scheduled for retries
(`.retries` wraps `Sidekiq::RetrySet` instead of `Sidekiq::ScheduledSet`):

```ruby
Sidetiq.retries(MyWorker) do |job|
  # do stuff ...
end
```

<a name='section_Polling'></a>
Polling
-------

By default Sidekiq uses a 15 second polling interval to check if scheduled
jobs are due. If a recurring job has to run more often than that you should
lower this value.

```ruby
Sidekiq.options[:poll_interval] = 1
```

More information about this can be found in the
[Sidekiq Wiki](https://github.com/mperham/sidekiq/wiki/Scheduled-Jobs).

<a name='section_Known_Issues'></a>
Known Issues
------------

Unfortunately, using ice_cube's interval methods is terribly slow on
start-up (it tends to eat up 100% CPU for quite a while). This is due to it
calculating every possible occurrence since the schedule's start time. The way
around is to avoid using them.

For example, instead of defining a job that should run every 15 minutes like this:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { minutely(15) }
end
```

It is better to use the more explicit way:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly.minute_of_hour(0, 15, 30, 45) }
end
```

<a name='section_Web_Extension'></a>
Web Extension
-------------

Sidetiq includes an extension for Sidekiq's web interface. It will not be
loaded by default, so it will have to be required manually:

```ruby
require 'sidetiq/web'
```

### SCREENSHOT

![Screenshot](http://f.cl.ly/items/1P2u1v091F3V1n381g2I/Screen%20Shot%202013-02-01%20at%2012.16.17.png)

<a name='section_Contribute'></a>
Contribute
----------

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

<a name='section_License'></a>
License
-------

Sidetiq is released under the 3-clause BSD. See LICENSE for further details.

<a name='section_Author'></a>
Author
------

Tobias Svensson, [@tobiassvn](https://twitter.com/tobiassvn), [http://github.com/tobiassvn](http://github.com/tobiassvn)

