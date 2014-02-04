# Ruse

Ruse is a low friction dependency injection tool for ruby.

It was inspired by the injector in [angular.js](http://docs.angularjs.org/guide/di)
(and so, transitively, [Guice](https://code.google.com/p/google-guice/)).

## Usage

Create an injector at the top level of your application:

```ruby
  injector = Ruse.create_injector
```

Retrieve instances via that injector:

```ruby
  command = injector.get :create_order_command
  #=> #<CreateOrderCommand:0x00000105cbea70>
```

## Example

Suppose you have a command that collaborates with a notifier service:

```ruby
class CreateOrderCommand
  def execute(customer, order_details)
    save_order(order_details)
    notifier.notify(customer)
  end

  def notifier
    @notifier ||= Notifier.new
  end
end

class Notifier
  def notify(customer)
    # send a notification to customer
  end
end
```

That `CreateOrderCommand` class is now tightly coupled to the `Notifier` class.
It has to know how to construct the Notifier. You would have to change
`CreateOrderCommand` to use a different notifier service.

You can improve the class by using dependency injection:


```ruby
class CreateOrderCommand
  def initialize(notifier)
    @notifier = notifier
  end

  def execute(customer, order_details)
    save_order(order_details)
    @notifier.notify(customer)
  end
end
```

The `CreateOrderCommand` class is now open for extension, but closed for
modification.  It can use a different notifier service, without any changes.
It also does not need to know how to construct a `Notifier` instance, which is
really important if `Notifier` has its own dependencies.

You have now passed the burden of creating and configuring the
`CreateOrderCommand`, the `Notifier`, and any of its dependencies on to the
caller. This is where an Inversion of Control/Dependency Injection tool becomes
valuable:

```ruby
  command = injector.get "CreateOrderCommand"
```

The tool did the tedious work of identifying and populating the dependencies,
all the way down the object graph.

## Instance Resolution

Dependencies are determined by the identifiers used in constructure parameters.
This was lifted directly from angular.js, and I believe may be the key to
reducing the overhead in using a tool like this. Your dependency consuming
classes do not have to be annotated or registered in any way.

In this early alpha state, identifiers are resolved to types through simple
string manipulation (similiar to ActiveSupport's `classify` and `constantize`).
That means you can get an instance of `SomeService` by requesting
`"SomeService"`, `"some_service"` or `:some_service`.

In the future, I can imagine a simple configuration mechanism that lets you
resolve an identifier to some other type, so `"notifier"` resolves to
`EmailNotifier`.

## Installation

Add this line to your application's Gemfile:

    gem 'ruse'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruse


## Contributing

1. [Fork it](http://github.com/joshuaflanagan/ruse/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
