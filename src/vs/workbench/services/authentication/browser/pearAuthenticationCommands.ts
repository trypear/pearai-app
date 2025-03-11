import { registerAction2, Action2 } from 'vs/platform/actions/common/actions';
import { ServicesAccessor } from 'vs/platform/instantiation/common/instantiation';
import { localize } from 'vs/nls';
import { IEnvironmentService } from 'vs/platform/environment/common/environment';
import { IProductService } from 'vs/platform/product/common/productService';
import { URI } from 'vs/base/common/uri';
import { PEAR_AUTH_PROVIDER_ID } from './pearAuthenticationProvider';
import { IOpenerService } from 'vs/platform/opener/common/opener';
import { IAuthenticationService } from 'vs/workbench/services/authentication/common/authentication';

export function registerPearAuthenticationCommands() {
	registerAction2(class extends Action2 {
		constructor() {
			super({
				id: 'pearai.login',
				title: localize('pearai.login', "Sign in with Pear AI"),
				category: 'Pear AI'
			});
		}

		async run(accessor: ServicesAccessor): Promise<void> {
			const environmentService = accessor.get(IEnvironmentService);
			const productService = accessor.get(IProductService);
			const openerService = accessor.get(IOpenerService);

			const scheme = productService.urlProtocol || 'vscode';
			const callbackUri = URI.parse(`${scheme}://pearai.pearai/auth`);

			const loginUrl = URI.parse(`https://trypear.ai/signin?callback=${encodeURIComponent(callbackUri.toString())}`);
			await openerService.open(loginUrl);
		}
	});

	registerAction2(class extends Action2 {
		constructor() {
			super({
				id: 'pearai.logout',
				title: localize('pearai.logout', "Sign out of Pear AI"),
				category: 'Pear AI'
			});
		}

		async run(accessor: ServicesAccessor): Promise<void> {
			const authService = accessor.get(IAuthenticationService);
			const sessions = await authService.getSessions(PEAR_AUTH_PROVIDER_ID);

			for (const session of sessions) {
				await authService.removeSession(PEAR_AUTH_PROVIDER_ID, session.id);
			}
		}
	});

	registerAction2(class extends Action2 {
		constructor() {
			super({
				id: 'pearai.updateUserAuth',
				title: localize('pearai.updateUserAuth', "Update Pear AI Authentication"),
				category: 'Pear AI'
			});
		}

		async run(accessor: ServicesAccessor, args?: { accessToken: string; refreshToken: string }): Promise<void> {
			if (!args?.accessToken || !args?.refreshToken) {
				return;
			}

			const authService = accessor.get(IAuthenticationService);
			await authService.createSession(PEAR_AUTH_PROVIDER_ID, ['default']);
		}
	});
}
