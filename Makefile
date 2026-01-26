BASE_PYTHON ?= python3
PYTHON := .venv/bin/python
OUT ?= dist
PKG_DIR ?= .

PLINK_URL = https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20250819.zip
PLINK_ZIP = bin/plink_linux_x86_64_20250819.zip
PLINK_BIN = bin/plink
CONDA_ENV_NAME = treemix_env

.DEFAULT_GOAL := all
SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.PHONY: all clean conda_env check-scripts test lint build run help plink
.SUFFIXES:
.DELETE_ON_ERROR:

hello: ## Check if the make file is working
	@echo "Makefile is working"

conda_env: environment.yml ## Install all the packages and dependencies
	@if conda env list | grep -q "^$(CONDA_ENV_NAME)"; then \
		echo "Environment '$(CONDA_ENV_NAME)' already exists. Syncing packages..."; \
		conda env update -n $(CONDA_ENV_NAME) -f environment.yml --prune; \
	else \
		echo "Environment '$(CONDA_ENV_NAME)' not found. Creating from the environment.yml..."; \
		conda env create -f environment.yml; \
	fi
	@echo "Environment is ready. Please run 'conda actiavte $(CONDA_ENV_NAME)' to activate it."
	@echo "[conda_env] ok"

clean: ## Remove artifacts
	@rm -rf __pycache__ .pytest_cache .mypy_cache build dist *.egg-info
	@find . -name '*.pyc' -delete
	@find . -name "*.egg-info" -exec rm -rf {} +
	@ echo "[clean] removed build/test artifacts"

lint: ## Static checks (ruff)
	@conda run -n $(CONDA_ENV_NAME) ruff check . || (echo '[lint] ruff failed' >&2; exit 1)
	@echo "[lint] ok"

plink:
	@if [ ! -f bin/plink/plink ]; then \
		echo "PLINK not found, downloading..."; \
		mkdir -p bin/plink; \
		wget -O bin/plink/plink_linux_x86_64_20250819.zip https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20250819.zip; \
		unzip -o bin/plink/plink_linux_x86_64_20250819.zip -d bin/plink; \
	else \
		echo "PLINK already exists in bin"; \
	fi
	@./bin/plink/plink --version
	@echo "[plink] ok"

check-scripts: # Fail if any of these bash files have warnring
	@shellcheck src/plink_script.sh || (echo '[shellcheck] failed' >&2; exit 1)
	@echo "[shellcheck] ok"
