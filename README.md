# ubiquitousse

Set of various libraries I use for game development, mainly with LÖVE. Most of which has already been done before, but these are tailored to what I need. They can be used independently too (you should be able to only pick the directories of the libraries you need; some modules depends on each other though, see documentation for details).

This provides, sorting the one with the fewest existing alterative as far as I know first:

* `ldtk` provides a [LDtk](https://ldtk.io/) level importer
* `gltf` provides a [glTF](https://www.khronos.org/gltf/) model loader
* `ecs` provides [ECS](https://en.wikipedia.org/wiki/Entity_component_system) facilities
* `input` provides input management facilities
* `timer` provides time management facilities
* `signal` provides a simple signal / observer pattern implementation
* `asset` provides barebones asset loading facilities
* `scene` provides some scene management facilities
* `util` provides some random, occasionally useful functions

You can find the documentation [here](https://reuh.github.io/ubiquitousse/index.html) or in the `docs/` directory.

Documentation is done in LDoc-like comments in source files, but LDoc doesn't really like how I structure my libraries (and the fact I use [Candran](https://github.com/Reuh/candran)) so you will need my [LDoc fork](https://github.com/Reuh/LDoc) if you want to generate the documentation yourself.

Whatever is currently on the master branch should be working and usable. Changelog, including breaking changes, are documented in commit messages.

Licensed under ISC (equivalent to MIT/Expat/Simplified BSD). Have fun.
