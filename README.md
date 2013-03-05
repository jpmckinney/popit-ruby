# The PopIt API Ruby Gem

A Ruby wrapper for the [PopIt](http://popit.mysociety.org/) API, which allows you to create, read, update and delete items from PopIt.

[![Build Status](https://secure.travis-ci.org/opennorth/popit-ruby.png)](http://travis-ci.org/opennorth/popit-ruby)
[![Dependency Status](https://gemnasium.com/opennorth/popit-ruby.png)](https://gemnasium.com/opennorth/popit-ruby)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/opennorth/popit-ruby)

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
* `:version` the PopIt API version – defaults to "v1"
* `:user` a user name – if blank, the API will be read-only
* `:password` the user's password

For brevity, we only show examples below for `person` items, but you can use the same code to operate on organisations and positions by substituting `organisation` or `position` for `person`.

More documentation at [RubyDoc.info](http://rdoc.info/gems/popit/PopIt).

### Read

Get all people:

```ruby
response = api.person.get
p response['results']
```

Get one person:

```ruby
response = api.person('47cc67093475061e3d95369d').get
p response['result']
```

You can also search for...

* people by slug, name or summary
* organisations by slug or name
* positions by title, person or organisation

For example:

```ruby
response = api.person.get :name => 'John Doe'
p response['results']
```

### Create

```ruby
response = api.person.post :name => 'John Doe'
id = response['result']['_id']
```

### Update

```ruby
response = api.person(id).put :name => 'Jane Doe'
p response['result']
```

### Delete

```ruby
success = api.person(id).delete
```

## Error Handling

If you attempt to:

* read an item that doesn't exist
* create, update or delete an item without authenticating
* operate on something other than people, organisations and positions

you will raise a `PopIt::Error` exception. The exception's message will be the same as from the PopIt API.

```ruby
require 'popit'
api = PopIt.new :instance_name => 'demo'
api.person.get 'foo' # raises PopIt::Error with {"error":"page not found"}
```

## Running Tests

To run the tests, create a `spec_auth.yml` file in the `spec` directory with the contents:

```yml
instance_name: YOUR_TEST_INSTANCE
user: YOUR_USERNAME
password: YOUR_PASSWORD
```

**If you care about the data in an instance, do not use that instance to run tests!**

## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/popit-ruby](http://github.com/opennorth/popit-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2011 Open North Inc., released under the MIT license
