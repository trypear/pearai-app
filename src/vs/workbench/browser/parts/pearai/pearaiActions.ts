import { registerAction2, Action2 } from "vs/platform/actions/common/actions";
import { ServicesAccessor } from "vs/platform/instantiation/common/instantiation";
import { IPearAIService } from "./pearaiService";
import { KeyCode, KeyMod } from "vs/base/common/keyCodes";

export class ClosePearAIAction extends Action2 {
	static readonly ID = "workbench.action.closePearAI";

	constructor() {
		super({
			id: ClosePearAIAction.ID,
			title: { value: "Close PearAI Popup", original: "Close PearAI Popup" },
			f1: true,
			keybinding: {
				weight: 200,
				primary: KeyCode.Escape,
			},
		});
	}

	run(accessor: ServicesAccessor): void {
		const pearaiService = accessor.get(IPearAIService);
		pearaiService.hide();
	}
}

export class TogglePearAIAction extends Action2 {
	static readonly ID = "workbench.action.togglePearAI";

	constructor() {
		super({
			id: TogglePearAIAction.ID,
			title: { value: "Toggle PearAI Popup", original: "Toggle PearAI Popup" },
			f1: true,
			keybinding: {
				weight: 200,
				primary: KeyMod.CtrlCmd | KeyCode.Digit7,
			},
		});
	}

	run(accessor: ServicesAccessor): void {
		const pearaiService = accessor.get(IPearAIService);
		console.log("TOGGLED PEARAI SERVICE 2");
		pearaiService.toggle();
	}
}

registerAction2(TogglePearAIAction);
registerAction2(ClosePearAIAction);
