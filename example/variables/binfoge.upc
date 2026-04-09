#! VARIABLES
hello="Hello from config!"
my.version="A1"

#! CONFIGURATION
name:("my-app2")
version:("0.1.0")
author:["a","b"]
main:("main.ftk")
build.outfile:("${name}-${my.version}")
build.outdir:("bin")
test.outfile:("test_${name}_${my.version}")
test.outdir:("test")