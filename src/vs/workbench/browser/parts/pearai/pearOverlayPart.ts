import { Part } from "vs/workbench/browser/part";
import {
	IWorkbenchLayoutService,
	Parts,
} from "vs/workbench/services/layout/browser/layoutService";
import { IThemeService } from "vs/platform/theme/common/themeService";
import { IStorageService } from "vs/platform/storage/common/storage";
import { $, getActiveWindow } from "vs/base/browser/dom";
// import { CancellationTokenSource } from "vs/base/common/cancellation";
import { IInstantiationService } from "vs/platform/instantiation/common/instantiation";

// imports that violate vscode source organization
import {
	// IWebviewViewService,
	WebviewView,
} from "vs/workbench/contrib/webviewView/browser/webviewViewService";
import { WebviewService } from "vs/workbench/contrib/webview/browser/webviewService";

export class PearOverlayPart extends Part {
	static readonly ID = "workbench.parts.pearoverlay";

	//#region IView

	readonly minimumWidth: number = 300;
	readonly maximumWidth: number = 800;
	readonly minimumHeight: number = 200;
	readonly maximumHeight: number = 600;

	//#endregion

	private fullScreenOverlay: HTMLElement | undefined;
	private popupAreaOverlay: HTMLElement | undefined;
	private webviewView: WebviewView | undefined;
	private _webviewService: WebviewService | undefined;

	private state: "loading" | "open" | "closed" = "loading";

	constructor(
		@IThemeService themeService: IThemeService,
		@IStorageService storageService: IStorageService,
		@IWorkbenchLayoutService layoutService: IWorkbenchLayoutService,
		// @IWebviewViewService
		// private readonly _webviewViewService: IWebviewViewService,
		@IInstantiationService
		private readonly _instantiationService: IInstantiationService,
	) {
		super(
			PearOverlayPart.ID,
			{ hasTitle: false },
			themeService,
			storageService,
			layoutService,
		);

		this._webviewService =
			this._instantiationService.createInstance(WebviewService);

		this.initialize();
	}

	private async initialize() {
		// 1. create an IOverlayWebview
		const webview = this._webviewService!.createWebviewOverlay({
			title: "PearAI",
			options: {
				enableFindWidget: false,
			},
			contentOptions: {
				allowScripts: true,
				localResourceRoots: [
					// Uri.joinPath(this._pearaiUri, 'out'),
					// URI.joinPath(pearaiUri, 'webview-ui/build'),
				],
			},
			extension: undefined,
		});

		webview.claim(this, getActiveWindow(), undefined);

		webview.setHtml(this.getTestWebviewContent());

		// 2. initialize this.webviewView by creating a WebviewView
		this.webviewView = {
			webview,
			onDidChangeVisibility: () => {
				return { dispose: () => {} };
			},
			onDispose: () => {
				return { dispose: () => {} };
			},

			get title(): string | undefined {
				return "PearAI";
			},
			set title(value: string | undefined) {},

			get description(): string | undefined {
				return undefined;
			},
			set description(value: string | undefined) {},

			get badge() {
				return undefined;
			},
			set badge(badge) {},

			dispose: () => {
				// Only reset and clear the webview itself. Don't dispose of the view container
				// this._activated = false;
				// this._webview.clear();
				// // this._webviewDisposables.clear();
			},

			show: (preserveFocus) => {
				// this.viewService.openView(this.id, !preserveFocus);
			},
		};

		// this.webviewView = this.getTestWebviewContent();

		// 3. ask the webviewViewService to connect our webviewView to the webviewViewProvider, i.e., HelloWorldPanel
		// const source = new CancellationTokenSource(); // todo add to disposables
		// await this._webviewViewService.resolve(
		// 	"pearai.magicWebview",
		// 	this.webviewView!,
		// 	source.token,
		// );

		// if both content and webview are ready, end loading state and open
		if (this.popupAreaOverlay && this.webviewView) {
			this.webviewView?.webview.layoutWebviewOverElement(this.popupAreaOverlay);
			this.open();
		} else {
			// hide stuff while we load
			this.webviewView!.webview.container.style.display = "none";
		}
	}

	private getTestWebviewContent(): string {
		return `
			<!DOCTYPE html>
			<html lang="en">
			<head>
				<meta charset="UTF-8">
				<meta name="viewport" content="width=device-width, initial-scale=1.0">
				<title>PearAI Test Webview</title>
				<style>
					.content {
						text-align: center;
						padding: 20px;
						background-color: white;
						border-radius: 8px;
						box-shadow: 0 2px 10px rgba(0,0,0,0.1);
					}
				</style>
			</head>
			<body>
				<div class="content">
					<h1>Hello from PearAI!</h1>
					<p>This is a test webview content.</p>
				</div>
			</body>
			</html>
		`;
	}

