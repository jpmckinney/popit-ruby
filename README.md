# The PopIt API Ruby Gem

A Ruby wrapper for the [PopIt](http://popit.mysociety.org/) API, which allows you to create, read, update and delete documents from PopIt.

[![Build Status](https://secure.travis-ci.org/opennorth/popit-ruby.png)](http://travis-ci.org/opennorth/popit-ruby)
[![Dependency Status](https://gemnasium.com/opennorth/popit-ruby.png)](https://gemnasium.com/opennorth/popit-ruby)
[![Coverage Status](https://coveralls.io/repos/opennorth/popit-ruby/badge.png?branch=master)](https://coveralls.io/r/opennorth/popit-ruby)
[![Code Climate](https://codeclimate.com/github/opennorth/popit-ruby.png)](https://codeclimate.com/github/opennorth/popit-ruby)

## Installation

    gem install popit

## API Examples

First, require the PopIt gem:

```ruby
require 'popit'
```

Then, create an API client for PopIt:

```ruby
api = PopIt.new :instance_name => 'demo'
```

You can pass these options to `PopIt.new`:

* `:instance_name` the PopIt instance, usually the first part of the domain name
* `:host_name` the PopIt API's host name – defaults to "popit.mysociety.org"
* `:port` the PopIt API's port – defaults to 80
* `:version` the PopIt API version – defaults to "v0.1"
* `:user` a user name – if blank, the API will be read-only
* `:password` the user's password

For brevity, we only show examples below for `persons` documents, but you can use the same code to operate on organizations and memberships by substituting `organizations` or `memberships` for `persons`.

More documentation at [RubyDoc.info](http://rdoc.info/gems/popit/PopIt).

### Read

Get all people:

```ruby
api.persons.get
```

Get one person:

```ruby
api.persons('47cc67093475061e3d95369d').get
```

### Search

Read the [PopIt API documentation](http://popit.mysociety.org/docs/api/search) for details.

```ruby
api.search.persons.get(:name => 'John Doe')
```

### Create

```ruby
response = api.person.post(:name => 'John Doe')
id = response['id']
```

### Update

```ruby
api.person(id).put(:id => id, :name => 'Jane Doe')
```

### Delete

```ruby
success = api.person(id).delete
```

## Error Handling

You will raise a `PopIt::PageNotFound` exception if you attempt to access an instance, API version, collection or document that doesn't exist. You will raise a `PopIt::NotAuthenticated` exception if you attempt to create, update or delete a document without authenticating. In other error cases, you will raise a generic `PopIt::Error` exception.

The exception's message will be the same as from the PopIt API.

```ruby
require 'popit'
api = PopIt.new :instance_name => 'demo'
api.person.get 'foo' # raises PopIt::PageNotFound with "page not found"
```

## Running Tests

To run the tests:

    export INSTANCE_NAME=YOUR_POPIT_INSTANCE_NAME
    export POPIT_USER=YOUR_POPIT_EMAIL_ADDRESS
    export POPIT_PASSWORD=YOUR_POPIT_PASSWORD
    bundle exec rake

**If you care about the data in an instance, do not use that instance to run tests!**

## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/popit-ruby](http://github.com/opennorth/popit-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2011 Open North Inc., released under the MIT license
