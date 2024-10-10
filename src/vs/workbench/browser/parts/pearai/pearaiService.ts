import {
	registerSingleton,
	InstantiationType,
} from "vs/platform/instantiation/common/extensions";
import { Disposable, IDisposable } from "vs/base/common/lifecycle";
import { PearAIPart } from "./pearaiPart";
import {
	createDecorator,
	IInstantiationService,
} from "vs/platform/instantiation/common/instantiation";
import { IEditorService } from "vs/workbench/services/editor/common/editorService";
import { ITerminalService } from "vs/workbench/contrib/terminal/browser/terminal";

export const IPearAIService = createDecorator<IPearAIService>("pearaiService");

export interface IPearAIService extends IDisposable {
	readonly _serviceBrand: undefined;

	/**
	 * Returns the PearAIPart instance.
	 */
	readonly pearaiPart: PearAIPart;

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
}

export class PearAIService extends Disposable implements IPearAIService {
	declare readonly _serviceBrand: undefined;

	private readonly _pearaiPart: PearAIPart;

	constructor(
		@IInstantiationService
		private readonly instantiationService: IInstantiationService,
		@IEditorService private readonly _editorService: IEditorService,
		@ITerminalService private readonly _terminalService: ITerminalService,
	) {
		super();
		this._pearaiPart = this.instantiationService.createInstance(PearAIPart);
		this.registerListeners();
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

	get pearaiPart(): PearAIPart {
		return this._pearaiPart;
	}

	show(): void {
		this._pearaiPart.show();
	}

	hide(): void {
		this._pearaiPart.hide();
	}

	toggle(): void {
		this._pearaiPart.toggle();
	}

	override dispose(): void {
		super.dispose();
		this._pearaiPart.dispose();
	}
}

registerSingleton(IPearAIService, PearAIService, InstantiationType.Eager);
