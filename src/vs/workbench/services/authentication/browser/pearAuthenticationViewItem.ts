import { Disposable } from 'vs/base/common/lifecycle';
import { IAuthenticationService } from 'vs/workbench/services/authentication/common/authentication';
import { PEAR_AUTH_PROVIDER_ID } from './pearAuthenticationProvider';
import { ICommandService } from 'vs/platform/commands/common/commands';
import { IQuickInputService } from 'vs/platform/quickinput/common/quickInput';
import { localize } from 'vs/nls';
import { IActivityService, IBadge, NumberBadge } from 'vs/workbench/services/activity/common/activity';
import { IContextKeyService, IContextKey } from 'vs/platform/contextkey/common/contextkey';
import { registerAccountMenuItems } from './pearAuthenticationAction';

export class PearAuthenticationViewItem extends Disposable {
	static readonly ID = 'pearai.auth.view';
	private readonly authStatusKey: IContextKey<string>;

	constructor(
		@IAuthenticationService private readonly authenticationService: IAuthenticationService,
		@ICommandService private readonly commandService: ICommandService,
		@IQuickInputService private readonly quickInputService: IQuickInputService,
		@IActivityService private readonly activityService: IActivityService,
		@IContextKeyService contextKeyService: IContextKeyService
	) {
		super();

		this.authStatusKey = contextKeyService.createKey('pearai.auth.status', 'notSignedIn');
		this.registerListeners();
		registerAccountMenuItems();
		this.updateAuthStatus();
	}

	private registerListeners(): void {
		this._register(this.authenticationService.onDidChangeSessions(() => {
			this.updateAuthStatus();
		}));
	}

	private async updateAuthStatus(): Promise<void> {
		const sessions = await this.authenticationService.getSessions(PEAR_AUTH_PROVIDER_ID);
		this.authStatusKey.set(sessions.length > 0 ? 'signedIn' : 'notSignedIn');

		const getTooltip = (count: number) => localize('pearai.accounts', "{0} Pear AI {0, plural, one {Account} other {Accounts}}", count);
		const badge = new NumberBadge(sessions.length || 0, getTooltip);

		this.activityService.showAccountsActivity({
			badge: sessions.length ? badge : new NumberBadge(0, getTooltip)
		});
	}
}
