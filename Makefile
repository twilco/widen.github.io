SPACE := $(subst ,, )

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

createDraft: determineDraftPostName createPostFile

createPost: determinePostName createPostFile

createPostFile:
	touch $(NEW_POST)
	echo '---' >> $(NEW_POST)
	echo 'title: "$(title)"' >> $(NEW_POST)
	echo 'date: '`date +%Y-%m-%d` >> $(NEW_POST)
	echo '---' >> $(NEW_POST)

determineDraftPostName:
	$(eval NEW_POST := _drafts/`date +%Y-%m-%d`-$(subst $(SPACE),-,$(title)).md)

determinePostName:
	$(eval NEW_POST := _posts/`date +%Y-%m-%d`-$(subst $(SPACE),-,$(title)).md)

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
	git remote rm origin
	@git remote add origin "https://${GH_TOKEN}@${GH_REF}"
	git fetch --all
	git checkout develop
