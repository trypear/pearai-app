/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
import { registerAction2, Action2 } from "vs/platform/actions/common/actions";
import { ServicesAccessor } from "vs/platform/instantiation/common/instantiation";
import { IPearOverlayService } from "./pearOverlayService";
import { KeyCode, KeyMod } from "vs/base/common/keyCodes";

export class ClosePearOverlayAction extends Action2 {
	static readonly ID = "workbench.action.closePearAI";

	constructor() {
		super({
			id: ClosePearOverlayAction.ID,
			title: { value: "Close PearAI Popup", original: "Close PearAI Popup" },
			f1: true,
			keybinding: {
				weight: 200,
				primary: KeyCode.Escape,
			},
		});
	}

	run(accessor: ServicesAccessor): void {
		const pearaiOverlayService = accessor.get(IPearOverlayService);
		pearaiOverlayService.hide();
	}
}

export class TogglePearOverlayAction extends Action2 {
	static readonly ID = "workbench.action.togglePearAI";

	constructor() {
		super({
			id: TogglePearOverlayAction.ID,
			title: { value: "Toggle PearAI Popup", original: "Toggle PearAI Popup" },
			f1: true,
			keybinding: {
				weight: 200,
				primary: KeyMod.CtrlCmd | KeyCode.KeyE,
			},
		});
	}

	run(accessor: ServicesAccessor): void {
		const pearaiOverlayService = accessor.get(IPearOverlayService);
		pearaiOverlayService.toggle();
	}
}

class UpdatePathnameAction extends Action2 {
	static readonly ID = "workbench.action.updatePathname";

	constructor() {
		super({
			id: UpdatePathnameAction.ID,
			title: {
				value: "Update PearAI Pathname",
				original: "Update PearAI Pathname",
			},
			f1: true,
		});
	}

	run(accessor: ServicesAccessor, pathname: string): void {
		const pearaiOverlayService = accessor.get(IPearOverlayService);
		pearaiOverlayService.updatePathname(pathname);
	}
}

registerAction2(TogglePearOverlayAction);
registerAction2(ClosePearOverlayAction);
registerAction2(UpdatePathnameAction);
