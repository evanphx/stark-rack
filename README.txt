= stark-rack

* https://github.com/evanphx/stark-rack

== DESCRIPTION:

Provides middleware for mounting Stark/Thrift services as Rack endpoints.

== FEATURES/PROBLEMS:

* Thrift binary protocol by default
* JSON protocol with 'Accept: application/json' in request headers

== SYNOPSIS:

  # config.ru
  use Stark::Rack
  use MyService::Processor  # Stark/Thrift processor
  run MyHandler.new         # Handler that implements service

== REQUIREMENTS:

* Rack (optional; only required with Stark::Rack::REST middleware)

== INSTALL:

* gem install stark-rack

== DEVELOPERS:

After checking out the source, run:

  $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the RDoc.

== LICENSE:

(The MIT License)

Copyright (c) 2012, 2013 Evan Phoenix

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
