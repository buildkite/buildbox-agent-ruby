# Buildbox

## Installation

Install the gem

    $ gem install buildbox
    
Authenticate

    $ buildbox auth:login [api_key]

Add your worker tokens

    $ buildbox agent:setup [token]

Then you can start monitoring for builds like so:

    $ buildbox agent:start

For more help with the command line interface

    $ buildbox --help

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2013 Keith Pitt. See LICENSE for details.
