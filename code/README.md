## aco-mets : code subdirectory
This directory contains a rough validator for Princeton ACO submissions.

## Current Status: *IN DEVELOPMENT*
 this code is pretty rough and needs to be refactored into a gem,
  but the code **does** check the following:

```
1.) METS file validates against schema
2.) all files mentioned in all parts of document:
    * are present
    * have checksum values
    * pass fixity check
3.) specific file checks
      eoc file present
      calibration files present
      marcxml file(s) present
      target files present
      master filegrp present
4.) struct map div
      TYPE contains recognized values
        SOURCE_ENTITY:TEXT
        ONE_TO_ONE_ENTITY:TEXT
        INTELLECTUAL_ENTITY:TEXT
        SCAN_ORDER
        READ_ORDER
        BINDING_ORIENTATION
    intellectual entity div
        @TYPE:
          INTELLECTUAL_ENTITY
     slot div:
       @TYPE
         LOCATION
         TYPE
```


## Prerequisites:
- to install the required gems, cd to the repository root and run ```$ bundle```


## Running:

### N.B. YOU MUST BE IN THE SAME DIRECTORY AS THE METS FILE BEFORE INVOKING SCRIPT

```
$ pwd
/digital/object/root/directory/containing/mets/file
$ ruby /path/to/script/validate-aco-mets.rb <digitization id>_mets.xml
```

## Sample invocation:
#### passing example
```
$ cd /path/to/princeton_aco1899218
$ ruby ~/dev/aco-mets/code/validate-aco-mets.rb princeton_aco1899218_mets.xml 
princeton_aco1899218_mets.xml
/path/to/princeton_aco1899218
$ echo $?
0
```

#### failing example
```
$ cd /path/to/princeton_aco568657
$ ruby ~/dev/aco-mets/code/validate-aco-mets.rb princeton_aco568657_mets.xml 
princeton_aco568657_mets.xml
/path/to/princeton_aco568657
{
    :struct_map_ie => [
        [0] "Incorrect div TYPE attribute. expected 'INTELLECTUAL_ENTITY' got 'INTELLECTUAL ENTITY'"
    ]
}
$ echo $?
1
```
