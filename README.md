![Sidetiq](http://f.cl.ly/items/1W3k0R2V2x3n3S1t1M0B/sidetiq.png)
=========

[![Build Status](https://travis-ci.org/endofunky/sidetiq.png)](https://travis-ci.org/endofunky/sidetiq)
[![Dependency Status](https://gemnasium.com/endofunky/sidetiq.png)](https://gemnasium.com/endofunky/sidetiq)
[![Coverage Status](https://coveralls.io/repos/github/endofunky/sidetiq/badge.svg?branch=master)](https://coveralls.io/github/endofunky/sidetiq?branch=master)
[![Code Climate](https://codeclimate.com/github/endofunky/sidetiq.png)](https://codeclimate.com/github/endofunky/sidetiq)

Recurring jobs for [Sidekiq](http://mperham.github.com/sidekiq/).

## NO LONGER MAINTAINED!!!

Due to changes in Sidekiq (which would necessitate an almost complete rewrite) and the move to the ActiveJob abstraction this library is no longer maintained. Please refer to alternatives instead.

### Alternatives

- [Sidekiq PRO](http://sidekiq.org/products/pro)
- [sidekiq-cron](https://github.com/ondrejbartas/sidekiq-cron)
- [sidekiq-scheduler](https://github.com/moove-it/sidekiq-scheduler)
- [sidekiq-dejavu](https://github.com/felixbuenemann/sidekiq-dejavu)

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

Please see the [Sidetiq wiki](http://github.com/endofunky/sidetiq/wiki) for more detailed
documentation and usage notes.

License
-------

Sidetiq is released under the 3-clause BSD. See LICENSE for further details.

Author
------

Tobias Svensson, [@endofunky](https://twitter.com/endofunky), [http://github.com/endofunky](http://github.com/endofunky)

