// src/vs/workbench/services/popupWindow/popupWindowService.ts

import { URI } from "vs/base/common/uri";
import { IOpenerService } from "vs/platform/opener/common/opener";
import { Disposable } from "vs/base/common/lifecycle";
import {
	IStorageService,
	StorageScope,
	StorageTarget,
} from "vs/platform/storage/common/storage";
import { IConfigurationService } from "vs/platform/configuration/common/configuration";

export class PopupWindowService extends Disposable {
	private static readonly POPUP_POSITION_KEY = "popupWindowPosition";
	private activePopups: Window[] = [];

	constructor(
		private readonly openerService: IOpenerService,
		private readonly storageService: IStorageService,
		private readonly configurationService: IConfigurationService,
	) {
		super();
	}

	openPopupWindow(
		url: string = "about:blank",
		title: string = "PopupWindow",
		width: number = 800,
		height: number = 600,
		left?: number,
		top?: number,
	): Window | null {
		const popupUrl = URI.parse(url);
		const position =
			left !== undefined && top !== undefined
				? { left, top }
				: this.getSavedPosition();

		// Open the window without specifying position
		const popup = window.open(
			popupUrl.toString(),
			title,
			`width=${width},height=${height},resizable=yes,scrollbars=yes`,
		);

		if (popup) {
			// Set position after opening
			popup.moveTo(position.left, position.top);
			popup.focus();
			this.setupPopup(popup);
			this.activePopups.push(popup);
			return popup;
		} else {
			console.error("Popup window was blocked");
			return null;
		}
	}

	private setupPopup(popup: Window): void {
		popup.addEventListener("keydown", (event) => {
			if (event.key === "Escape") {
				this.closePopup(popup);
			}
		});

		popup.addEventListener("unload", () => {
			this.savePosition(popup);
			this.activePopups = this.activePopups.filter((p) => p !== popup);
		});

		const theme = this.configurationService.getValue<string>(
			"workbench.colorTheme",
		);
		popup.document.body.classList.add(`vscode-theme-${theme}`);
	}

	closePopup(popup: Window): void {
		popup.close();
		this.activePopups = this.activePopups.filter((p) => p !== popup);
	}

	storePopup(popup: Window): void {
		this.activePopups.push(popup);
	}

	closeAllPopups(): void {
		this.activePopups.forEach((popup) => popup.close());
		this.activePopups = [];
	}

	private getSavedPosition(): { left: number; top: number } {
		const savedPosition = this.storageService.get(
			PopupWindowService.POPUP_POSITION_KEY,
			StorageScope.APPLICATION,
		);
		if (savedPosition) {
			return JSON.parse(savedPosition);
		}
		return { left: 100, top: 100 };
	}

	private savePosition(popup: Window): void {
		const position = { left: popup.screenX, top: popup.screenY };
		this.storageService.store(
			PopupWindowService.POPUP_POSITION_KEY,
			JSON.stringify(position),
			StorageScope.APPLICATION,
			StorageTarget.USER,
		);
	}

	setPopupContent(popup: Window, content: string): void {
		if (!popup || !popup.document) {
			console.error("Invalid popup window");
			return;
		}

		popup.document.open();
		popup.document.write(content);
		popup.document.close();

		// Log to check if this method is being called
		console.log("Content set in popup:", content.substring(0, 100) + "...");
	}

	async loadUrlInPopup(popup: Window, url: string): Promise<void> {
		await this.openerService.open(URI.parse(url), {
			openToSide: false,
			// Use any other relevant options from IOpenerService
		});

		// Manually set the URL of the popup window
		popup.location.href = url;
	}

	override dispose(): void {
		this.closeAllPopups();
		super.dispose();
	}
}
