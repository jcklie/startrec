dev-install:
	pip install -e .

.PHONY: build
build:
	python setup.py build_ext --inplace

format:
	black -l 120 startrec/ tests/ setup.py

	isort --profile black startrec/ tests/ setup.py
