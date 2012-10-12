## Vagrantfile examples for use with CFEngine

For now, all the documentation about the parameters is in the provided
Vagrantfile samples. You can find them in the samples/ directory.

`samples/community/` contains a simple Vagrantfile that instantiates a
single VM and configures it as a policy hub.

`samples/enterprise/` contains a more complex example that creates a
hub, four clients, and installs CFEngine Enterprise on all of them
(you need to provide your own Enterprise packages, you can get them
free for up to 25 nodes at http://cfengine.com/25free ).

`samples/master/` contains a Vagrantfile that downloads, compiles
and installs the latest version of CFEngine from the github repository.
This is useful for running tests on the latest version of the code.

## Feedback

If you have any comments, please contact me through Twitter
[@zzamboni](http://twitter.com/zzamboni) or look for me in the
[#cfengine IRC channel](http://webchat.freenode.net/?channels=cfengine).
