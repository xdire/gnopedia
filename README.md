# gnopedia
Curious case of RPCs masquerading in smart contracts

# Design for the implementation 
Find it here [Package design PRD](r/gnopedia/docs/prd.md)

# Testing strategy

1) Run `gnodev *` to launch the package


2) Add test key to `gno` keychain: `gnokey add --recover test1`
Default mnemonic is (check with the `gnodev` output):
```
source bonus chronic canvas draft south burst lottery vacant surface solve popular case indicate oppose farm nothing bullet exhibit title speed wink action roast
```

3) Use the help section of the UI to copy development commands to use `Gno` transactions as following

### Create new Article
```
gnokey maketx call -pkgpath "gno.land/r/foundations/gnopedia" -func "NewArticle" -gas-fee 1000000ugnot -gas-wanted 2000000 -send "" -broadcast -chainid "dev" -args "1" -args "1" -args "0" -args "Test Article" -args "Lorem Ipsum Dolem" -remote "tcp://127.0.0.1:26657" 
```

### Approve article version to be published (second args 0)
```
gnokey maketx call -pkgpath "gno.land/r/foundations/gnopedia" -func "ApproveArticleVersion" -gas-fee 1000000ugnot -gas-wanted 2000000 -send "" -broadcast -chainid "dev" -args 0 -args 0 -remote "tcp://127.0.0.1:26657" TEST1-KEY-SIGNATURE
```

### Propose change for the article
```
 gnokey maketx call -pkgpath "gno.land/r/foundations/gnopedia" -func "ProposeArticleVersion" -gas-fee 1000000ugnot -gas-wanted 2000000
 -send "" -broadcast -chainid "dev" -args "0" -args "New title text" -args "New content please approve" -remote "tcp://127.0.0.1:26657" TEST1-KEY-SIGNATURE
```

### Vote for the newly arrived change (second args 1)
```
gnokey maketx call -pkgpath "gno.land/r/foundations/gnopedia" -func "ApproveArticleVersion" -gas-fee 1000000ugnot -gas-wanted 2000000
 -send "" -broadcast -chainid "dev" -args 0 -args 1 -remote "tcp://127.0.0.1:26657" TEST1-KEY-SIGNATURE
```

### Try to downvote existing article
```
gnokey maketx call -pkgpath "gno.land/r/foundations/gnopedia" -func "DenyArticleVersion" -gas-fee 1000000ugnot -gas-wanted 2000000 -send "" -broadcast -chainid "dev" -args 0 -args 1 -remote "tcp://127.0.0.1:26657" TEST1-KEY-SIGNATURE 
```

After all of those actions — new version of article can be proposed by the new or other 
author looking to be rewarded for the write-up