	protected override createContentArea(element: HTMLElement): HTMLElement {
		// create the full screen overlay. this serves as a click target for closing pearai
		this.element = element;
		this.fullScreenOverlay = element; // use the pearOverlayPart root element as the fullScreenOverlay
		this.fullScreenOverlay.style.zIndex = "-10";
		this.fullScreenOverlay.style.position = "absolute";
		this.fullScreenOverlay.style.top = "0";
		this.fullScreenOverlay.style.left = "0";
		this.fullScreenOverlay.style.right = "0";
		this.fullScreenOverlay.style.bottom = "0";
		this.fullScreenOverlay.style.backgroundColor = "rgba(0, 0, 0, 0.2)";

		// create the popup area overlay. this is just a target for webview to layout over
		this.popupAreaOverlay = $("div.pearai-popup-area-overlay");
		this.popupAreaOverlay.style.position = "absolute"; // couldn't get it to work with relative for some reason
		this.popupAreaOverlay.style.margin = "0px";
		this.popupAreaOverlay.style.top = "0";
		this.popupAreaOverlay.style.left = "0";
		this.popupAreaOverlay.style.right = "0";
		this.popupAreaOverlay.style.bottom = "0";
		this.element.appendChild(this.popupAreaOverlay);

		// if both content and webview are ready, end loading state and open
		if (this.popupAreaOverlay && this.webviewView) {
			this.webviewView?.webview.layoutWebviewOverElement(this.popupAreaOverlay);
			this.open();
		} else {
			// hide stuff while we load
			this.fullScreenOverlay!.style.display = "none";
		}

		return this.fullScreenOverlay!;
	}

	override layout(
		width: number,
		height: number,
		top: number,
		left: number,
	): void {
		super.layout(width, height, top, left);
		if (this.fullScreenOverlay) {
			this.fullScreenOverlay!.style.width = `${width}px`;
			this.fullScreenOverlay!.style.height = `${height}px`;
		}

		if (this.state === "open") {
			this.webviewView!.webview.layoutWebviewOverElement(
				this.popupAreaOverlay!,
			);
		}
	}

	private open() {
		this.state = "open";
		this.fullScreenOverlay!.style.zIndex = "95";

		const container = this.webviewView!.webview.container;
		container.style.display = "flex";
		container.style.boxSizing = "border-box";
		container.style.boxShadow = "0 0 20px 0 rgba(0, 0, 0, 0.5)";
		// container.style.borderRadius = '12px';
		container.style.backgroundColor = "white";
		container.style.zIndex = "1000";

		// Add faster bounce animation
		container.style.animation =
			"pearaiBounceIn 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275)";
		container.style.transformOrigin = "center";

		// Define keyframes for faster bounce animation and fade out
		const style = document.createElement("style");
		style.textContent = `
			@keyframes pearaiBounceIn {
				0% { transform: scale(0.95); opacity: 0; }
				70% { transform: scale(1.02); opacity: 1; }
				100% { transform: scale(1); opacity: 1; }
			}
			@keyframes pearaiFadeOut {
				0% { opacity: 1; }
				100% { opacity: 0; }
			}
		`;
		document.head.appendChild(style);

		this.fullScreenOverlay?.addEventListener("click", () => {
			this.close();
		});

		this.webviewView!.webview.layoutWebviewOverElement(this.popupAreaOverlay!);
		this.focus();
	}

	private close() {
		this.state = "closed";
		const container = this.webviewView!.webview.container;

		// Apply fade-out animation
		container.style.animation = "pearaiFadeOut 0.2s ease-out";

		// Hide elements after animation completes
		setTimeout(() => {
			this.fullScreenOverlay!.style.zIndex = "-10";
			container.style.display = "none";
		}, 20); // 20ms matches the animation duration
	}

	private toggleOpenClose() {
		this.state === "open" ? this.close() : this.open();
	}

	focus(): void {
		if (this.webviewView) {
			this.webviewView.webview.focus();
		}
	}

	show(): void {
		if (this.state === "loading") {
			console.warn("Can't open PearAI while loading");
			return;
		}

		this.open();
	}

	hide(): void {
		if (this.state === "loading") {
			console.warn("Can't close PearAI while loading");
			return;
		}
		this.close();
	}

	toggle(): void {
		if (this.state === "loading") {
			console.warn("Can't toggle PearAI while loading");
			return;
		}
		this.toggleOpenClose();
	}

	toJSON(): object {
		return {
			type: Parts.PEAROVERLAY_PART,
		};
	}
}
