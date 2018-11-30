[![Build Status](https://travis-ci.org/dreal-deps/homebrew-ibex.svg?branch=master)](https://travis-ci.org/dreal-deps/homebrew-ibex)

How to Maintain
---------------

```bash
brew rm ibex@2.7.4 -f
brew install ./ibex@2.7.4.rb --build-bottle
brew bottle ./ibex@2.7.4.rb --force-core-tap
```
