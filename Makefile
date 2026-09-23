# HackShack OpenCode Tutorial - Makefile
#
# Targets:
#   make build        - Clone instrospect + build Docker image
#   make up           - Start the container
#   make down         - Stop the container
#   make restart      - Rebuild and restart
#   make validate     - Run validation checks
#   make video-web    - Record web variant (Playwright, all labs)
#   make video-cli    - Record CLI variant (asciinema+expect, all labs)
#   make video-lab1   - Record Lab 1 only (web)
#   make video-lab2   - Record Lab 2 only (web)
#   make video-lab3   - Record Lab 3 only (web)
#   make video-lab4   - Record Lab 4 only (web)
#   make video-vhs    - Record shell-only portions (VHS, deterministic)
#   make clean        - Remove containers, recordings, and instrospect clone
#   make help         - Show this help

.PHONY: build up down restart validate video video-web video-cli video-vhs video-lab1 video-lab2 video-lab3 video-lab4 clean help setup-playwright

# ---- Config ----

COMPOSE := docker compose
CONTAINER := hackshack-lab
RECORDINGS := recordings

# ---- Bootstrap ----

build:
	@echo "--- Building HackShack container ---"
	./build.sh

build-quick:
	@echo "--- Quick build (no instrospect, Lab 2D limited) ---"
	@mkdir -p instrospect/src/sandbox
	@echo 'import sys; print("[WARN] instrospect not available -- built without HPE VPN."); sys.exit(1)' > instrospect/src/skill_review.py
	@echo 'import sys; print("[WARN] instrospect not available -- built without HPE VPN."); sys.exit(1)' > instrospect/src/sandbox/bootstrap.py
	$(COMPOSE) build

up:
	$(COMPOSE) up -d
	@echo ""
	@echo "  Tutorial: http://localhost:8080"
	@echo "  OpenCode: http://localhost:5178"
	@echo ""

down:
	$(COMPOSE) down

restart: build up

# ---- Validation ----

validate:
	docker exec $(CONTAINER) bash tests/validate-env.sh

# ---- Video Recording: Web (Playwright + browser) ----

setup-playwright:
	@if [ ! -d node_modules/playwright ]; then \
		echo "[*] Installing Playwright..."; \
		npm install playwright; \
		npx playwright install chromium; \
	fi

video: video-web

video-web: setup-playwright up
	@echo "--- Recording web variant (all labs) ---"
	@mkdir -p $(RECORDINGS)
	node record-demo.js

video-lab1: setup-playwright up
	@echo "--- Recording Lab 1 (web) ---"
	@mkdir -p $(RECORDINGS)
	node record-demo.js --lab 1

video-lab2: setup-playwright up
	@echo "--- Recording Lab 2 (web) ---"
	@mkdir -p $(RECORDINGS)
	node record-demo.js --lab 2

video-lab3: setup-playwright up
	@echo "--- Recording Lab 3 (web) ---"
	@mkdir -p $(RECORDINGS)
	node record-demo.js --lab 3

video-lab4: setup-playwright up
	@echo "--- Recording Lab 4 (web) ---"
	@mkdir -p $(RECORDINGS)
	node record-demo.js --lab 4

video-headless: setup-playwright up
	@echo "--- Recording full demo (headless, web) ---"
	@mkdir -p $(RECORDINGS)
	node record-demo.js --headless

# ---- Video Recording: CLI (asciinema + expect inside container) ----

video-cli: up
	@echo "--- Recording CLI variant (asciinema + expect) ---"
	@mkdir -p $(RECORDINGS)
	bash record-cli.sh

video-cli-lab1: up
	@echo "--- Recording Lab 1 (CLI) ---"
	@mkdir -p $(RECORDINGS)
	bash record-cli.sh --lab 1

video-cli-lab2: up
	@echo "--- Recording Lab 2 (CLI) ---"
	@mkdir -p $(RECORDINGS)
	bash record-cli.sh --lab 2

video-cli-lab3: up
	@echo "--- Recording Lab 3 (CLI) ---"
	@mkdir -p $(RECORDINGS)
	bash record-cli.sh --lab 3

video-cli-lab4: up
	@echo "--- Recording Lab 4 (CLI) ---"
	@mkdir -p $(RECORDINGS)
	bash record-cli.sh --lab 4

# ---- Video Recording: VHS (deterministic shell-only) ----

video-vhs: up
	@echo "--- Recording shell-only portions (VHS) ---"
	@mkdir -p $(RECORDINGS)
	vhs hackshack-cli.tape

# ---- Cleanup ----

clean:
	$(COMPOSE) down -v 2>/dev/null || true
	rm -rf instrospect/
	rm -rf recordings/
	rm -rf node_modules/

# ---- Help ----

help:
	@echo ""
	@echo "HackShack OpenCode Tutorial"
	@echo "==========================="
	@echo ""
	@echo "Bootstrap:"
	@echo "  make build            Full build (requires HPE VPN for instrospect)"
	@echo "  make build-quick      Quick build (no instrospect, Lab 2D limited)"
	@echo "  make up               Start container"
	@echo "  make down             Stop container"
	@echo "  make restart          Rebuild + restart"
	@echo "  make validate         Run environment checks"
	@echo ""
	@echo "Web recording (Playwright + browser):"
	@echo "  make video-web        Record all labs (web UI)"
	@echo "  make video-lab1       Record Lab 1 only"
	@echo "  make video-lab2       Record Lab 2 only"
	@echo "  make video-lab3       Record Lab 3 only"
	@echo "  make video-lab4       Record Lab 4 only"
	@echo "  make video-headless   Record all labs headless"
	@echo ""
	@echo "CLI recording (asciinema + expect):"
	@echo "  make video-cli        Record all labs (terminal)"
	@echo "  make video-cli-lab1   Record Lab 1 only"
	@echo "  make video-cli-lab2   Record Lab 2 only"
	@echo "  make video-cli-lab3   Record Lab 3 only"
	@echo "  make video-cli-lab4   Record Lab 4 only"
	@echo ""
	@echo "Shell-only recording (VHS, deterministic):"
	@echo "  make video-vhs        Record shell portions as GIF/MP4"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean            Remove containers, recordings, node_modules"
	@echo ""
	@echo "URLs (after 'make up'):"
	@echo "  Tutorial:  http://localhost:8080"
	@echo "  OpenCode:  http://localhost:5178"
	@echo ""
