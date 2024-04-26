# Set the base image to use for subsequent instructions
FROM ubuntu:jammy
# Copy any source file(s) required for the action
COPY entrypoint.sh /
# Configure the container to be run as an executable
ENTRYPOINT ["bash","/entrypoint.sh"]
