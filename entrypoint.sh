#!/bin/sh -l

# Use INPUT_<INPUT_NAME> to get the value of an input
echo "cd /github/workspace/$INPUT_PATH"
cd /github/workspace/$INPUT_PATH
cargo install --path . --target x86_64-unknown-linux-musl

# Write outputs to the $GITHUB_OUTPUT file
if [ "" = "$INPUT_PATH" ]; then
  echo "release_dir=/github/workspace/target/x86_64-unknown-linux-musl/release/" >> "$GITHUB_OUTPUT"
  exit 0
else
  echo "release_dir=/github/workspace/$INPUT_PATH/target/x86_64-unknown-linux-musl/release/" >> "$GITHUB_OUTPUT"
  exit 0
fi
