import { createDecorator } from "vs/platform/instantiation/common/instantiation";
import { INotificationService } from "vs/platform/notification/common/notification";

export const IPerplexityWindowService =
	createDecorator<IPerplexityWindowService>("perplexityWindowService");

export interface IPerplexityWindowService {
	openNewWindow(): void;
}

export class PerplexityWindowService implements IPerplexityWindowService {
	constructor(
		@INotificationService private notificationService: INotificationService,
	) {}

	openNewWindow(): void {
		this.notificationService.info("Opening Perplexity Window");
		// Implement actual window opening logic here
	}
}
