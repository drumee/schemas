# schemas
Drumee Schemas Packages
## Principles
- A file must not contain more than one routine


### To patch a routine
```console
bin/patch-from-file routine-file-path db_name|db_class 
```
A db_class may be one of yp|common|hub|drumate

### To patch a set of routines from a manifest file
```console
bin/patch-from-manifest patches-dir
```

### To create a manifest for patching from files that have been changed between two git commits
```console
bin/make-manifest git_hash1 git_hash2
```

### Build a new Drumee Schemas template from existing installation
```console
bin/make-templates git_hash1 git_hash2
```
