# Set the base image to use for subsequent instructions
FROM ubuntu:focal
# 设置时区相关的环境变量
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
# Copy any source file(s) required for the action
COPY entrypoint.sh /
# Configure the container to be run as an executable
ENTRYPOINT ["bash","/entrypoint.sh"]
