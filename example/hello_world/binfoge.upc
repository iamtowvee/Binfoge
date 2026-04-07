#! local variables
#! name=value
my.custom.version="ABC-VERSION-FORM"

#! config of project
name:("my-app2") #! Name of project
version:("0.1.0") #! Version of project (Support formats: CalVer, SemVer)
author:["a","b"] #! author/-s
main:("main.ftk") #! path to main file
build.outfile:("${name}-${my.custom.version}") #! name of outfile (without extention)
build.outdir:("bin") #! path to outfile
test.outfile:("test_${name}_${version}") #! name of test build file
test.outdir:("test") #! path to test build file


