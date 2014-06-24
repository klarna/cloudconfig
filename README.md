# Cloudconfig

## Installation

Add this line to your application's Gemfile:

    gem 'cloudconfig'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloudconfig

## Usage

Cloudconfig will configure resources in Cloudstack.

To use the application:

    cloudconfig --help

Create config:

    cloudconfig config API_KEY SECRET_KEY RESOURCE_DIRECTORY

Dryrun can be performed to view potential changes:

    cloudconfig update hosts --dryrun

### Configuration of resources

Cloudconfig will configure resources in Cloudstack according to resources in yaml files in specified directory.

Resources that currently are handled by cloudconfig:

- Compute offerings (create, update, delete)
- Disk offerings (update)
- Host tags (create, delete)
- Storage tags (create, delete)

Resource files are expected to be structured in following manner in configured resource directory:

    .
    ├── diskofferings.yaml
    ├── hosts.yaml
    ├── serviceofferings.yaml
    └── storages.yaml

diskofferings.yaml:

    DiskOfferings:
      20gb: { tags: "SSD",
              displaytext: "20GB SSD Drive",
              disksize: 200 }

      50GB: { tags: "SSD",
              displaytext: "50GB SSD Drive",
              disksize: 50 }

hosts.yaml:

    Hosts:
      host1.example.com: { hosttags: "small,medium",
                           zonename: "example" }

      host2.example.com: { hosttags: "small,medium,large",
                           zonename: "example" }

serviceofferings.yaml:

    ServiceOfferings:
      small: { displaytext: "1vCPU, 1GHz, 1GB RAM",
               storagetype: "shared",
               cpunumber: 1,
               cpuspeed: 1000,
               memory: 1024,
               tags: "disk",
               hosttags: "small" }

storage.yaml:

    Storages:
      ssd: { tags: "ssd",
             zonename: "example" }

      ssd: { tags: "ssd",
             zonename: "example" }

### Testing

Currently only unit testing:

    bundle install
    bundle exec ruby test/test.rb

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
