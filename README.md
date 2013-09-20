![Sidetiq](http://f.cl.ly/items/1W3k0R2V2x3n3S1t1M0B/sidetiq.png)
=========

[![Build Status](https://travis-ci.org/tobiassvn/sidetiq.png)](https://travis-ci.org/tobiassvn/sidetiq)
[![Dependency Status](https://gemnasium.com/tobiassvn/sidetiq.png)](https://gemnasium.com/tobiassvn/sidetiq)
[![Coverage Status](https://coveralls.io/repos/tobiassvn/sidetiq/badge.png)](https://coveralls.io/r/tobiassvn/sidetiq)
[![Code Climate](https://codeclimate.com/github/tobiassvn/sidetiq.png)](https://codeclimate.com/github/tobiassvn/sidetiq)

Recurring jobs for [Sidekiq](http://mperham.github.com/sidekiq/).

Overview
--------

Sidetiq provides a simple API for defining recurring workers for Sidekiq.

- Concurrency and fault-tolerance using Celluloid actors.

- Flexible DSL based on [ice_cube](http://seejohnrun.github.com/ice_cube/).

- Distributed, Redis-based locking to synchronize multiple Sidetiq processes.

- Web extension with extensive monitoring of recurring jobs.

- Sidetiq runs in your Sidekiq processes. No extra resources required.

Usage
-----

Please see the [Sidetiq wiki](http://github.com/tobiassvn/sidetiq/wiki) for more detailed
documentation and usage notes.

License
-------

Sidetiq is released under the 3-clause BSD. See LICENSE for further details.

Author
------

Tobias Svensson, [@tobiassvn](https://twitter.com/tobiassvn), [http://github.com/tobiassvn](http://github.com/tobiassvn)

