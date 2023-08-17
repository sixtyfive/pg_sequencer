# `pg_sequencer` Gem

[![Build Status](https://travis-ci.org/sixtyfive/pg_sequencer.svg?branch=master)](https://travis-ci.org/sixtyfive/pg_sequencer)

The `pg_sequencer` gem adds methods to your migrations to allow you to create, drop and change sequence objects in PostgreSQL. It also dumps sequences to `schema.rb` by extending `ActiveRecord::SchemaDumper`. Originally tested with postgres 9.0.4 and was said to work down to 8.1 at that time. Currently known-working with postgres up to 15.0 (adjustments were made at the time of postgres 10.0).

This fork aims to integrate as many of the forks off of the original codebase which was abandoned in 2018. For a better starting point, it was itself forked off of @tablexi's fork, though. So far, it features the following enhancements:

- `db:migrate` no longer pollutes `schema.rb` with sequences already assigned
- `db:migrate` no longer resets existing sequences' `max` value to `0`
- `.tool-versions` file for use with ASDF
- write dumped create sequence statements _above_ tables in `schema.rb`
- `select_sequence` argument
- `owned_by` option
- ignore table primary keys
- support for ruby 2.0+
- support for rails 5.0+
- CI via Travis (currently inoperational, PR welcome)
- a lot of code cleanup by various people

## Installation

Requires `ruby` version 2.7.8+ and `rails` version 6.1+.

Add this to your Gemfile:

```sh
gem 'pg_sequencer', github: 'sixtyfive/pg_sequencer'
```

## API

`pg_sequencer` adds the following methods to migrations:

```ruby
create_sequence(sequence_name, options)
change_sequence(sequence_name, options)
drop_sequence(sequence_name)
```

The methods closely mimic the syntax of the PostgreSQL for `CREATE SEQUENCE`, `DROP SEQUENCE` and `ALTER SEQUENCE`. See the **References** section below for more information.

## Options

For `create_sequence` and `change_sequence`, all options are the same, except `create_sequence` will look for `:start` or `:start_with`, and
`change_sequence` will look for `:restart` or `:restart_with`.

* `:increment`/`:increment_by` (integer) - The value to increment the sequence by.
* `:min` (integer/false) - The minimum value of the sequence. If specified as false (e.g. :min => false), "NO MINVALUE" is sent to Postgres.
* `:max` (integer/false) - The maximum value of the sequence. May be specified as ":max => false" to generate "NO MAXVALUE"
* `:start`/`:start_with` (integer) - The starting value of the sequence (**create_sequence** only)
* `:restart`/`:restart_with` (integer) The value to restart the sequence with (**change_sequence** only)
* `:cache` (integer) - The number of values the sequence should cache.
* `:cycle` (boolean) - Whether the sequence should cycle. Generated at "CYCLE" or "NO CYCLE"

## Creating a sequence

To create a sequence called `user_seq`, incrementing by 1, min of 1, max of 2000000, starts at 1, caches 10 values, and disallows cycles:

```ruby
create_sequence "user_seq",
  increment: 1,
  min: 1,
  max: 2000000,
  start: 1,
  cache: 10,
  cycle: false
```

This is equivalent to:

```sql
CREATE SEQUENCE user_seq INCREMENT BY 1 MIN 1 MAX 2000000 START 1 CACHE 10 NO CYCLE
```

## Altering a sequence

```ruby
change_sequence "accounts_seq", restart_with: 50
```

This is equivalent to:

```sql
ALTER SEQUENCE accounts_seq RESTART WITH 50
```

## Removing a sequence

```ruby
drop_sequence "products_seq"
```

This is equivalent to:

```sql
DROP SEQUENCE products_seq
```

## Caveats / Bugs
 
* Listing all the sequences in a database creates n+1 queries (1 to get the names and n to describe each sequence).
  Is there a way to fully describe all sequences in a database in one query? PRs welcome!
* The `SET SCHEMA` fragment of the `ALTER` command is not implemented.
* Oracle or other databases with sequence or sequence-like concepts are not supported and out of scope for this gem

## References

* [CREATE SEQUENCE](https://www.postgresql.org/docs/current/sql-createsequence.html)
* [ALTER SEQUENCE](https://www.postgresql.org/docs/current/sql-altersequence.html)
* [Extracting Meta Information From PostgreSQL](http://www.alberton.info/postgresql_meta_info.html)

## Credits

The original version of this gem was written by Tony Collen from [Code42](https://www.code42.com). This repository may include commits by authors found in the forks of GitHub users @zenedge, @wwinters, @thinkthroughmath, @steakknife, @offtop, @guilleva, @sinfin, @emilford, @cwinters, @charitywater, @brunopascoa, @bprotas, @didacte, @achempion, @buyapowa, @mindvision and @jhun-magatas and is being kept around by me, @sixtyfive. I currently lack the time to properly maintain this but will gratefully respond to PRs. Looking through those forks, it seemed to me like a lot of work has happened during the time since Code42 posted their abandonment notice and I feel it'd be lovely if not all of that was lost :)

The design of `pg_sequencer` is heavily influenced by Matthew Higgins' [foreigner](https://github.com/matthuhiggins/foreigner) gem.
