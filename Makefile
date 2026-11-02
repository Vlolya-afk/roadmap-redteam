.PHONY: install serve build deploy new check clean

install:
	python -m venv .venv
	. .venv/bin/activate && pip install -r requirements.txt

serve:
	. .venv/bin/activate && mkdocs serve

build:
	. .venv/bin/activate && mkdocs build --strict

deploy:
	. .venv/bin/activate && mkdocs gh-deploy --force

# make new MODULE=m05-windows-ad LESSON=l06-tokens
new:
	./scripts/new-lesson.sh $(MODULE) $(LESSON)

check:
	python scripts/check-links.py

clean:
	rm -rf site .cache
