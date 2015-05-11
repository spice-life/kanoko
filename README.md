kanoko
===

[![Build Status](https://travis-ci.org/spice-life/kanoko.svg?branch=master)](https://travis-ci.org/spice-life/kanoko)

**kanoko** is an active image generate application.

# Quick Start

```
require 'kanoko/application/convert'

class MyApp < Kanoko::Application::Convert
end

run MyApp
```

```
$ KANOKO_DIGEST_FUNC=sha1 KANOKO_SECRET_KEY=devkey unicorn --config-file config/unicorn/development.rb
```

# Arguments

**http://{{kanoko.host}}/:hash/:func/:args/:path**

- **hash:** params signature (see also **Signature**)
- **func:** a function name of image processing (e.g. fit)
- **args:** image processing arguments (e.g. "100x100")
- **path:** Target image path without scheme (e.g. "host/path/to/image?params\_a=value\_a")

# Signature

**hash** is changeable.

By default, see `Kanoko::Configure#initialize`.

On application, It must be set **hash** same way as this.

If hash not match, application should be return *400 Bad Request*.

This function behavior can change by Kanoko.configure.

```ruby
Kanoko.configure.hash_proc = ->{
  "some_hash_value_on_url"
}
```

# TODO

- To be able to change digest_func and secret_key on graceful restart
- More fast
