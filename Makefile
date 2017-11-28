.PHONY=
SCALA_VERSION=2.12.4

default: build-repo

setup:
	mkdir -p rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	mkdir -p repo/{x86_64,noarch}

clean:
	rm -rf rpmbuild
	rm -rf repo

s3-sync-from: setup
	aws --region eu-west-1 s3 sync s3://chaossystems-repositories/artifacts/rpm/chaossystems repo

s3-sync-to: build-repo
	aws --region eu-west-1 s3 sync --delete repo s3://chaossystems-repositories/artifacts/rpm/chaossystems

deploy: #: Deploy the repo to S3. This should only be used by CI, developers should use s3-sync-to.
	aws --region eu-west-1 s3 sync --delete --acl public-read repo s3://chaossystems-repositories/artifacts/rpm/chaossystems

build-repo: setup s3-sync-from ammonite-rpm chaossystems-repos-rpm chaossystems-i3-rpm chaossystems-devtools-rpm download-scala ironkey-rpm
	for a in repo{/x86_64,/noarch} ; do \
	       createrepo -v --update --deltas $$a/ ; \
	       done

ammonite-rpm: setup
	cd ammonite; $(MAKE)
	cp rpmbuild/RPMS/noarch/ammonite-*.rpm repo/noarch/

ironkey-rpm: setup
	cd ironkey; $(MAKE)
	cp rpmbuild/RPMS/noarch/ironkey-*.rpm repo/noarch/

chaossystems-repos-rpm: setup
	cd chaossystems-repos; $(MAKE)
	cp rpmbuild/RPMS/noarch/chaossystems-repos-*.rpm repo/noarch/

chaossystems-i3-rpm: setup
	cd chaossystems-i3; $(MAKE)
	cp rpmbuild/RPMS/noarch/chaossystems-i3-*.rpm repo/noarch/

chaossystems-devtools-rpm: setup
	cd chaossystems-devtools; $(MAKE)
	cp rpmbuild/RPMS/noarch/chaossystems-devtools-*.rpm repo/noarch/

download-scala:
	curl -LsO https://downloads.lightbend.com/scala/$(SCALA_VERSION)/scala-$(SCALA_VERSION).rpm
	cp scala-$(SCALA_VERSION).rpm repo/noarch/
	rm -f scala-$(SCALA_VERSION).rpm
