#! Binfoge UPC Syntax Example
#! Language: Binfoge (Version: 26.04.1A)
#! Language: Binfoge UPC (Version: 26.04.1A)
#!
#! Theme in example: "GitHub Dark Colorblind (Beta)" (VS Code plugin: "GitHub Theme")

#! variables
#! Types are detected automatically*
#! view: key=value
my.custom.version="ABC-VERSION-FORM"
its.true_const=true
its.false_const=false
its.null_const=null
its.int_number=65536
its.float_number=3.1415926

#! config of project
#! You cannot put any phrases or words in the key names, only prepared ones
#! Value types (float, integer, boolean, string, character) for certain keys are also predefined.
#! view: key:(value)
name:("my-app2") #! Name of project
version:("0.1.0") #! Version of project (Support formats: CalVer, SemVer)
author:["a","b"] #! author/-s
main:("main.ftk") #! path to main file
build.outfile:("${name}-${my.custom.version}") #! name of outfile (without extention)
build.outdir:("bin") #! path to outfile
test.outfile:("test_${name}_${version}") #! name of test build file
test.outdir:("test") #! path to test build file

#! Types are detected automatically*:
#! number - int
#! number with dot - float
#! values in double quota - str
#! values in single quota - char
#! true/false - bool


