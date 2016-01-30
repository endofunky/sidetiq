0.6.4
-----

- Use Time.current instead of Time.now in rails apps to
  respect configured timezone [effektz]

0.6.3
-----

- Don't pass classes without #perform defined to handler
- Don't try to connect to redis from Schduleable unless
  Sidekiq.server? returns true.

0.6.2
-----

- Lock ice cube to 0.11.1 to fix memory leaks [camjackson]
- Don't use Redis keys command [Connorhd ]
- Use Sidekiq.redis_pool in Schedulable [nkondratyev]

0.6.1
-----

- Fix manual triggering of jobs with #perform arguments.
- Require 'sidetiq' in 'sidetiq/web'.

0.6.0
-----

- Explicitly require Sidekiq::ExceptionHandler [gglider]
- Fix config.utc [gglider]
- Add Ruby 2.1.1 to travix [gglider]
- Bump ice_cube dependency to 0.12.0 [toolmantim]
- Sort workers index page in web dashboard by name [oestrich]
- Reseting cached times when recurrence changes [LongMan]
- Move CSS to external files [futhr]

0.5.0
-----

- Relax Sidekiq dependency. [leemhenson]

0.4.3
-----

- Various web UI fixes. [manuelmeurer]

0.4.2
-----

- Fix styling for Bootstrap 3 [manuelmeurer]

0.4.1
-----

- Use Sidekiq's JSON wrappers instead of the json gem directly.
- Allow tick used by Clock#tick to be overridden.
- Bump Sidekiq dependency to >= 2.15.0

0.4.0
-----

- Fix bug where web dashboard wouldn't render when in presence of a
  worker without a schedule.
- Schedulable#tiq deprecation warning removed.
- Schedules are now stored on the workers directly instead of in a
  pseudo-global, mutable Hash.
- Clock now start looping automatically if `Sidekiq.server?` returns true.
- Show job history in web extension.
- Integrate with Sidekiq's exception handling/reporting in critical parts.
- Store more detailed lock metadata.
- Remove stray 'thead' from ERB template.
- Store scheduled worker history in Redis.
- Use a Celluloid pool of scheduling handlers to run calculations in parallel.
- Use Celluloid actors instead of plain threads.
- Fix to work with workers with one optional argument. [nata79]
- Refactor top-level namespace methods into separate modules.
- Add Procfile-based example code to boot Sidekiq and the web frontend
  simultaneuously.
- Experimental watcher worker to remove invalid locks.

0.3.7
-----

- Bump Sidekiq dependency to ~> 2.14.0.
- Use ERB templates instead of slim.
- Don't check if `Sidekiq::Web.tabs` is an Array in Sidetiq::Web.
- Fix Ruby parser warnings in web.rb.
- Move development dependencies from Gemfile to gemspec.
- Use coveralls instead of simplecov.

0.3.6
-----

- Better protection against stale locks and race-conditions.

  Locking is now done using WATCH/MULTI/EXEC/UNWATCH and additionally
  includes a host and process specific identifier to prevent accidental
  unlocks from other Sidekiq processes.

- Fix Sidetiq::Schedulable documentation.

0.3.5
-----

- Use Clock#mon_synchronize instead of #synchronize.

  ActiveSupport's core extensions override Module#synchronize which seems to
  break MonitorMixin.

0.3.4
-----

- More robust #perform arity handling.

0.3.3
-----

- Deprecate Sidekiq::Schedulable.tiq in favor of .recurrence.
  Sidekiq::Schedulable.tiq will still work until v0.4.0 but log
  a deprecation warning.

0.3.2
-----

- Fix tests to work with changes to Sidekiq::Client.
  #push_old seems to expect 'at' instead of 'enqueued_at' now
- Switch from MIT to 3-clause BSD license.
- Remove C extension.
- Bump Sidekiq dependency to ~> 2.13.0.
- Ensure redis locks get unlocked in Clock#synchronize_clockworks.

0.3.1
-----

- Bump ice_cube dependency to ~> 0.11.0.
- Bump Sidekiq dependency to ~> 2.12.0.
- Fix tests.

0.3.0
-----

- Add `Sidetiq.schedules`.
- Add `Sidetiq.workers`.
- Add `Sidetiq.scheduled`.
- Add `Sidetiq.retries`.
- Add `Sidetiq.logger`. This defaults to the Sidekiq logger.
- Add support for job backfills.
- Clean up tests.
- Sidetiq::Schedule no longer inherits from IceCube::Schedule.

0.2.0
-----

- Add class methods to get last and next scheduled occurrence.
- Pass last and next (current) occurrence to #perform, if desired.
  This checks the method arity of #perform.
- Bump Sidekiq dependency to 2.8.0
- Fix incorrectly assigned Thread priority.
- Adjust clock sleep depending of execution time of the last tick.
- Don't log thread object ids.
- Issue a warning from the middleware if the clock thread died previously.

0.1.5
-----

- Allow jobs to be scheduled for immediate runs via the web extension.
