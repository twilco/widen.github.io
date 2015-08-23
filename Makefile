build:
	jekyll build

cleanMerge:
	git merge -s ours master --no-edit
	git checkout master

commitSiteOnly:
	find . -maxdepth 1 ! -name '_site' ! -name '.*' | xargs rm -rf
	cp -pR _site/* .
	rm -rf _site
	git add .
	git commit -a -m "publish blog update"

publish: build cleanMerge commitSiteOnly
	git push origin master

setup:
	gem install bundle
	bundle install

start:
	jekyll serve --drafts

travisBuild:
	bundle exec jekyll build

travisPublish: travisSetup travisBuild cleanMerge commitSiteOnly
	git push origin master

travisSetup:
	git config user.name "Widen Travis-CI agent"
	git config user.email "travis@widen.com"
	git clone "https://${GH_TOKEN}@${GH_REF}"
	cd widen.github.io
	git fetch origin
	git checkout master
	git checkout develop
