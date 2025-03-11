import { IURLHandler, IURLService } from 'vs/platform/url/common/url';
import { URI } from 'vs/base/common/uri';
import { IAuthenticationService } from 'vs/workbench/services/authentication/common/authentication';
import { PEAR_AUTH_PROVIDER_ID } from './pearAuthenticationProvider';
import { Registry } from 'vs/platform/registry/common/platform';
import { IWorkbenchContribution, IWorkbenchContributionsRegistry, Extensions as WorkbenchExtensions } from 'vs/workbench/common/contributions';
import { LifecyclePhase } from 'vs/workbench/services/lifecycle/common/lifecycle';

export class PearAuthenticationUriHandler implements IWorkbenchContribution {
	constructor(
		@IAuthenticationService private readonly authenticationService: IAuthenticationService,
		@IURLService private readonly urlService: IURLService
	) {
		this.registerHandler();
	}

	private registerHandler(): void {
		this.urlService.registerHandler({
			handleURL: async (uri: URI): Promise<boolean> => {
				if (uri.authority === 'pearai.pearai' && uri.path === '/auth') {
					const query = new URLSearchParams(uri.query);
					const accessToken = query.get('accessToken');
					const refreshToken = query.get('refreshToken');

					if (accessToken && refreshToken) {
						await this.authenticationService.createSession(
							PEAR_AUTH_PROVIDER_ID,
							['default']
						);
						return true;
					}
				}
				return false;
			}
		});
	}
}

// Register the URI handler as a workbench contribution
Registry.as<IWorkbenchContributionsRegistry>(WorkbenchExtensions.Workbench)
	.registerWorkbenchContribution(PearAuthenticationUriHandler, LifecyclePhase.Restored);
