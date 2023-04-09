# Sensei

Sensei is a Mac app based on OpenAI API.

## Build

To build Sensei, follow these steps:

- Clone this repository.
- Install [Tuist](https://docs.tuist.io/tutorial/get-started) if needed.
- In the repository's directory, run `make sensei bundle-id-prefix=io.tuist` to fetch third-party dependencies, then generate the Xcode Project and open it. You can replace `io.tuist` with your own domain in reverse-DNS format.
