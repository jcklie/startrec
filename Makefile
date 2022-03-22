dev-install:
	pip install -e .

format:
	black -l 120 startrec tests setup.py

	isort --profile black startrec tests setup.py
