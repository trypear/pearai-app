/* eslint-disable header/header */

import {
	registerSingleton,
	InstantiationType,
} from "../../../../platform/instantiation/common/extensions.js";
import { Disposable, IDisposable } from "../../../../base/common/lifecycle.js";
import { AgentOverlayPart } from "./agentOverlayPart.js";
import {
	createDecorator,
	IInstantiationService,
} from "../../../../platform/instantiation/common/instantiation.js";
import { IEditorService } from "../../../../workbench/services/editor/common/editorService.js";
import { ITerminalService } from "../../../../workbench/contrib/terminal/browser/terminal.js";
import { CommandsRegistry } from "../../../../platform/commands/common/commands.js";

export const IAgentOverlayService = createDecorator<IAgentOverlayService>(
	"agentOverlayService",
);

export interface IAgentOverlayService extends IDisposable {
	readonly _serviceBrand: undefined;

	/**
	 * Returns the PearOverlayPart instance.
	 */
	readonly agentOverlayPart: AgentOverlayPart;

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

export class AgentOverlayService
	extends Disposable
	implements IAgentOverlayService
{
	declare readonly _serviceBrand: undefined;

	private readonly _agentOverlayPart: AgentOverlayPart;

	constructor(
		@IInstantiationService
		private readonly instantiationService: IInstantiationService,
		@IEditorService private readonly _editorService: IEditorService,
		@ITerminalService private readonly _terminalService: ITerminalService,
		// @ICommandService private readonly commandService: ICommandService,
	) {
		super();
		this._agentOverlayPart =
			this.instantiationService.createInstance(AgentOverlayPart);
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
		CommandsRegistry.registerCommand("pearai.isAgentOverlayVisible", (accessor) => {
			const overlayService = accessor.get(IAgentOverlayService);
			return overlayService.isVisible();
		});

		CommandsRegistry.registerCommand("pearai.showAgentOverlay", (accessor) => {
			const overlayService = accessor.get(IAgentOverlayService);
			overlayService.show();
		});

		CommandsRegistry.registerCommand("pearai.hideAgentOverlay", (accessor) => {
			const overlayService = accessor.get(IAgentOverlayService);
			overlayService.hide();
		});

		CommandsRegistry.registerCommand("pearai.toggleAgentOverlay", (accessor) => {
			const overlayService = accessor.get(IAgentOverlayService);
			overlayService.toggle();
		});

		CommandsRegistry.registerCommand("pearai.lockAgentOverlay", (accessor) => {
			const overlayService = accessor.get(IAgentOverlayService);
			overlayService.lock();
		});

		CommandsRegistry.registerCommand("pearai.unlockAgentOverlay", (accessor) => {
			const overlayService = accessor.get(IAgentOverlayService);
			overlayService.unlock();
		});

		CommandsRegistry.registerCommand("pearai.isAgentOverlayLocked", (accessor) => {
			const overlayService = accessor.get(IAgentOverlayService);
			return overlayService.isLocked();
		});

		CommandsRegistry.registerCommand("pearai.hideAgentOverlayLoadingMessage", (accessor) => {
			const overlayService = accessor.get(IAgentOverlayService);
			overlayService.hideOverlayLoadingMessage();
		});
	}

	get agentOverlayPart(): AgentOverlayPart {
		return this._agentOverlayPart;
	}

	show(): void {
		this._agentOverlayPart.show();
	}

	hide(): void {
		this._agentOverlayPart.hide();
	}

	hideOverlayLoadingMessage(): void {
		this._agentOverlayPart.hideOverlayLoadingMessage();
	}

	toggle(): void {
		this._agentOverlayPart.toggle();
	}

	lock(): void {
		this._agentOverlayPart.lock();
	}

	unlock(): void {
		this._agentOverlayPart.unlock();
	}

	isLocked(): boolean {
		return this._agentOverlayPart.isLocked;
	}

	override dispose(): void {
		super.dispose();
		this._agentOverlayPart.dispose();
	}

	isVisible(): boolean {
		return this._agentOverlayPart.isVisible();
	}
}

registerSingleton(
	IAgentOverlayService,
	AgentOverlayService,
	InstantiationType.Eager,
);
