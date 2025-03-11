import { Action2, registerAction2 } from 'vs/platform/actions/common/actions';
import { IMenuService, MenuId, MenuRegistry } from 'vs/platform/actions/common/actions';
import { localize } from 'vs/nls';
import { ServicesAccessor } from 'vs/platform/instantiation/common/instantiation';
import { ContextKeyExpr } from 'vs/platform/contextkey/common/contextkey';

export class PearAuthenticationAction extends Action2 {
	static readonly ID = 'pearai.auth.menu';
	static readonly LABEL = localize('pearai.auth.menu.label', "Pear AI Account");

	constructor() {
		super({
			id: PearAuthenticationAction.ID,
			title: { value: PearAuthenticationAction.LABEL, original: 'Pear AI Account' },
			category: 'Authentication'
		});
	}

	async run(accessor: ServicesAccessor): Promise<void> {
		// No-op, menu items handle their own actions
	}
}

export function registerAccountMenuItems(): void {
	MenuRegistry.appendMenuItem(MenuId.AccountsContext, {
		group: '1_accounts',
		command: {
			id: 'pearai.login',
			title: localize('pearai.login.title', "Sign in with Pear AI")
		},
		when: ContextKeyExpr.equals('pearai.auth.status', 'notSignedIn')
	});

	MenuRegistry.appendMenuItem(MenuId.AccountsContext, {
		group: '1_accounts',
		command: {
			id: 'pearai.logout',
			title: localize('pearai.logout.title', "Sign out of Pear AI")
		},
		when: ContextKeyExpr.equals('pearai.auth.status', 'signedIn')
	});

	registerAction2(PearAuthenticationAction);
}
