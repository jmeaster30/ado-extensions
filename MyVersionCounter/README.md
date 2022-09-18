# MyVersionCounter

This is a version counter that is meant to run in the ADO Release Pipelines.

The version numbers that this extension can work with are in the format:
> `{Major}.{Minor}.{Patch}`

The pipeline agent must have permissions to read and write to the ADO Variable Groups since the permissions from this task are automatically pulled from the pipeline's permissions.

## Settings

### Variable Group Name (string)

The variable group name that holds the version number variable.

### Variable Name (string)

The variable that holds the version number.

### Max Patch Number (string)

The maximum value for the patch number.

### Max Minor Number (string)

The maximum value for the minor number.
