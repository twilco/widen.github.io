build:
	jekyll build

cleanMerge:
	git merge -s ours origin/master --no-edit
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

travisPublish: travisSetup build cleanMerge commitSiteOnly
	git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master > /dev/null 2>&1

travisSetup:
	git config user.name "Widen Travis-CI agent"
	git config user.email "travis@widen.com"
	git clone git@github.com:Widen/widen.github.io.git
	cd widen.github.io
	git checkout develop
