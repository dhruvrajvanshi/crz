# CRZ [![Build Status](https://travis-ci.org/dhruvrajvanshi/crz.svg?branch=master)](https://travis-ci.org/dhruvrajvanshi/crz)
CRZ is a functional programming library for the crystal languages.
Features include
* Common monads
	- Option (implemented)
	- Result
	- Future
* Algebraic data types (using macros).
* Haskell like do notation (more macro goodness).
* Macros for Applicative types.
* Pattern matching (May or may not implement nested patterns and compile time exhaustiveness checking in the future).

## Goals
* Make working with monads/applicatives/functors as pleasant as possible (using macros if needed).
* Enable type safe error handling in the language (using Result(A, E) type).
* Emulate algebraic data types using macros.
* Make working with algebraic types type safe and easy using pattern matching.

## Roadmap
* Write tests.
* Write documentation.
* Make ADT base type a module instead of an abstract class.
* Implement Result and Future types.
* Improve compile time error messages for macros.
