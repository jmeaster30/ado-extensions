# ado-extensions

This is a repository of my ado extensions.

### MyVersionCounter

Updates a version number that is stored in a variable group. This allows you to use the same version number for both a release and in your build pipelines.

The use case I had was we needed the version number during the main build pipeline but only wanted to update the version number after a particular stage in the release pipeline. This required the use of Variable Groups but the version number counters I could find did not work with variable groups. To be fair I only tried two of them.
