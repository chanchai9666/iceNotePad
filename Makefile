.DEFAULT_GOAL := help

.PHONY: help build release app run test package clean install uninstall

INSTALL_DIR ?= /Applications

## แสดงคำสั่งทั้งหมดที่สามารถใช้งานได้
help:
	@echo "=================================================="
	@echo "               iceNotePad Makefile"
	@echo "=================================================="
	@echo "Available commands:"
	@echo "  make build      - คอมไพล์โปรเจกต์ในโหมด Debug (swift build)"
	@echo "  make release    - คอมไพล์โปรเจกต์ในโหมด Release (swift build -c release)"
	@echo "  make test       - รันชุดทดสอบทั้งหมด (swift test)"
	@echo "  make app        - บิลด์และสร้าง macOS Application bundle (iceNotePad.app)"
	@echo "  make run        - บิลด์แอปพลิเคชันและเปิดใช้งานทันที"
	@echo "  make install    - บิลด์และติดตั้งแอปพลิเคชันไปยัง /Applications"
	@echo "  make uninstall  - ถอนการติดตั้งแอปพลิเคชันออกจาก /Applications"
	@echo "  make package    - สร้างแพ็กเกจ Release (.dmg และ .zip)"
	@echo "  make clean      - ล้างไฟล์บิลด์และแคชทั้งหมด (.build และ build/)"
	@echo "=================================================="

## คอมไพล์โปรเจกต์ในโหมด Debug
build:
	@echo "==> Building iceNotePad (Debug)..."
	swift build

## คอมไพล์โปรเจกต์ในโหมด Release
release:
	@echo "==> Building iceNotePad (Release)..."
	swift build -c release

## รัน Automated Unit Tests
test:
	@echo "==> Running Automated Tests..."
	swift test

## บิลด์และสร้าง macOS Application bundle (.app)
app:
	@echo "==> Building macOS App Bundle..."
	./scripts/build_app.sh

## บิลด์และเปิดใช้งานแอปพลิเคชัน
run: app
	@echo "==> Launching iceNotePad..."
	open build/iceNotePad.app

## บิลด์และติดตั้งแอปพลิเคชันไปยัง $(INSTALL_DIR)
install: app
	@echo "==> Installing iceNotePad to $(INSTALL_DIR)..."
	@mkdir -p "$(INSTALL_DIR)"
	@rm -rf "$(INSTALL_DIR)/iceNotePad.app"
	@cp -R "build/iceNotePad.app" "$(INSTALL_DIR)/"
	@echo "==> Installed iceNotePad.app to $(INSTALL_DIR) successfully."

## ถอนการติดตั้งแอปพลิเคชันออกจาก $(INSTALL_DIR)
uninstall:
	@echo "==> Uninstalling iceNotePad from $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/iceNotePad.app"
	@echo "==> Uninstalled iceNotePad.app from $(INSTALL_DIR) successfully."

## สร้างไฟล์ Release Package (.dmg และ .zip)
package:
	@echo "==> Packaging Release (.dmg / .zip)..."
	./scripts/package_release.sh

## ล้างไฟล์ Build Artifacts ทั้งหมด
clean:
	@echo "==> Cleaning build artifacts..."
	swift package clean
	rm -rf build .build
	@echo "==> Clean complete."

