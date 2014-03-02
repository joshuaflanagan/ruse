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

Dependencies are determined by the identifiers used in constructor parameters.
This was lifted directly from angular.js, and I believe may be the key to
reducing the overhead in using a tool like this. Your dependency consuming
classes do not have to be annotated or registered in any way.

By default, identifiers are resolved to types through simple
string manipulation (similiar to ActiveSupport's `classify` and `constantize`).
That means you can get an instance of `SomeService` by requesting
`"SomeService"`, `"some_service"` or `:some_service`. The type is then
instantiated (populating all of *its* dependencies using the same mechanism)
and passed in to the constructor.

However, you can configure the injector to use types that differ from the
parameter name, or return existing objects.

## Instance Lifecycle

Currently, all objects retrieved from the injector are treated as singletons.
This means that any time you ask a given injector for an instance of a
service, you will always get the same exact instance. If you want a new
instance, you need to use a new instance of the injector. In the future,
the lifecycle may be configurable, but I haven't needed it yet.

## Configuration

Currently, you configure the injector by passing an options `Hash` to
`Ruse.create_injector` or to the `#configure` method of an `Injector` instance.
You can call the `#configure` method multiple times, and each time the options
will be merged into the existing options.

Eventually there may be an API or DSL for building the options `Hash`, but for
now, you need to know the specific keys that are understood internally.

### Aliases

Aliases are the most common configuration. They allow you to specify the type
that should be injected for a given parameter name. In the example above,
the `CreateOrderCommand` relies on a `:notifier`. By default, Ruse will
attempt to inject an instance of `Notifier`. However, you may have two services
that can act as a `notifier`: `EmailNotifier` or `FileSystemNotifier`.

In production, you want real emails to be sent, so you would configure the
injector to use `EmailNotifier`:

```ruby
Ruse.create_injector aliases: {notifier: "EmailNotifier"}
```

However, in testing, you just want to record notifications in the filesystem:

```ruby
Ruse.create_injector aliases: {notifier: "FileSystemNotifier"}
```

### Values

Sometimes you want to inject a specific value, or existing object instance,
instead of relying on the injector to create the instance.

```ruby
Ruse.create_injector values: {max_uploads: 42, file_system: File}
```

You could now create a class that depends on `file_system` and send messages
exposed by `File`, without an explicit dependency on `File` (making it easy
to pass in a stub file system during tests).

### Factories / Procs / Delayed Evaluation

Factories are similar to `values`, but allow you to delay the creation of the
object until it is requested. For example, you might want to inject a
connection to a 3rd party service, but you don't want to create the connection
at configuration time - you want to wait until it is used.

```ruby
Ruse.create_injector factories: {
  s3_connection:
    ->{ AWS::S3.new(config).buckets["my_files"] }
}
```

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
