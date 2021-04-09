Build re2 wheels for Python

[re2](https://github.com/google/re2) in Python ... without the compilation.

This builds [manylinux2014](https://www.python.org/dev/peps/pep-0599/)-compatible
files, for widespread distribution.

# Installation

Instead of `python -mpip install google-re2`, run:

```
python -mpip install built-google-re2
```

And use it as though you'd installed `google-re2`.

# The problem

Python's [re](https://docs.python.org/3/library/re.html) module (and the
third-party [regex](https://pypi.org/project/regex/) module) have two flaws:

* *They're too slow* on complex regexes. If you're using them to extract tokens,
  email addresses or URLs from text, you're either violating your spec or you're
  waiting seconds or minutes on any decent amount of text.
* *They're unsafe* on user-entered regexes. If you've built a web server that
  accepts a regex from an end-user and runs it, you're vulnerable to
  denial-of-service.

# The solution...

Google's [re2](https://github.com/google/re2) fixes both problems. It's very,
very fast. And it has performance guarantees to prevent denial-of-service.

It isn't perfectly compatible with Python's `re` module, but that's the point!
Backreferences and look-around assertions won't work.

However, there's a new problem: compilation.

The official [google-re2](https://pypi.org/project/google-re2/) package needs
to be compiled from source, and it expects "re2" to be installed on your system.
Most systems don't come with "re2" (tragedy!); and your installed version might
not be compatible. Plus, you need a C++ compiler just to install this Python
package....

All that to say: `python -mpip install google-re2` is fraught with new problems.
So is `python -mpip install pyre2`, `python -mpip install re2` ... and so on.

# The solution ... for real!

So you can just `python -mpip install built-google-re2`.

It has no system dependencies. It's pre-compiled on
[manylinux2014](https://www.python.org/dev/peps/pep-0599/), so virtually any
non-end-of-life Linux system can load it.

# Developing

You'll need to run this on Linux. Any Linux will do.

0. Install [Docker](https://docs.docker.com/get-docker/)
1. Edit files in this repository
2. Run `rm -f dist/*.whl; ./gen-wheels.sh` to build wheels
3. Run `twine upload dist/*.whl` to upload the wheels to pypi

## Innards

* This library is named `built-google-re2` instead of `google-re2`. Hopefully,
  that's temporary: ideally, one day, `python3 -mpip install google-re2` should
  install these very wheels. In the meantime, your Python code won't change: you
  still `import re2`.
* This library is built from a git tag. That's because as of 2021-04-09, the last
  google-re2 version (0.0.7) used a slightly different build system. Rather than
  fix outdated build errors, it's published as version `0.0.7.20210224100510`.
* Python versions: `3.6`, `3.7`, `3.8`, `3.9`. (Python 2 isn't supported. It has
  reached end-of-life.)
* The wheels have only one `.so` file -- `_re2.so`. It includes some abseil and
  re2 symbols. If you install `re2` as a systemwide library, `built-google-re2`
  won't use it.
* The build system uses Bazel to build `_re2.so`. Internally, we run
  `python ./setup.py bdist_wheel` ... which tries to compile the source code
  Bazel already compiled. So we install a "fake C compiler" just for setup.py:
  it copies the Bazel-compiled `_re2.so` to the final destination.

# License

MIT license
