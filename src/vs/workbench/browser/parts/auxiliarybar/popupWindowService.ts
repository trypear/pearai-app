// src/vs/workbench/services/popupWindow/popupWindowService.ts

import { URI } from "vs/base/common/uri";
import { IOpenerService } from "vs/platform/opener/common/opener";

export class PopupWindowService {
	constructor(private openerService: IOpenerService) {}

	openPopupWindow(
		url: string = "about:blank",
		title: string = "PopupWindow",
	): Window | null {
		const popupUrl = URI.parse(url);
		const features =
			"width=600,height=400,resizable=yes,scrollbars=yes,status=no";

		const popup = window.open(popupUrl.toString(), title, features);

		if (popup) {
			popup.focus();
			return popup;
		} else {
			console.error("Popup window was blocked");
			return null;
		}
	}

	// Add more methods as needed
}
