/* eslint-disable header/header */

import {
	registerSingleton,
	InstantiationType,
} from "../../../../platform/instantiation/common/extensions.js";
import { Disposable, IDisposable } from "../../../../base/common/lifecycle.js";
import { PearOverlayPart } from "./pearOverlayPart.js";
import {
	createDecorator,
	IInstantiationService,
} from "../../../../platform/instantiation/common/instantiation.js";
import { IEditorService } from "../../../../workbench/services/editor/common/editorService.js";
import { ITerminalService } from "../../../../workbench/contrib/terminal/browser/terminal.js";
import { CommandsRegistry } from "../../../../platform/commands/common/commands.js";

export const IPearOverlayService = createDecorator<IPearOverlayService>(
	"pearaiOverlayService",
);

export interface IPearOverlayService extends IDisposable {
	readonly _serviceBrand: undefined;

	/**
	 * Returns the PearOverlayPart instance.
	 */
	readonly pearOverlayPart: PearOverlayPart;

	/**
	 * Shows the PearAI popup.
	 */
	show(): void;

	/**
	 * Hides the PearAI popup.
	 */
	hide(): void;

	/**
	 * Toggles the visibility of the PearAI popup.
	 */
	toggle(): void;

	/**
	 * Returns true if the PearAI popup is visible.
	 */
	isVisible(): boolean;

	/**
	 * Locks the PearAI popup.
	 */
	lock(): void;

	/**
	 * Unlocks the PearAI popup.
	 */
	unlock(): void;

	/**
	 * Returns true if the PearAI popup is locked.
	 */
	isLocked(): boolean;

	/**
	 * Hides the loading overlay message.
	 */
	hideOverlayLoadingMessage(): void;
}

export class PearOverlayService
	extends Disposable
	implements IPearOverlayService
{
	declare readonly _serviceBrand: undefined;

	private readonly _pearOverlayPart: PearOverlayPart;

	constructor(
		@IInstantiationService
		private readonly instantiationService: IInstantiationService,
		@IEditorService private readonly _editorService: IEditorService,
		@ITerminalService private readonly _terminalService: ITerminalService,
		// @ICommandService private readonly commandService: ICommandService,
	) {
		super();
		this._pearOverlayPart =
			this.instantiationService.createInstance(PearOverlayPart);
		this.registerListeners();
		this.registerCommands();
	}

	private registerListeners(): void {
		this._register(
			this._editorService.onDidActiveEditorChange(() => {
				this.hide();
			}),
		);

		this._register(
			this._terminalService.onDidFocusInstance(() => {
				this.hide();
			}),
		);
	}

	private registerCommands(): void {
		// Register commands for external use e.g. in pearai submodule
		CommandsRegistry.registerCommand("pearai.isOverlayVisible", (accessor) => {
			const overlayService = accessor.get(IPearOverlayService);
			return overlayService.isVisible();
		});

		CommandsRegistry.registerCommand("pearai.showOverlay", (accessor) => {
			const overlayService = accessor.get(IPearOverlayService);
			overlayService.show();
		});

		CommandsRegistry.registerCommand("pearai.hideOverlay", (accessor) => {
			const overlayService = accessor.get(IPearOverlayService);
			overlayService.hide();
		});

		CommandsRegistry.registerCommand("pearai.toggleOverlay", (accessor) => {
			const overlayService = accessor.get(IPearOverlayService);
			overlayService.toggle();
		});

		CommandsRegistry.registerCommand("pearai.lockOverlay", (accessor) => {
			const overlayService = accessor.get(IPearOverlayService);
			overlayService.lock();
		});

		CommandsRegistry.registerCommand("pearai.unlockOverlay", (accessor) => {
			const overlayService = accessor.get(IPearOverlayService);
			overlayService.unlock();
		});

		CommandsRegistry.registerCommand("pearai.isOverlayLocked", (accessor) => {
			const overlayService = accessor.get(IPearOverlayService);
			return overlayService.isLocked();
		});

		CommandsRegistry.registerCommand("pearai.hideOverlayLoadingMessage", (accessor) => {
			const overlayService = accessor.get(IPearOverlayService);
			overlayService.hideOverlayLoadingMessage();
		});
	}

	get pearOverlayPart(): PearOverlayPart {
		return this._pearOverlayPart;
	}

	show(): void {
		this._pearOverlayPart.show();
	}

	hide(): void {
		this._pearOverlayPart.hide();
	}

	hideOverlayLoadingMessage(): void {
		this._pearOverlayPart.hideOverlayLoadingMessage();
	}

	toggle(): void {
		this._pearOverlayPart.toggle();
	}

	lock(): void {
		this._pearOverlayPart.lock();
	}

	unlock(): void {
		this._pearOverlayPart.unlock();
	}

	isLocked(): boolean {
		return this._pearOverlayPart.isLocked;
	}

	override dispose(): void {
		super.dispose();
		this._pearOverlayPart.dispose();
	}

	isVisible(): boolean {
		return this._pearOverlayPart.isVisible();
	}
}

registerSingleton(
	IPearOverlayService,
	PearOverlayService,
	InstantiationType.Eager,
);
