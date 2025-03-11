import { Emitter } from 'vs/base/common/event';
import { Disposable } from 'vs/base/common/lifecycle';
import { AuthenticationProviderInformation, AuthenticationSession, AuthenticationSessionsChangeEvent, IAuthenticationProviderSessionOptions } from 'vs/workbench/services/authentication/common/authentication';
import { IStorageService, StorageScope, StorageTarget } from 'vs/platform/storage/common/storage';
import { ILogService } from 'vs/platform/log/common/log';
import { IEnvironmentService } from 'vs/platform/environment/common/environment';
import { IProductService } from 'vs/platform/product/common/productService';
import { URI } from 'vs/base/common/uri';

export const PEAR_AUTH_PROVIDER_ID = 'pearai';

export interface IPearSession extends AuthenticationSession {
	refreshToken: string;
}

export class PearAuthenticationProvider extends Disposable {
	private readonly _sessions: Map<string, IPearSession> = new Map<string, IPearSession>();
	private _sessionChangeEmitter = new Emitter<AuthenticationSessionsChangeEvent>();

	readonly id = PEAR_AUTH_PROVIDER_ID;
	readonly label = 'Pear AI';
	readonly supportsMultipleAccounts = false;
	readonly onDidChangeSessions = this._sessionChangeEmitter.event;

	private emitSessionsChange(added: IPearSession[] = [], removed: IPearSession[] = []): void {
		const event: AuthenticationSessionsChangeEvent = {
			added,
			removed,
			changed: []
		};
		this._sessionChangeEmitter.fire(event);
	}

	constructor(
		private readonly storageService: IStorageService,
		private readonly logService: ILogService,
		private readonly environmentService: IEnvironmentService,
		private readonly productService: IProductService
	) {
		super();
		this.initialize();
	}

	private initialize(): void {
		try {
			const storedSessions = this.storageService.get(`${PEAR_AUTH_PROVIDER_ID}.sessions`, StorageScope.APPLICATION);
			if (storedSessions) {
				const sessions = JSON.parse(storedSessions);
				sessions.forEach((session: IPearSession) => {
					this._sessions.set(session.id, session);
				});
			}
		} catch (e) {
			this.logService.error('Failed to initialize PearAuthenticationProvider:', e);
		}
	}

	private persistSessions(): void {
		const sessions = Array.from(this._sessions.values());
		this.storageService.store(
			`${PEAR_AUTH_PROVIDER_ID}.sessions`,
			JSON.stringify(sessions),
			StorageScope.APPLICATION,
			StorageTarget.MACHINE
		);
	}

	async getSessions(): Promise<IPearSession[]> {
		return Array.from(this._sessions.values());
	}

	async createSession(scopes: string[], _options: IAuthenticationProviderSessionOptions): Promise<IPearSession> {
		const { accessToken, refreshToken } = await this.login();

		const session: IPearSession = {
			id: Date.now().toString(),
			accessToken,
			refreshToken,
			account: {
				id: Date.now().toString(),
				label: 'Pear AI'
			},
			scopes,
			idToken: undefined
		};

		this._sessions.set(session.id, session);
		this.persistSessions();
		this.emitSessionsChange([session]);

		return session;
	}

	private async getStoredTokens(sessionId: string): Promise<{ accessToken: string; refreshToken: string }> {
		const session = this._sessions.get(sessionId);
		if (!session) {
			throw new Error(`No session found with id: ${sessionId}`);
		}
		return {
			accessToken: session.accessToken,
			refreshToken: session.refreshToken
		};
	}

	private async login(): Promise<{ accessToken: string; refreshToken: string }> {
		throw new Error('Login flow must be initiated through pearai.login command');
	}

	async removeSession(sessionId: string): Promise<void> {
		const session = this._sessions.get(sessionId);
		if (session) {
			this._sessions.delete(sessionId);
			this.persistSessions();
			this.emitSessionsChange([], [session]);
		}
	}

	async getCallbackUri(): Promise<string> {
		const scheme = this.productService.urlProtocol || 'vscode';
		const callbackUri = URI.parse(`${scheme}://pearai.pearai/auth`);
		return callbackUri.toString();
	}

	getProviderInformation(): AuthenticationProviderInformation {
		return {
			id: PEAR_AUTH_PROVIDER_ID,
			label: 'Pear AI',
		};
	}
}
